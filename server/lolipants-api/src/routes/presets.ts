import { Hono } from "hono";
import type { Env } from "../types";

export const presetRoutes = new Hono<{ Bindings: Env }>();

presetRoutes.get("/", async (c) => {
  const type = c.req.query("type");
  const garmentType = c.req.query("garmentType");

  let sql = "SELECT * FROM presets WHERE is_active = 1";
  const binds: unknown[] = [];

  if (type) {
    sql += " AND type = ?";
    binds.push(type);
  }
  if (garmentType) {
    sql += " AND (garment_type = ? OR garment_type IS NULL)";
    binds.push(garmentType);
  }

  sql += " ORDER BY created_at DESC";
  const { results } = await c.env.DB.prepare(sql).bind(...binds).all();
  return c.json(results);
});
