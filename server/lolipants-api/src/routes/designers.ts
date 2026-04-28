import { Hono } from "hono";
import { apiError } from "../lib/http";
import { requireAuth } from "../middleware/auth";
import type { AppVariables, Env } from "../types";

export const designerRoutes = new Hono<{ Bindings: Env; Variables: AppVariables }>();
designerRoutes.use("*", requireAuth);

type DesignerRow = {
  id: string;
  name: string;
  email: string;
  avatar_url: string | null;
  bio: string | null;
  speciality: string | null;
  follower_count: number | null;
  is_pro_designer: number | null;
};

function shapeDesigner(row: DesignerRow, isFollowing: boolean, extras: Record<string, unknown> = {}) {
  return {
    id: row.id,
    name: row.name,
    avatarUrl: row.avatar_url,
    bio: row.bio,
    speciality: row.speciality,
    followerCount: Number(row.follower_count ?? 0),
    isProDesigner: Boolean(row.is_pro_designer),
    isFollowing,
    ...extras,
  };
}

// GET /designers/pro — list pro-designers with most followers.
designerRoutes.get("/pro", async (c) => {
  const viewerId = c.get("userId") as string;
  const { results } = await c.env.DB.prepare(
    `SELECT id, name, email, avatar_url, bio, speciality, follower_count, is_pro_designer
     FROM users
     WHERE is_pro_designer = 1
     ORDER BY follower_count DESC, name ASC
     LIMIT 100`,
  ).all<DesignerRow>();
  const rows = (results ?? []) as DesignerRow[];
  if (rows.length === 0) return c.json([]);
  const placeholders = rows.map(() => "?").join(", ");
  const follows = await c.env.DB.prepare(
    `SELECT following_id FROM follows WHERE follower_id = ? AND following_id IN (${placeholders})`,
  )
    .bind(viewerId, ...rows.map((r) => r.id))
    .all<{ following_id: string }>();
  const followingSet = new Set(
    (follows.results ?? []).map((r) => r.following_id),
  );
  return c.json(rows.map((r) => shapeDesigner(r, followingSet.has(r.id))));
});

// GET /designers/me/earnings — summary of commissions aggregated by status.
designerRoutes.get("/me/earnings", async (c) => {
  const userId = c.get("userId") as string;
  const { results } = await c.env.DB.prepare(
    `SELECT status, COUNT(*) AS count, SUM(amount) AS total
     FROM commissions
     WHERE designer_id = ?
     GROUP BY status`,
  )
    .bind(userId)
    .all<{ status: string; count: number; total: number | null }>();
  const byStatus: Record<string, { count: number; total: number }> = {
    pending: { count: 0, total: 0 },
    approved: { count: 0, total: 0 },
    paid: { count: 0, total: 0 },
    void: { count: 0, total: 0 },
  };
  for (const row of results ?? []) {
    byStatus[row.status] = {
      count: Number(row.count ?? 0),
      total: Number(row.total ?? 0),
    };
  }
  const lifetime = Object.values(byStatus).reduce((s, v) => s + v.total, 0);
  return c.json({
    currency: "QAR",
    byStatus,
    lifetimeTotal: lifetime,
    payoutPending: byStatus.approved.total,
    paidOut: byStatus.paid.total,
    unsettled: byStatus.pending.total,
  });
});

// GET /designers/me/commissions?status=pending
designerRoutes.get("/me/commissions", async (c) => {
  const userId = c.get("userId") as string;
  const status = c.req.query("status")?.trim().toLowerCase();
  const binds: unknown[] = [userId];
  let sql =
    `SELECT c.*, o.total_price, o.status AS order_status, o.delivery_city,
            d.name AS design_name
     FROM commissions c
     JOIN orders o ON o.id = c.order_id
     LEFT JOIN designs d ON d.id = o.design_id
     WHERE c.designer_id = ?`;
  if (status) {
    sql += " AND c.status = ?";
    binds.push(status);
  }
  sql += " ORDER BY c.created_at DESC LIMIT 200";
  const { results } = await c.env.DB.prepare(sql)
    .bind(...binds)
    .all<Record<string, unknown>>();
  return c.json(results ?? []);
});

// GET /designers/:id — single designer profile (with is_following).
designerRoutes.get("/:id", async (c) => {
  const viewerId = c.get("userId") as string;
  const id = c.req.param("id");
  const row = await c.env.DB.prepare(
    `SELECT id, name, email, avatar_url, bio, speciality, follower_count, is_pro_designer
     FROM users WHERE id = ?`,
  )
    .bind(id)
    .first<DesignerRow>();
  if (!row) return apiError(c, 404, "DESIGNER_NOT_FOUND", "Designer not found");

  const follow = await c.env.DB.prepare(
    "SELECT 1 AS x FROM follows WHERE follower_id = ? AND following_id = ?",
  )
    .bind(viewerId, id)
    .first<{ x: number }>();

  const totals = await c.env.DB.prepare(
    `SELECT
       (SELECT COUNT(*) FROM designs WHERE user_id = ? AND is_public = 1) AS public_designs,
       (SELECT COUNT(*) FROM orders o JOIN designs d ON d.id = o.design_id WHERE d.user_id = ?) AS orders_earned`,
  )
    .bind(id, id)
    .first<{ public_designs: number; orders_earned: number }>();

  return c.json(
    shapeDesigner(row, Boolean(follow), {
      stats: {
        publicDesigns: Number(totals?.public_designs ?? 0),
        ordersEarned: Number(totals?.orders_earned ?? 0),
      },
    }),
  );
});

// GET /designers/:id/designs — public designs for a designer.
designerRoutes.get("/:id/designs", async (c) => {
  const id = c.req.param("id");
  const { results } = await c.env.DB.prepare(
    `SELECT id, name, garment_type, primary_colour, accent_colour, print_image_url,
            fabric_quality, order_count, created_at, user_id
     FROM designs
     WHERE user_id = ? AND is_public = 1
     ORDER BY order_count DESC, created_at DESC
     LIMIT 100`,
  )
    .bind(id)
    .all<Record<string, unknown>>();
  return c.json(results ?? []);
});
