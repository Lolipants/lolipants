import { Hono } from "hono";
import { v4 as uuidv4 } from "uuid";
import { apiError } from "../lib/http";
import { orderStatusTemplates, sendToUser } from "../lib/onesignal";
import { requireAuth, requireRole } from "../middleware/auth";
import type { AppVariables, Env } from "../types";

export const orderRoutes = new Hono<{ Bindings: Env; Variables: AppVariables }>();
orderRoutes.use("*", requireAuth);

const validOrderStatuses = new Set([
  "placed",
  "confirmed",
  "cutting",
  "stitching",
  "embroidery",
  "quality_check",
  "ready_to_ship",
  "out_for_delivery",
  "delivered",
  "cancelled",
]);

const statusTransitions: Record<string, ReadonlySet<string>> = {
  placed: new Set(["confirmed", "cancelled"]),
  confirmed: new Set(["cutting", "cancelled"]),
  cutting: new Set(["stitching", "cancelled"]),
  stitching: new Set(["embroidery", "quality_check", "cancelled"]),
  embroidery: new Set(["quality_check", "cancelled"]),
  quality_check: new Set(["ready_to_ship", "cancelled"]),
  ready_to_ship: new Set(["out_for_delivery", "cancelled"]),
  out_for_delivery: new Set(["delivered"]),
  delivered: new Set(),
  cancelled: new Set(),
};

const cityDeliveryFees: Record<string, number> = {
  doha: 20,
  default: 25,
};

const BASE_PRICE = 350;

function fabricFeeFor(quality: string | null | undefined): number {
  const q = (quality ?? "").toLowerCase();
  if (q === "premium") return 120;
  if (q === "suit_grade") return 180;
  return 60;
}

function deliveryFeeFor(city: string): number {
  const key = city.trim().toLowerCase();
  return cityDeliveryFees[key] ?? cityDeliveryFees.default;
}

orderRoutes.get("/", async (c) => {
  const userId = c.get("userId") as string;
  const { results } = await c.env.DB.prepare(
    "SELECT * FROM orders WHERE user_id = ? ORDER BY placed_at DESC",
  )
    .bind(userId)
    .all();
  return c.json(results);
});

orderRoutes.get("/quote", async (c) => {
  const userId = c.get("userId") as string;
  const designId = (c.req.query("designId") ?? "").trim();
  const city = (c.req.query("city") ?? "Doha").trim();
  if (!designId) {
    return apiError(c, 400, "DESIGN_ID_REQUIRED", "designId is required");
  }
  const design = await c.env.DB.prepare(
    "SELECT id, user_id, fabric_quality FROM designs WHERE id = ?",
  )
    .bind(designId)
    .first<{ id: string; user_id: string; fabric_quality: string | null }>();
  if (!design) return apiError(c, 404, "DESIGN_NOT_FOUND", "Design not found");
  if (design.user_id !== userId) {
    return apiError(
      c,
      403,
      "QUOTE_OWN_DESIGN_ONLY",
      "You can only quote your own design",
    );
  }
  const fabricFee = fabricFeeFor(design.fabric_quality);
  const deliveryFee = deliveryFeeFor(city);
  const total = BASE_PRICE + fabricFee + deliveryFee;
  return c.json({
    designId,
    city,
    basePrice: BASE_PRICE,
    fabricFee,
    deliveryFee,
    total,
    currency: "QAR",
    fabricQuality: design.fabric_quality,
  });
});

orderRoutes.get("/queue", requireRole("tailor"), async (c) => {
  const tailorId = c.get("userId") as string;
  const statusFilter = (c.req.query("status") ?? "").trim().toLowerCase();
  const statuses = statusFilter
    ? statusFilter
        .split(",")
        .map((s) => s.trim())
        .filter((s) => validOrderStatuses.has(s))
    : [];
  let query =
    "SELECT * FROM orders WHERE (tailor_id IS NULL OR tailor_id = ?)";
  const bindings: Array<string> = [tailorId];
  if (statuses.length > 0) {
    const placeholders = statuses.map(() => "?").join(", ");
    query += ` AND status IN (${placeholders})`;
    bindings.push(...statuses);
  }
  query += " ORDER BY placed_at DESC LIMIT 200";
  const { results } = await c.env.DB.prepare(query)
    .bind(...bindings)
    .all();
  return c.json(results);
});

orderRoutes.post("/:id/claim", requireRole("tailor"), async (c) => {
  const tailorId = c.get("userId") as string;
  const id = c.req.param("id");
  const current = await c.env.DB.prepare(
    "SELECT id, tailor_id, status FROM orders WHERE id = ?",
  )
    .bind(id)
    .first<{ id: string; tailor_id: string | null; status: string }>();
  if (!current) {
    return apiError(c, 404, "ORDER_NOT_FOUND", "Order not found");
  }
  if (current.tailor_id && current.tailor_id !== tailorId) {
    return apiError(
      c,
      409,
      "ORDER_ALREADY_CLAIMED",
      "Order already assigned to another tailor",
    );
  }
  await c.env.DB.prepare(
    "UPDATE orders SET tailor_id = ?, updated_at = datetime('now') WHERE id = ? AND (tailor_id IS NULL OR tailor_id = ?)",
  )
    .bind(tailorId, id, tailorId)
    .run();
  return c.json({ claimed: true, orderId: id, tailorId });
});

orderRoutes.get("/:id", async (c) => {
  const userId = c.get("userId") as string;
  const id = c.req.param("id");

  const order = await c.env.DB.prepare(
    "SELECT * FROM orders WHERE id = ? AND user_id = ?",
  )
    .bind(id, userId)
    .first<Record<string, unknown>>();
  if (!order) return apiError(c, 404, "ORDER_NOT_FOUND", "Order not found");

  const history = await c.env.DB.prepare(
    "SELECT * FROM order_status_history WHERE order_id = ? ORDER BY timestamp ASC",
  )
    .bind(id)
    .all();
  const payment = await c.env.DB.prepare(
    "SELECT id, status, amount, currency, updated_at FROM payment_transactions WHERE order_id = ? ORDER BY updated_at DESC LIMIT 1",
  )
    .bind(id)
    .first<Record<string, unknown>>();
  return c.json({ ...order, statusHistory: history.results, payment });
});

orderRoutes.post("/", async (c) => {
  const userId = c.get("userId") as string;
  const idempotencyKey = c.req.header("x-idempotency-key")?.trim() ?? "";
  if (!idempotencyKey) {
    return apiError(
      c,
      400,
      "IDEMPOTENCY_KEY_REQUIRED",
      "X-Idempotency-Key header is required",
    );
  }
  const existing = await c.env.DB.prepare(
    `SELECT o.* FROM order_idempotency_keys k
     JOIN orders o ON o.id = k.order_id
     WHERE k.user_id = ? AND k.idempotency_key = ? LIMIT 1`,
  )
    .bind(userId, idempotencyKey)
    .first<Record<string, unknown>>();
  if (existing) return c.json(existing, 200);

  const body = (await c.req.json()) as Record<string, unknown>;
  const designId = String(body.designId ?? "").trim();
  if (!designId) {
    return apiError(c, 400, "DESIGN_ID_REQUIRED", "designId is required");
  }

  const design = await c.env.DB.prepare(
    "SELECT id, user_id, fabric_quality, is_public FROM designs WHERE id = ?",
  )
    .bind(designId)
    .first<{ id: string; user_id: string; fabric_quality: string | null; is_public: number | null }>();
  if (!design) return apiError(c, 404, "DESIGN_NOT_FOUND", "Design not found");
  const requestedDesignerId = body.designerId ? String(body.designerId).trim() : "";
  const isOwnDesign = design.user_id === userId;
  const isPublicDesign = Boolean(design.is_public);
  if (!isOwnDesign && !isPublicDesign) {
    return apiError(
      c,
      403,
      "ORDER_OWN_DESIGN_ONLY",
      "You can only order your own designs or public showcase designs",
    );
  }
  if (requestedDesignerId && requestedDesignerId !== design.user_id) {
    return apiError(
      c,
      400,
      "DESIGNER_MISMATCH",
      "designerId does not match the design author",
    );
  }
  // Designer credited with commission is the design author (never the buyer on their own design).
  const designerId = !isOwnDesign ? design.user_id : null;

  const deliveryAddress = String(body.deliveryAddress ?? "").trim();
  const deliveryCity = String(body.deliveryCity ?? "").trim();
  const deliveryPhone = String(body.deliveryPhone ?? "").trim();
  if (!deliveryAddress || !deliveryCity || !deliveryPhone) {
    return apiError(
      c,
      400,
      "DELIVERY_FIELDS_REQUIRED",
      "deliveryAddress, deliveryCity, and deliveryPhone are required",
    );
  }
  const sizing = await c.env.DB.prepare(
    "SELECT id FROM measurements WHERE user_id = ? ORDER BY saved_at DESC LIMIT 1",
  )
    .bind(userId)
    .first<{ id: string }>();
  if (!sizing) {
    return apiError(
      c,
      400,
      "MEASUREMENTS_REQUIRED",
      "Please save measurements before ordering",
    );
  }

  const deliveryFee = deliveryFeeFor(deliveryCity);
  const basePrice = BASE_PRICE;
  const fabricFee = fabricFeeFor(design.fabric_quality);
  const totalPrice = basePrice + fabricFee + deliveryFee;
  const id = uuidv4();

  try {
    await c.env.DB.prepare(
      `INSERT INTO orders (id, user_id, design_id, designer_id, status, delivery_address, delivery_city,
        delivery_phone, delivery_notes, base_price, fabric_fee, delivery_fee, total_price, payment_token)
        VALUES (?, ?, ?, ?, 'placed', ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    )
      .bind(
        id,
        userId,
        designId,
        designerId,
        deliveryAddress,
        deliveryCity,
        deliveryPhone,
        body.deliveryNotes ?? null,
        basePrice,
        fabricFee,
        deliveryFee,
        totalPrice,
        body.paymentToken ?? null,
      )
      .run();

    await c.env.DB.prepare(
      "INSERT INTO order_status_history (id, order_id, status) VALUES (?, ?, 'placed')",
    )
      .bind(uuidv4(), id)
      .run();
    await c.env.DB.prepare(
      "INSERT INTO order_idempotency_keys (id, user_id, idempotency_key, order_id) VALUES (?, ?, ?, ?)",
    )
      .bind(uuidv4(), userId, idempotencyKey, id)
      .run();

    if (designerId && designerId !== userId) {
      const commissionPct = 10;
      const commissionAmount = Math.round(totalPrice * (commissionPct / 100));
      await c.env.DB.prepare(
        `INSERT OR IGNORE INTO commissions
           (id, order_id, designer_id, buyer_id, amount, percentage, currency, status)
         VALUES (?, ?, ?, ?, ?, ?, 'QAR', 'pending')`,
      )
        .bind(
          uuidv4(),
          id,
          designerId,
          userId,
          commissionAmount,
          commissionPct,
        )
        .run();
    }

    await c.env.DB.prepare(
      "UPDATE designs SET order_count = (SELECT COUNT(*) FROM orders WHERE design_id = ?) WHERE id = ?",
    )
      .bind(designId, designId)
      .run();
  } catch (error) {
    console.error("failed to create order", error);
    return apiError(c, 500, "ORDER_CREATE_FAILED", "Could not create order");
  }

  const created = await c.env.DB.prepare("SELECT * FROM orders WHERE id = ?")
    .bind(id)
    .first();
  return c.json(created, 201);
});

orderRoutes.delete("/:id", async (c) => {
  const userId = c.get("userId") as string;
  const id = c.req.param("id");

  const order = await c.env.DB.prepare(
    "SELECT id, status FROM orders WHERE id = ? AND user_id = ?",
  )
    .bind(id, userId)
    .first<{ id: string; status: string }>();
  if (!order) return apiError(c, 404, "ORDER_NOT_FOUND", "Order not found");
  if (order.status === "delivered" || order.status === "cancelled") {
    return apiError(
      c,
      400,
      "ORDER_CANCELLATION_INVALID",
      "Order can no longer be cancelled",
    );
  }

  await c.env.DB.prepare(
    "UPDATE orders SET status = 'cancelled', updated_at = datetime('now') WHERE id = ? AND user_id = ?",
  )
    .bind(id, userId)
    .run();
  await c.env.DB.prepare(
    "INSERT INTO order_status_history (id, order_id, status, note, updated_by) VALUES (?, ?, 'cancelled', ?, ?)",
  )
    .bind(uuidv4(), id, "Cancelled by customer", userId)
    .run();
  await c.env.DB.prepare(
    "UPDATE commissions SET status = 'void', updated_at = datetime('now') WHERE order_id = ? AND status IN ('pending','approved')",
  )
    .bind(id)
    .run();

  return c.json({ cancelled: true });
});

orderRoutes.patch("/:id/status", requireRole("tailor"), async (c) => {
  const id = c.req.param("id");
  const userId = c.get("userId") as string;
  const body = (await c.req.json()) as Record<string, unknown>;
  const status = String(body.status ?? "").trim().toLowerCase();
  if (!status) return apiError(c, 400, "STATUS_REQUIRED", "status is required");
  if (!validOrderStatuses.has(status)) {
    return apiError(c, 400, "INVALID_STATUS", "Invalid order status");
  }
  const current = await c.env.DB.prepare("SELECT status FROM orders WHERE id = ?")
    .bind(id)
    .first<{ status: string }>();
  if (!current) {
    return apiError(c, 404, "ORDER_NOT_FOUND", "Order not found");
  }
  const allowed = statusTransitions[current.status.toLowerCase()] ?? new Set();
  if (!allowed.has(status)) {
    return apiError(
      c,
      409,
      "INVALID_STATUS_TRANSITION",
      `Cannot transition from ${current.status} to ${status}`,
    );
  }

  await c.env.DB.prepare(
    "UPDATE orders SET status = ?, updated_at = datetime('now') WHERE id = ?",
  )
    .bind(status, id)
    .run();
  await c.env.DB.prepare(
    "INSERT INTO order_status_history (id, order_id, status, note, updated_by) VALUES (?, ?, ?, ?, ?)",
  )
    .bind(uuidv4(), id, status, body.note ?? null, userId)
    .run();

  if (status === "delivered") {
    await c.env.DB.prepare(
      "UPDATE commissions SET status = 'approved', updated_at = datetime('now') WHERE order_id = ? AND status = 'pending'",
    )
      .bind(id)
      .run();
  } else if (status === "cancelled") {
    await c.env.DB.prepare(
      "UPDATE commissions SET status = 'void', updated_at = datetime('now') WHERE order_id = ? AND status IN ('pending','approved')",
    )
      .bind(id)
      .run();
  }

  // Push the order owner on every transition that has a bilingual template.
  const template = orderStatusTemplates[status];
  if (template) {
    const owner = await c.env.DB.prepare(
      "SELECT user_id FROM orders WHERE id = ?",
    )
      .bind(id)
      .first<{ user_id: string }>();
    if (owner) {
      await sendToUser({
        env: c.env,
        userIds: [owner.user_id],
        headings: template.headings,
        contents: template.contents,
        route: `/orders/detail/${id}`,
      });
    }
  }

  return c.json({ updated: true, status });
});
