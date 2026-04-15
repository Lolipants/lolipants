import { Hono } from "hono";
import { v4 as uuidv4 } from "uuid";
import { requireAuth, requireRole } from "../middleware/auth";
import type { AppVariables, Env } from "../types";

export const orderRoutes = new Hono<{ Bindings: Env; Variables: AppVariables }>();
orderRoutes.use("*", requireAuth);

orderRoutes.get("/", async (c) => {
  const userId = c.get("userId") as string;
  const { results } = await c.env.DB.prepare(
    "SELECT * FROM orders WHERE user_id = ? ORDER BY placed_at DESC",
  )
    .bind(userId)
    .all();
  return c.json(results);
});

orderRoutes.get("/:id", async (c) => {
  const userId = c.get("userId") as string;
  const id = c.req.param("id");

  const order = await c.env.DB.prepare(
    "SELECT * FROM orders WHERE id = ? AND user_id = ?",
  )
    .bind(id, userId)
    .first<Record<string, unknown>>();
  if (!order) return c.json({ error: "Order not found" }, 404);

  const history = await c.env.DB.prepare(
    "SELECT * FROM order_status_history WHERE order_id = ? ORDER BY timestamp ASC",
  )
    .bind(id)
    .all();
  return c.json({ ...order, statusHistory: history.results });
});

orderRoutes.post("/", async (c) => {
  const userId = c.get("userId") as string;
  const body = (await c.req.json()) as Record<string, unknown>;
  const designId = String(body.designId ?? "").trim();
  if (!designId) return c.json({ error: "designId is required" }, 400);

  const design = await c.env.DB.prepare(
    "SELECT id, user_id FROM designs WHERE id = ?",
  )
    .bind(designId)
    .first<{ id: string; user_id: string }>();
  if (!design) return c.json({ error: "Design not found" }, 404);
  if (design.user_id !== userId) {
    return c.json({ error: "You can only order your own design" }, 403);
  }

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
        body.designerId ?? null,
        body.deliveryAddress ?? "",
        body.deliveryCity ?? "Doha",
        body.deliveryPhone ?? "",
        body.deliveryNotes ?? null,
        body.basePrice ?? 0,
        body.fabricFee ?? 0,
        body.deliveryFee ?? 0,
        body.totalPrice ?? 0,
        body.paymentToken ?? null,
      )
      .run();

    await c.env.DB.prepare(
      "INSERT INTO order_status_history (id, order_id, status) VALUES (?, ?, 'placed')",
    )
      .bind(uuidv4(), id)
      .run();
  } catch (error) {
    console.error("failed to create order", error);
    return c.json({ error: "Could not create order" }, 500);
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
  if (!order) return c.json({ error: "Order not found" }, 404);
  if (order.status === "delivered" || order.status === "cancelled") {
    return c.json({ error: "Order can no longer be cancelled" }, 400);
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

  return c.json({ cancelled: true });
});

orderRoutes.patch("/:id/status", requireRole("tailor"), async (c) => {
  const id = c.req.param("id");
  const userId = c.get("userId") as string;
  const body = (await c.req.json()) as Record<string, unknown>;
  const status = String(body.status ?? "");
  if (!status) return c.json({ error: "status is required" }, 400);

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

  return c.json({ updated: true, status });
});
