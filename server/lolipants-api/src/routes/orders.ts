import { Hono } from "hono";
import { v4 as uuidv4 } from "uuid";
import { apiError } from "../lib/http";
import { orderStatusTemplates, sendToUser } from "../lib/onesignal";
import { pickNearestTailor } from "../lib/tailorAssignment";
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

function parseCoord(
  raw: string | undefined,
  field: string,
): { ok: true; value: number } | { ok: false; message: string } {
  if (raw == null || raw.trim() === "") {
    return { ok: false, message: `${field} is required` };
  }
  const value = Number(raw);
  if (!Number.isFinite(value)) {
    return { ok: false, message: `${field} must be a number` };
  }
  return { ok: true, value };
}

function pricesMatch(
  a: { base: number; fabric: number; delivery: number; total: number },
  b: { base: number; fabric: number; delivery: number; total: number },
): boolean {
  const eps = 0.01;
  return (
    Math.abs(a.base - b.base) < eps &&
    Math.abs(a.fabric - b.fabric) < eps &&
    Math.abs(a.delivery - b.delivery) < eps &&
    Math.abs(a.total - b.total) < eps
  );
}

async function assignTailorAndQuote(
  db: D1Database,
  input: {
    design: {
      garment_type: string;
      fabric_quality: string | null;
    };
    city: string;
    deliveryLat: number;
    deliveryLng: number;
  },
) {
  const assigned = await pickNearestTailor({
    db,
    deliveryLat: input.deliveryLat,
    deliveryLng: input.deliveryLng,
    city: input.city,
    design: input.design,
  });
  if (!assigned) return null;
  return {
    tailorId: assigned.tailorId,
    tailorName: assigned.tailorName,
    shopName: assigned.shopName,
    distanceKm: Math.round(assigned.distanceKm * 10) / 10,
    pricePlanId: assigned.quote.planId,
    assignmentMethod: "proximity" as const,
    basePrice: assigned.quote.basePrice,
    fabricFee: assigned.quote.fabricFee,
    deliveryFee: assigned.quote.deliveryFee,
    total: assigned.quote.total,
    currency: assigned.quote.currency,
    fabricQuality: assigned.quote.fabricQuality,
    garmentType: assigned.quote.garmentType,
  };
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
  const latParsed = parseCoord(c.req.query("deliveryLat"), "deliveryLat");
  const lngParsed = parseCoord(c.req.query("deliveryLng"), "deliveryLng");
  if (!latParsed.ok) {
    return apiError(c, 400, "DELIVERY_LAT_REQUIRED", latParsed.message);
  }
  if (!lngParsed.ok) {
    return apiError(c, 400, "DELIVERY_LNG_REQUIRED", lngParsed.message);
  }
  if (latParsed.value < -90 || latParsed.value > 90) {
    return apiError(c, 400, "INVALID_LAT", "deliveryLat out of range");
  }
  if (lngParsed.value < -180 || lngParsed.value > 180) {
    return apiError(c, 400, "INVALID_LNG", "deliveryLng out of range");
  }
  if (!designId) {
    return apiError(c, 400, "DESIGN_ID_REQUIRED", "designId is required");
  }
  const design = await c.env.DB.prepare(
    "SELECT id, user_id, garment_type, fabric_quality FROM designs WHERE id = ?",
  )
    .bind(designId)
    .first<{
      id: string;
      user_id: string;
      garment_type: string;
      fabric_quality: string | null;
    }>();
  if (!design) return apiError(c, 404, "DESIGN_NOT_FOUND", "Design not found");
  if (design.user_id !== userId) {
    return apiError(
      c,
      403,
      "QUOTE_OWN_DESIGN_ONLY",
      "You can only quote your own design",
    );
  }

  const quote = await assignTailorAndQuote(c.env.DB, {
    design: {
      garment_type: design.garment_type,
      fabric_quality: design.fabric_quality,
    },
    city,
    deliveryLat: latParsed.value,
    deliveryLng: lngParsed.value,
  });
  if (!quote) {
    return apiError(
      c,
      404,
      "NO_TAILOR_AVAILABLE",
      "No tailor is available near this location for this garment",
    );
  }

  return c.json({
    designId,
    city,
    deliveryLat: latParsed.value,
    deliveryLng: lngParsed.value,
    tailorId: quote.tailorId,
    tailorName: quote.tailorName,
    shopName: quote.shopName,
    distanceKm: quote.distanceKm,
    pricePlanId: quote.pricePlanId,
    assignmentMethod: quote.assignmentMethod,
    basePrice: quote.basePrice,
    fabricFee: quote.fabricFee,
    deliveryFee: quote.deliveryFee,
    total: quote.total,
    currency: quote.currency,
    fabricQuality: quote.fabricQuality,
    garmentType: quote.garmentType,
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
  let query = "SELECT * FROM orders WHERE tailor_id = ?";
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
  if (!current.tailor_id) {
    return apiError(
      c,
      409,
      "TAILOR_NOT_ASSIGNED",
      "This order has no assigned tailor yet",
    );
  }
  if (current.tailor_id !== tailorId) {
    return apiError(
      c,
      409,
      "ORDER_ALREADY_CLAIMED",
      "Order is assigned to another tailor",
    );
  }
  return c.json({ claimed: true, orderId: id, tailorId, accepted: true });
});

orderRoutes.get("/tailor/:id", requireRole("tailor"), async (c) => {
  const tailorId = c.get("userId") as string;
  const id = c.req.param("id");
  const order = await c.env.DB.prepare(
    `SELECT o.*, d.print_image_url AS design_print_image_url,
            d.sketch_image_url AS design_sketch_image_url
     FROM orders o
     LEFT JOIN designs d ON d.id = o.design_id
     WHERE o.id = ? AND o.tailor_id = ?`,
  )
    .bind(id, tailorId)
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
    "SELECT id, user_id, garment_type, fabric_quality, is_public FROM designs WHERE id = ?",
  )
    .bind(designId)
    .first<{
      id: string;
      user_id: string;
      garment_type: string;
      fabric_quality: string | null;
      is_public: number | null;
    }>();
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

  const latRaw = body.deliveryLat ?? body.delivery_lat;
  const lngRaw = body.deliveryLng ?? body.delivery_lng;
  const lat =
    typeof latRaw === "number" ? latRaw : Number(String(latRaw ?? "").trim());
  const lng =
    typeof lngRaw === "number" ? lngRaw : Number(String(lngRaw ?? "").trim());
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
    return apiError(
      c,
      400,
      "DELIVERY_COORDS_REQUIRED",
      "deliveryLat and deliveryLng are required",
    );
  }

  const requestedTailorId = String(body.tailorId ?? body.tailor_id ?? "").trim();
  if (!requestedTailorId) {
    return apiError(c, 400, "TAILOR_ID_REQUIRED", "tailorId is required");
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

  const quote = await assignTailorAndQuote(c.env.DB, {
    design: {
      garment_type: design.garment_type,
      fabric_quality: design.fabric_quality,
    },
    city: deliveryCity,
    deliveryLat: lat,
    deliveryLng: lng,
  });
  if (!quote) {
    return apiError(
      c,
      404,
      "NO_TAILOR_AVAILABLE",
      "No tailor is available near this location for this garment",
    );
  }
  if (quote.tailorId !== requestedTailorId) {
    return apiError(
      c,
      409,
      "QUOTE_STALE",
      "Assigned tailor changed. Refresh your quote before paying.",
    );
  }

  const clientBase = Number(body.basePrice ?? body.base_price);
  const clientFabric = Number(body.fabricFee ?? body.fabric_fee);
  const clientDelivery = Number(body.deliveryFee ?? body.delivery_fee);
  const clientTotal = Number(body.totalPrice ?? body.total_price);
  if (
    Number.isFinite(clientTotal) &&
    !pricesMatch(
      {
        base: clientBase,
        fabric: clientFabric,
        delivery: clientDelivery,
        total: clientTotal,
      },
      {
        base: quote.basePrice,
        fabric: quote.fabricFee,
        delivery: quote.deliveryFee,
        total: quote.total,
      },
    )
  ) {
    return apiError(
      c,
      409,
      "QUOTE_MISMATCH",
      "Price no longer matches the server quote. Refresh and try again.",
    );
  }

  const basePrice = quote.basePrice;
  const fabricFee = quote.fabricFee;
  const deliveryFee = quote.deliveryFee;
  const totalPrice = quote.total;
  const id = uuidv4();

  try {
    await c.env.DB.prepare(
      `INSERT INTO orders (id, user_id, design_id, designer_id, tailor_id, status,
        delivery_address, delivery_city, delivery_phone, delivery_notes,
        delivery_lat, delivery_lng, price_plan_id, assignment_method,
        base_price, fabric_fee, delivery_fee, total_price, payment_token)
        VALUES (?, ?, ?, ?, ?, 'placed', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    )
      .bind(
        id,
        userId,
        designId,
        designerId,
        quote.tailorId,
        deliveryAddress,
        deliveryCity,
        deliveryPhone,
        body.deliveryNotes ?? null,
        lat,
        lng,
        quote.pricePlanId,
        quote.assignmentMethod,
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
  const current = await c.env.DB.prepare(
    "SELECT status, tailor_id FROM orders WHERE id = ?",
  )
    .bind(id)
    .first<{ status: string; tailor_id: string | null }>();
  if (!current) {
    return apiError(c, 404, "ORDER_NOT_FOUND", "Order not found");
  }
  const role = (c.get("userRole") as string | undefined)?.toLowerCase();
  if (role === "tailor" && current.tailor_id && current.tailor_id !== userId) {
    return apiError(c, 403, "FORBIDDEN", "Not your assigned order");
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
