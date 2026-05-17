import { Hono } from "hono";
import { v4 as uuidv4 } from "uuid";
import { apiError } from "../lib/http";
import { orderStatusTemplates, sendToUser } from "../lib/onesignal";
import { requireAuth, requireCourier } from "../middleware/auth";
import type { AppVariables, Env } from "../types";

export const deliveryRoutes = new Hono<{ Bindings: Env; Variables: AppVariables }>();
deliveryRoutes.use("*", requireAuth);
deliveryRoutes.use("*", requireCourier());

// Statuses a delivery-person can transition through.
const COURIER_PICKUP_STATUS = "ready_to_ship";
const PICKED_UP_STATUS = "out_for_delivery";
const DELIVERED_STATUS = "delivered";

// Columns we join back to present a rich list row.
const ORDER_COLUMNS = `
  o.id, o.user_id, o.status, o.tailor_id, o.courier_id,
  o.delivery_address, o.delivery_city, o.delivery_phone, o.delivery_notes,
  o.base_price, o.fabric_fee, o.delivery_fee, o.total_price,
  o.delivery_proof_url, o.delivered_at, o.placed_at, o.updated_at,
  d.name AS design_name, d.garment_type AS garment_type
`;

/** Orders waiting for a courier: tailoring is complete, nobody claimed them. */
deliveryRoutes.get("/queue", async (c) => {
  const { results } = await c.env.DB.prepare(
    `SELECT ${ORDER_COLUMNS}
     FROM orders o
     LEFT JOIN designs d ON d.id = o.design_id
     WHERE o.status = ? AND o.courier_id IS NULL
     ORDER BY o.updated_at ASC
     LIMIT 200`,
  )
    .bind(COURIER_PICKUP_STATUS)
    .all();
  return c.json(results);
});

/** Claim an order. Atomic - only succeeds if courier_id is still NULL. */
deliveryRoutes.post("/orders/:id/claim", async (c) => {
  const courierId = c.get("userId") as string;
  const id = c.req.param("id");
  const current = await c.env.DB.prepare(
    "SELECT id, courier_id, status FROM orders WHERE id = ?",
  )
    .bind(id)
    .first<{ id: string; courier_id: string | null; status: string }>();
  if (!current) return apiError(c, 404, "ORDER_NOT_FOUND", "Order not found");
  if (current.status !== COURIER_PICKUP_STATUS) {
    return apiError(
      c,
      409,
      "ORDER_NOT_READY",
      "This order is not yet ready for pickup",
    );
  }
  if (current.courier_id && current.courier_id !== courierId) {
    return apiError(
      c,
      409,
      "ORDER_ALREADY_CLAIMED",
      "Another courier already claimed this order",
    );
  }
  const res = await c.env.DB.prepare(
    "UPDATE orders SET courier_id = ?, updated_at = datetime('now') WHERE id = ? AND courier_id IS NULL",
  )
    .bind(courierId, id)
    .run();
  const changes =
    (res as unknown as { meta?: { changes?: number } }).meta?.changes ?? 0;
  if (changes === 0 && current.courier_id !== courierId) {
    return apiError(c, 409, "ORDER_ALREADY_CLAIMED", "Another courier claimed this first");
  }
  return c.json({ claimed: true, orderId: id, courierId });
});

/** Orders currently being delivered by this courier. */
deliveryRoutes.get("/active", async (c) => {
  const courierId = c.get("userId") as string;
  const { results } = await c.env.DB.prepare(
    `SELECT ${ORDER_COLUMNS}
     FROM orders o
     LEFT JOIN designs d ON d.id = o.design_id
     WHERE o.courier_id = ? AND o.status IN ('${COURIER_PICKUP_STATUS}', '${PICKED_UP_STATUS}')
     ORDER BY o.updated_at DESC
     LIMIT 200`,
  )
    .bind(courierId)
    .all();
  return c.json(results);
});

/** Delivered orders completed by this courier. */
deliveryRoutes.get("/history", async (c) => {
  const courierId = c.get("userId") as string;
  const { results } = await c.env.DB.prepare(
    `SELECT ${ORDER_COLUMNS}
     FROM orders o
     LEFT JOIN designs d ON d.id = o.design_id
     WHERE o.courier_id = ? AND o.status = '${DELIVERED_STATUS}'
     ORDER BY COALESCE(o.delivered_at, o.updated_at) DESC
     LIMIT 200`,
  )
    .bind(courierId)
    .all();
  return c.json(results);
});

async function loadDeliveryOrderPayload(
  db: D1Database,
  courierId: string,
  orderId: string,
): Promise<Record<string, unknown> | null> {
  const order = await db
    .prepare(
      `SELECT ${ORDER_COLUMNS}
       FROM orders o
       LEFT JOIN designs d ON d.id = o.design_id
       WHERE o.id = ? AND o.courier_id = ?`,
    )
    .bind(orderId, courierId)
    .first<Record<string, unknown>>();
  if (!order) return null;
  const history = await db
    .prepare(
      "SELECT * FROM order_status_history WHERE order_id = ? ORDER BY timestamp ASC",
    )
    .bind(orderId)
    .all();
  return { ...order, statusHistory: history.results };
}

/** One order, restricted to the courier who claimed it. */
deliveryRoutes.get("/orders/:id", async (c) => {
  const courierId = c.get("userId") as string;
  const id = c.req.param("id");
  const order = await c.env.DB.prepare(
    `SELECT ${ORDER_COLUMNS}
     FROM orders o
     LEFT JOIN designs d ON d.id = o.design_id
     WHERE o.id = ? AND (o.courier_id = ? OR (o.courier_id IS NULL AND o.status = ?))`,
  )
    .bind(id, courierId, COURIER_PICKUP_STATUS)
    .first<Record<string, unknown>>();
  if (!order) return apiError(c, 404, "ORDER_NOT_FOUND", "Order not found");
  const history = await c.env.DB.prepare(
    "SELECT * FROM order_status_history WHERE order_id = ? ORDER BY timestamp ASC",
  )
    .bind(id)
    .all();
  return c.json({ ...order, statusHistory: history.results });
});

/**
 * Delivery state-machine:
 *   ready_to_ship -> out_for_delivery (pick-up)
 *   out_for_delivery -> delivered (requires proof_url)
 */
deliveryRoutes.patch("/orders/:id/status", async (c) => {
  const courierId = c.get("userId") as string;
  const id = c.req.param("id");
  const body = (await c.req.json().catch(() => ({}))) as Record<string, unknown>;
  const nextStatus = String(body.status ?? "").trim().toLowerCase();
  if (![PICKED_UP_STATUS, DELIVERED_STATUS].includes(nextStatus)) {
    return apiError(c, 400, "INVALID_STATUS", "Unsupported delivery status");
  }
  const proofUrl = body.proofUrl ? String(body.proofUrl).trim() : "";
  const note = body.note ? String(body.note).trim() : null;

  const current = await c.env.DB.prepare(
    "SELECT id, courier_id, status FROM orders WHERE id = ?",
  )
    .bind(id)
    .first<{ id: string; courier_id: string | null; status: string }>();
  if (!current) return apiError(c, 404, "ORDER_NOT_FOUND", "Order not found");

  if (nextStatus === PICKED_UP_STATUS) {
    if (
      current.courier_id &&
      current.courier_id !== courierId
    ) {
      return apiError(
        c,
        403,
        "FORBIDDEN",
        "This delivery is assigned to another courier",
      );
    }
  } else if (current.courier_id !== courierId) {
    return apiError(c, 403, "FORBIDDEN", "You have not claimed this order");
  }

  if (nextStatus === PICKED_UP_STATUS && current.status !== COURIER_PICKUP_STATUS) {
    return apiError(
      c,
      409,
      "INVALID_STATUS_TRANSITION",
      `Cannot pick up an order in status ${current.status}`,
    );
  }
  if (nextStatus === DELIVERED_STATUS) {
    if (current.status !== PICKED_UP_STATUS) {
      return apiError(
        c,
        409,
        "INVALID_STATUS_TRANSITION",
        `Cannot mark delivered from status ${current.status}`,
      );
    }
    if (!proofUrl) {
      return apiError(
        c,
        400,
        "PROOF_REQUIRED",
        "Delivery proof photo URL is required",
      );
    }
  }

  if (nextStatus === DELIVERED_STATUS) {
    await c.env.DB.prepare(
      `UPDATE orders
       SET status = ?, delivery_proof_url = ?, delivered_at = datetime('now'),
           updated_at = datetime('now')
       WHERE id = ?`,
    )
      .bind(nextStatus, proofUrl, id)
      .run();
  } else {
    await c.env.DB.prepare(
      `UPDATE orders
       SET status = ?, courier_id = ?, updated_at = datetime('now')
       WHERE id = ?
         AND (courier_id IS NULL OR courier_id = ?)
         AND status = ?`,
    )
      .bind(nextStatus, courierId, id, courierId, COURIER_PICKUP_STATUS)
      .run();
  }
  await c.env.DB.prepare(
    "INSERT INTO order_status_history (id, order_id, status, note, updated_by) VALUES (?, ?, ?, ?, ?)",
  )
    .bind(uuidv4(), id, nextStatus, note, courierId)
    .run();

  if (nextStatus === DELIVERED_STATUS) {
    await c.env.DB.prepare(
      "UPDATE commissions SET status = 'approved', updated_at = datetime('now') WHERE order_id = ? AND status = 'pending'",
    )
      .bind(id)
      .run();
  }

  // Notify the customer on delivery transitions (pickup + delivered).
  const pushTemplateKey =
    nextStatus === PICKED_UP_STATUS ? "out_for_delivery" : "delivered";
  const template = orderStatusTemplates[pushTemplateKey];
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

  const order = await loadDeliveryOrderPayload(c.env.DB, courierId, id);
  if (!order) {
    return c.json({ updated: true, status: nextStatus });
  }
  return c.json({ ...order, updated: true, status: nextStatus });
});
