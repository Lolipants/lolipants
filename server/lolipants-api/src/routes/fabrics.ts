import { Hono } from "hono";
import type { Env } from "../types";

export const fabricRoutes = new Hono<{ Bindings: Env }>();

fabricRoutes.get("/", async (c) => {
  const garmentType = c.req.query("garmentType");
  const quality = c.req.query("quality");

  let sql =
    "SELECT * FROM fabric_options WHERE is_available = 1 AND (garment_type = ? OR garment_type = 'all')";
  const binds: unknown[] = [garmentType ?? "all"];

  if (quality) {
    sql += " AND quality = ?";
    binds.push(quality);
  }

  sql += " ORDER BY name ASC";
  const { results } = await c.env.DB.prepare(sql).bind(...binds).all();
  return c.json(results);
});
