import { Hono } from "hono";
import { apiError } from "../lib/http";
import { requireAuth } from "../middleware/auth";
import type { AppVariables, Env } from "../types";

async function hmacSha256Hex(secret: string, payload: string): Promise<string> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    encoder.encode(payload),
  );
  return Array.from(new Uint8Array(signature))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

export const paymentRoutes = new Hono<{
  Bindings: Env;
  Variables: AppVariables;
}>();

paymentRoutes.use("/intent", requireAuth);
paymentRoutes.use("/simulate", requireAuth);
paymentRoutes.use("/confirm", requireAuth);

paymentRoutes.post("/intent", async (c) => {
  const userId = c.get("userId") as string;
  const body = (await c.req.json()) as Record<string, unknown>;
  const orderId = String(body.orderId ?? "").trim();
  if (!orderId) {
    return apiError(c, 400, "ORDER_ID_REQUIRED", "orderId is required");
  }
  const order = await c.env.DB.prepare(
    "SELECT id, user_id, total_price FROM orders WHERE id = ?",
  )
    .bind(orderId)
    .first<{ id: string; user_id: string; total_price: number }>();
  if (!order || order.user_id !== userId) {
    return apiError(c, 404, "ORDER_NOT_FOUND", "Order not found");
  }
  const paymentRef = `pay_${order.id}_${Date.now()}`;
  await c.env.DB.prepare(
    `INSERT INTO payment_transactions (id, order_id, provider, amount, currency, status)
     VALUES (?, ?, 'tap', ?, 'QAR', 'requires_payment')
     ON CONFLICT(id) DO UPDATE SET amount = excluded.amount`,
  )
    .bind(paymentRef, order.id, order.total_price)
    .run();
  return c.json({
    paymentReference: paymentRef,
    orderId: order.id,
    amount: order.total_price,
    currency: "QAR",
    status: "requires_payment",
  });
});

// Dev-mode manual charge. Blocked in production; lets the client drive the
// full order+intent+confirm flow before the real Tap SDK is wired in.
paymentRoutes.post("/simulate", async (c) => {
  if (c.env.ENVIRONMENT === "production") {
    return apiError(
      c,
      404,
      "NOT_FOUND",
      "Simulation endpoint is disabled in production",
    );
  }
  const userId = c.get("userId") as string;
  const body = (await c.req.json()) as Record<string, unknown>;
  const paymentReference = String(body.paymentReference ?? "").trim();
  const outcome =
    String(body.outcome ?? "paid").toLowerCase() === "failed"
      ? "failed"
      : "paid";
  if (!paymentReference) {
    return apiError(
      c,
      400,
      "PAYMENT_REF_REQUIRED",
      "paymentReference is required",
    );
  }
  const payment = await c.env.DB.prepare(
    "SELECT id, order_id FROM payment_transactions WHERE id = ?",
  )
    .bind(paymentReference)
    .first<{ id: string; order_id: string }>();
  if (!payment) {
    return apiError(c, 404, "PAYMENT_NOT_FOUND", "Payment not found");
  }
  const order = await c.env.DB.prepare(
    "SELECT id, user_id FROM orders WHERE id = ?",
  )
    .bind(payment.order_id)
    .first<{ id: string; user_id: string }>();
  if (!order || order.user_id !== userId) {
    return apiError(c, 403, "FORBIDDEN", "Not allowed");
  }
  await c.env.DB.prepare(
    "UPDATE payment_transactions SET status = ?, updated_at = datetime('now') WHERE id = ?",
  )
    .bind(outcome, paymentReference)
    .run();
  if (outcome === "paid") {
    await c.env.DB.prepare(
      "UPDATE orders SET status = 'confirmed', payment_token = ?, updated_at = datetime('now') WHERE id = ? AND status = 'placed'",
    )
      .bind(paymentReference, payment.order_id)
      .run();
    await c.env.DB.prepare(
      "INSERT INTO order_status_history (id, order_id, status, note) VALUES (?, ?, 'confirmed', 'Payment captured (sandbox)')",
    )
      .bind(crypto.randomUUID(), payment.order_id)
      .run();
  }
  return c.json({ paymentReference, status: outcome, orderId: payment.order_id });
});

// Real Tap charge creation. Swaps the sandbox path for a server-side call to
// Tap's /v2/charges API using the token the Flutter SDK returns. Success
// captures the payment immediately and advances the order to `confirmed`;
// any Tap-side failure leaves the transaction `failed` and surfaces the
// provider error to the client.
paymentRoutes.post("/confirm", async (c) => {
  const userId = c.get("userId") as string;
  const body = (await c.req.json()) as Record<string, unknown>;
  const paymentReference = String(body.paymentReference ?? body.intentId ?? "")
    .trim();
  const tapToken = String(body.tapToken ?? body.token ?? "").trim();
  if (!paymentReference) {
    return apiError(
      c,
      400,
      "PAYMENT_REF_REQUIRED",
      "paymentReference is required",
    );
  }
  if (!tapToken) {
    return apiError(c, 400, "TAP_TOKEN_REQUIRED", "tapToken is required");
  }

  const secret = c.env.TAP_SECRET_KEY?.trim();
  if (!secret) {
    return apiError(c, 500, "PAYMENT_CONFIG_MISSING", "Payment secret missing");
  }

  const payment = await c.env.DB.prepare(
    "SELECT id, order_id, amount, currency, status FROM payment_transactions WHERE id = ?",
  )
    .bind(paymentReference)
    .first<{
      id: string;
      order_id: string;
      amount: number;
      currency: string;
      status: string;
    }>();
  if (!payment) {
    return apiError(c, 404, "PAYMENT_NOT_FOUND", "Payment not found");
  }

  const order = await c.env.DB.prepare(
    "SELECT id, user_id FROM orders WHERE id = ?",
  )
    .bind(payment.order_id)
    .first<{ id: string; user_id: string }>();
  if (!order || order.user_id !== userId) {
    return apiError(c, 403, "FORBIDDEN", "Not allowed");
  }

  if (payment.status === "paid") {
    return c.json({
      paymentReference,
      status: "paid",
      orderId: payment.order_id,
    });
  }

  const chargeBody = {
    amount: payment.amount,
    currency: payment.currency || "QAR",
    threeDSecure: true,
    save_card: false,
    description: `Lolipants order ${payment.order_id}`,
    metadata: {
      orderId: payment.order_id,
      paymentReference,
    },
    reference: {
      transaction: paymentReference,
      order: payment.order_id,
    },
    receipt: { email: false, sms: false },
    source: { id: tapToken },
    post: { url: `${new URL(c.req.url).origin}/payments/webhook/tap` },
    redirect: { url: `${new URL(c.req.url).origin}/payments/webhook/tap` },
  };

  let chargeResponse: Response;
  try {
    chargeResponse = await fetch("https://api.tap.company/v2/charges", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${secret}`,
      },
      body: JSON.stringify(chargeBody),
    });
  } catch (err) {
    console.error("tap.charge.fetch_failed", err);
    return apiError(c, 502, "TAP_UNREACHABLE", "Payment provider unreachable");
  }

  const chargeJson = (await chargeResponse
    .json()
    .catch(() => ({}))) as Record<string, unknown>;
  const chargeStatus = String(chargeJson.status ?? "").toUpperCase();
  const captured = chargeResponse.ok && chargeStatus === "CAPTURED";
  const finalStatus = captured ? "paid" : "failed";

  await c.env.DB.prepare(
    "UPDATE payment_transactions SET status = ?, updated_at = datetime('now') WHERE id = ?",
  )
    .bind(finalStatus, paymentReference)
    .run();

  if (captured) {
    await c.env.DB.prepare(
      "UPDATE orders SET status = 'confirmed', payment_token = ?, updated_at = datetime('now') WHERE id = ? AND status = 'placed'",
    )
      .bind(paymentReference, payment.order_id)
      .run();
    await c.env.DB.prepare(
      "INSERT INTO order_status_history (id, order_id, status, note) VALUES (?, ?, 'confirmed', 'Payment captured (Tap)')",
    )
      .bind(crypto.randomUUID(), payment.order_id)
      .run();
    return c.json({
      paymentReference,
      status: "paid",
      orderId: payment.order_id,
      chargeId: chargeJson.id ?? null,
    });
  }

  const providerMessage = typeof chargeJson.response === "object" &&
      chargeJson.response !== null
    ? String(
      (chargeJson.response as Record<string, unknown>).message ?? "",
    )
    : "";
  return apiError(
    c,
    402,
    "PAYMENT_DECLINED",
    providerMessage || "Payment was declined by the provider",
  );
});

paymentRoutes.post("/webhook/tap", async (c) => {
  const raw = await c.req.text();
  const signature = c.req.header("x-tap-signature") ?? "";
  const secret = c.env.TAP_SECRET_KEY?.trim();
  if (!secret) {
    return apiError(c, 500, "PAYMENT_CONFIG_MISSING", "Payment secret missing");
  }
  const expected = await hmacSha256Hex(secret, raw);
  if (!signature || signature !== expected) {
    return apiError(c, 401, "INVALID_WEBHOOK_SIGNATURE", "Invalid signature");
  }
  const body = JSON.parse(raw) as Record<string, unknown>;
  const refObj =
    typeof body.reference === "object" && body.reference !== null
      ? (body.reference as Record<string, unknown>)
      : null;
  const paymentReference = String(
    body.paymentReference ??
      body.payment_reference ??
      refObj?.transaction ??
      "",
  ).trim();
  const status = String(body.status ?? body.payment_status ?? "").trim();
  if (!paymentReference || !status) {
    return apiError(
      c,
      400,
      "INVALID_WEBHOOK_PAYLOAD",
      "paymentReference and status are required",
    );
  }

  const payment = await c.env.DB.prepare(
    "SELECT order_id FROM payment_transactions WHERE id = ?",
  )
    .bind(paymentReference)
    .first<{ order_id: string }>();
  if (!payment) {
    return apiError(
      c,
      404,
      "PAYMENT_NOT_FOUND",
      "Payment transaction not found",
    );
  }

  const normalized = status.toUpperCase();
  const mapped =
    normalized === "PAID" || normalized === "CAPTURED" ? "paid" : "failed";
  await c.env.DB.prepare(
    "UPDATE payment_transactions SET status = ?, updated_at = datetime('now') WHERE id = ?",
  )
    .bind(mapped, paymentReference)
    .run();
  if (mapped === "paid") {
    await c.env.DB.prepare(
      "UPDATE orders SET status = 'confirmed', payment_token = ?, updated_at = datetime('now') WHERE id = ?",
    )
      .bind(paymentReference, payment.order_id)
      .run();
    await c.env.DB.prepare(
      "INSERT INTO order_status_history (id, order_id, status, note) VALUES (?, ?, 'confirmed', 'Payment captured')",
    )
      .bind(crypto.randomUUID(), payment.order_id)
      .run();
  }
  return c.json({ received: true });
});
