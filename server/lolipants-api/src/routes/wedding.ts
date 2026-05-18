import { Hono } from "hono";
import type { AppVariables, Env } from "../types";

export const weddingRoutes = new Hono<{ Bindings: Env; Variables: AppVariables }>();

weddingRoutes.get("/dresses", async (c) => {
  const category = (c.req.query("category") ?? "").trim();
  let query =
    `SELECT id, label_en, label_ar, category, image_url,
            rent_price_per_day, sale_price, insurance_deposit,
            is_active, sort_order, created_at, updated_at
     FROM wedding_dresses
     WHERE is_active = 1`;
  const bindings: Array<string> = [];
  if (category === "wedding_dress" || category === "bridesmaid") {
    query += " AND category = ?";
    bindings.push(category);
  }
  query += " ORDER BY sort_order ASC, created_at DESC LIMIT 200";
  const stmt = c.env.DB.prepare(query);
  const { results } =
    bindings.length > 0
      ? await stmt.bind(...bindings).all()
      : await stmt.all();
  return c.json(results ?? []);
});
