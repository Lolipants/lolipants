import { Hono } from "hono";
import { requireAuth } from "../middleware/auth";
import type { AppVariables, Env } from "../types";

export const showcaseRoutes = new Hono<{ Bindings: Env; Variables: AppVariables }>();
showcaseRoutes.use("*", requireAuth);

const VALID_SORTS = new Set(["trending", "newest", "most_ordered"]);
const PAGE_SIZE = 20;

type ShowcaseRow = {
  id: string;
  name: string;
  garment_type: string;
  primary_colour: string;
  accent_colour: string | null;
  fabric_quality: string | null;
  print_image_url: string | null;
  order_count: number | null;
  created_at: string;
  designer_id: string;
  designer_name: string | null;
  designer_avatar_url: string | null;
  designer_is_pro: number | null;
  recent_orders: number | null;
  recent_reactions: number | null;
};

function shape(row: ShowcaseRow) {
  return {
    designId: row.id,
    name: row.name,
    garmentType: row.garment_type,
    primaryColour: row.primary_colour,
    accentColour: row.accent_colour,
    fabricQuality: row.fabric_quality,
    previewImageUrl: row.print_image_url,
    orderCount: Number(row.order_count ?? 0),
    createdAt: row.created_at,
    designer: {
      id: row.designer_id,
      name: row.designer_name ?? "Lolipants Designer",
      avatarUrl: row.designer_avatar_url,
      isProDesigner: Boolean(row.designer_is_pro),
    },
    trendingScore:
      Number(row.recent_orders ?? 0) * 2 + Number(row.recent_reactions ?? 0),
  };
}

showcaseRoutes.get("/", async (c) => {
  const sortParam = (c.req.query("sort") ?? "trending").trim().toLowerCase();
  const sort = VALID_SORTS.has(sortParam) ? sortParam : "trending";
  const cursor = Number(c.req.query("cursor") ?? "0") || 0;
  const garment = c.req.query("garment")?.trim().toLowerCase();

  const wheres: string[] = ["d.is_public = 1"];
  const binds: unknown[] = [];
  if (garment) {
    wheres.push("LOWER(d.garment_type) = ?");
    binds.push(garment);
  }

  const orderBy = {
    newest: "COALESCE(d.published_at, d.created_at) DESC",
    most_ordered: "d.order_count DESC, d.created_at DESC",
    trending: "trending_score DESC, COALESCE(d.published_at, d.created_at) DESC",
  }[sort];

  const sql = `
    SELECT d.id, d.name, d.garment_type, d.primary_colour, d.accent_colour,
           d.fabric_quality, d.print_image_url, d.order_count, d.created_at,
           d.user_id AS designer_id,
           u.name AS designer_name, u.avatar_url AS designer_avatar_url,
           u.is_pro_designer AS designer_is_pro,
           (SELECT COUNT(*) FROM orders o WHERE o.design_id = d.id
              AND o.placed_at >= datetime('now', '-14 day')) AS recent_orders,
           0 AS recent_reactions,
           (
             (SELECT COUNT(*) FROM orders o WHERE o.design_id = d.id
                AND o.placed_at >= datetime('now', '-14 day')) * 2
           ) AS trending_score
    FROM designs d
    LEFT JOIN users u ON u.id = d.user_id
    WHERE ${wheres.join(" AND ")}
    ORDER BY ${orderBy}
    LIMIT ? OFFSET ?
  `;
  binds.push(PAGE_SIZE + 1, Math.max(cursor, 0));
  const { results } = await c.env.DB.prepare(sql)
    .bind(...binds)
    .all<ShowcaseRow>();
  const rows = (results ?? []) as ShowcaseRow[];
  const hasMore = rows.length > PAGE_SIZE;
  const pageRows = hasMore ? rows.slice(0, PAGE_SIZE) : rows;
  return c.json({
    items: pageRows.map(shape),
    nextCursor: hasMore ? cursor + PAGE_SIZE : null,
    sort,
  });
});
