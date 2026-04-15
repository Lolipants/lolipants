import { Hono } from "hono";
import { v4 as uuidv4 } from "uuid";
import { requireAuth } from "../middleware/auth";
import type { AppVariables, Env } from "../types";

export const designRoutes = new Hono<{ Bindings: Env; Variables: AppVariables }>();
designRoutes.use("*", requireAuth);

designRoutes.get("/", async (c) => {
  const userId = c.get("userId") as string;
  const { results } = await c.env.DB.prepare(
    "SELECT * FROM designs WHERE user_id = ? ORDER BY created_at DESC",
  )
    .bind(userId)
    .all();
  return c.json(results);
});

designRoutes.post("/", async (c) => {
  const userId = c.get("userId") as string;
  const body = (await c.req.json()) as Record<string, unknown>;
  const id = uuidv4();

  await c.env.DB.prepare(
    `INSERT INTO designs (id, user_id, name, garment_type, mannequin_id, fabric_id, fabric_quality,
      primary_colour, accent_colour, pattern_id, print_image_url, preset_style_id, text_layers, is_public)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
  )
    .bind(
      id,
      userId,
      body.name ?? "Untitled",
      body.garmentType ?? "thobe",
      body.mannequinId ?? null,
      body.fabricId ?? null,
      body.fabricQuality ?? "standard",
      body.primaryColour ?? "#162F28",
      body.accentColour ?? null,
      body.patternId ?? null,
      body.printImageUrl ?? null,
      body.presetStyleId ?? null,
      JSON.stringify(body.textLayers ?? []),
      body.isPublic ? 1 : 0,
    )
    .run();

  const created = await c.env.DB.prepare("SELECT * FROM designs WHERE id = ?")
    .bind(id)
    .first();
  return c.json(created, 201);
});

designRoutes.patch("/:id", async (c) => {
  const userId = c.get("userId") as string;
  const id = c.req.param("id");
  const body = (await c.req.json()) as Record<string, unknown>;

  const existing = await c.env.DB.prepare(
    "SELECT * FROM designs WHERE id = ? AND user_id = ?",
  )
    .bind(id, userId)
    .first<Record<string, unknown>>();
  if (!existing) return c.json({ error: "Design not found" }, 404);

  await c.env.DB.prepare(
    `UPDATE designs SET
      name = ?, garment_type = ?, mannequin_id = ?, fabric_id = ?, fabric_quality = ?,
      primary_colour = ?, accent_colour = ?, pattern_id = ?, print_image_url = ?,
      preset_style_id = ?, text_layers = ?, is_public = ?, updated_at = datetime('now')
      WHERE id = ? AND user_id = ?`,
  )
    .bind(
      body.name ?? existing.name,
      body.garmentType ?? existing.garment_type,
      body.mannequinId ?? existing.mannequin_id,
      body.fabricId ?? existing.fabric_id,
      body.fabricQuality ?? existing.fabric_quality,
      body.primaryColour ?? existing.primary_colour,
      body.accentColour ?? existing.accent_colour,
      body.patternId ?? existing.pattern_id,
      body.printImageUrl ?? existing.print_image_url,
      body.presetStyleId ?? existing.preset_style_id,
      body.textLayers ? JSON.stringify(body.textLayers) : existing.text_layers,
      body.isPublic !== undefined
        ? body.isPublic
          ? 1
          : 0
        : existing.is_public,
      id,
      userId,
    )
    .run();

  const updated = await c.env.DB.prepare("SELECT * FROM designs WHERE id = ?")
    .bind(id)
    .first();
  return c.json(updated);
});
