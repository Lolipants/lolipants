export type CourierPick = {
  courierId: string;
  courierName: string;
  activeDeliveries: number;
};

type CourierRow = {
  id: string;
  name: string | null;
  active_count: number;
};

/**
 * Picks the delivery-role user with the fewest in-progress deliveries
 * (ready_to_ship or out_for_delivery). Tie-break by user id for stability.
 */
export async function pickCourierForDelivery(
  db: D1Database,
): Promise<CourierPick | null> {
  const { results } = await db
    .prepare(
      `SELECT u.id, u.name,
              (SELECT COUNT(*) FROM orders o
               WHERE o.courier_id = u.id
                 AND o.status IN ('ready_to_ship', 'out_for_delivery')) AS active_count
       FROM users u
       WHERE u.role = 'delivery'
         AND (u.banned_at IS NULL OR u.banned_at = '')
       ORDER BY active_count ASC, u.id ASC
       LIMIT 1`,
    )
    .all<CourierRow>();

  const row = results?.[0];
  if (!row?.id) return null;

  return {
    courierId: row.id,
    courierName: row.name?.trim() || "Delivery partner",
    activeDeliveries: Number(row.active_count ?? 0),
  };
}

/** Assigns a courier to [orderId] when none is set yet. */
export async function assignCourierToOrder(
  db: D1Database,
  orderId: string,
): Promise<CourierPick | null> {
  const existing = await db
    .prepare("SELECT courier_id FROM orders WHERE id = ?")
    .bind(orderId)
    .first<{ courier_id: string | null }>();
  if (!existing) return null;
  if (existing.courier_id) {
    const courier = await db
      .prepare("SELECT id, name FROM users WHERE id = ?")
      .bind(existing.courier_id)
      .first<{ id: string; name: string | null }>();
    if (!courier) return null;
    return {
      courierId: courier.id,
      courierName: courier.name?.trim() || "Delivery partner",
      activeDeliveries: 0,
    };
  }

  const picked = await pickCourierForDelivery(db);
  if (!picked) return null;

  await db
    .prepare(
      "UPDATE orders SET courier_id = ?, updated_at = datetime('now') WHERE id = ? AND courier_id IS NULL",
    )
    .bind(picked.courierId, orderId)
    .run();

  return picked;
}
