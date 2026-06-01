import { Hono } from "hono";
import { isAccessoryCategory } from "../lib/accessoryPricing";
import type { AppVariables, Env } from "../types";

export const accessoryRoutes = new Hono<{ Bindings: Env; Variables: AppVariables }>();

accessoryRoutes.get("/", async (c) => {
  const category = (c.req.query("category") ?? "").trim();
  let query = `SELECT id, label_en, label_ar, category, image_url, sale_price,
                      description_en, description_ar, allow_addon,
                      is_active, sort_order, created_at, updated_at
               FROM accessories
               WHERE is_active = 1`;
  const bindings: string[] = [];
  if (category && isAccessoryCategory(category)) {
    query += " AND category = ?";
    bindings.push(category);
  }
  query += " ORDER BY sort_order ASC, label_en ASC LIMIT 200";
  const stmt = c.env.DB.prepare(query);
  const { results } =
    bindings.length > 0
      ? await stmt.bind(...bindings).all()
      : await stmt.all();
  return c.json(results ?? []);
});
