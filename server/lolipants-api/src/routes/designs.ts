import { Hono } from "hono";
import { v4 as uuidv4 } from "uuid";
import { apiError } from "../lib/http";
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
  const requestedMannequinId =
    body.mannequinId?.toString().trim().length != null &&
    body.mannequinId?.toString().trim().length! > 0
      ? body.mannequinId!.toString().trim()
      : null;
  let normalizedMannequinId: string | null = requestedMannequinId;
  if (requestedMannequinId != null) {
    const mannequin = await c.env.DB.prepare(
      "SELECT id FROM mannequin_options WHERE id = ? LIMIT 1",
    )
      .bind(requestedMannequinId)
      .first<{ id: string }>();
    if (mannequin == null) {
      // Avoid hard save failures when client uses local fallback mannequin IDs.
      normalizedMannequinId = null;
    }
  }

  const renderMetadata = _buildRenderMetadata(body, normalizedMannequinId);

  await c.env.DB.prepare(
    `INSERT INTO designs (id, user_id, name, garment_type, mannequin_id, fabric_id, fabric_quality,
      primary_colour, accent_colour, pattern_id, print_image_url, preset_style_id, text_layers, render_metadata, is_public)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
  )
    .bind(
      id,
      userId,
      body.name ?? "Untitled",
      body.garmentType ?? "thobe",
      normalizedMannequinId,
      body.fabricId ?? null,
      body.fabricQuality ?? "standard",
      body.primaryColour ?? "#162F28",
      body.accentColour ?? null,
      body.patternId ?? null,
      body.printImageUrl ?? null,
      body.presetStyleId ?? null,
      JSON.stringify(body.textLayers ?? []),
      JSON.stringify(renderMetadata),
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
  if (!existing) return apiError(c, 404, "DESIGN_NOT_FOUND", "Design not found");

  let finalMannequinId: string | null = (existing.mannequin_id as string | null) ?? null;
  if (Object.prototype.hasOwnProperty.call(body, "mannequinId")) {
    const requestedMannequinId =
      body.mannequinId?.toString().trim().length != null &&
      body.mannequinId?.toString().trim().length! > 0
        ? body.mannequinId!.toString().trim()
        : null;
    if (requestedMannequinId == null) {
      finalMannequinId = null;
    } else {
      const mannequin = await c.env.DB.prepare(
        "SELECT id FROM mannequin_options WHERE id = ? LIMIT 1",
      )
        .bind(requestedMannequinId)
        .first<{ id: string }>();
      finalMannequinId = mannequin == null ? null : requestedMannequinId;
    }
  }

  await c.env.DB.prepare(
    `UPDATE designs SET
      name = ?, garment_type = ?, mannequin_id = ?, fabric_id = ?, fabric_quality = ?,
      primary_colour = ?, accent_colour = ?, pattern_id = ?, print_image_url = ?,
      preset_style_id = ?, text_layers = ?, render_metadata = ?, is_public = ?, updated_at = datetime('now')
      WHERE id = ? AND user_id = ?`,
  )
    .bind(
      body.name ?? existing.name,
      body.garmentType ?? existing.garment_type,
      finalMannequinId,
      body.fabricId ?? existing.fabric_id,
      body.fabricQuality ?? existing.fabric_quality,
      body.primaryColour ?? existing.primary_colour,
      body.accentColour ?? existing.accent_colour,
      body.patternId ?? existing.pattern_id,
      body.printImageUrl ?? existing.print_image_url,
      body.presetStyleId ?? existing.preset_style_id,
      body.textLayers ? JSON.stringify(body.textLayers) : existing.text_layers,
      Object.prototype.hasOwnProperty.call(body, "renderMetadata")
        ? JSON.stringify(
            _buildRenderMetadata(
              body,
              finalMannequinId,
              body.textLayers ?? existing.text_layers,
              existing.render_metadata?.toString(),
            ),
          )
        : existing.render_metadata,
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

function _buildRenderMetadata(
  body: Record<string, unknown>,
  mannequinId: string | null,
  textLayersOverride?: unknown,
  existingRaw?: string,
) {
  let existing: Record<string, unknown> = {};
  if (existingRaw != null && existingRaw.trim().length > 0) {
    try {
      existing = JSON.parse(existingRaw) as Record<string, unknown>;
    } catch {
      existing = {};
    }
  }
  const printPlacement = body.printPlacement?.toString() ?? existing.printPlacement?.toString() ?? "chest";
  const printOffsetX = Number(body.printOffsetX ?? existing.printOffsetX ?? 0);
  const printOffsetY = Number(body.printOffsetY ?? existing.printOffsetY ?? 0);
  const printScale = Number(body.printScale ?? existing.printScale ?? 40);
  const textLayers = textLayersOverride ?? body.textLayers ?? existing.textLayers ?? [];
  const printImageUrl = body.printImageUrl?.toString() ?? existing.printImageUrl?.toString() ?? null;
  const primaryColour = body.primaryColour?.toString() ?? existing.primaryColour?.toString() ?? "#162F28";
  const accentColour = body.accentColour?.toString() ?? existing.accentColour?.toString() ?? "#C9A84C";
  const garmentType = body.garmentType?.toString() ?? existing.garmentType?.toString() ?? "thobe";
  const fabricProfile = body.fabricQuality?.toString() ?? existing.fabricProfile?.toString() ?? "standard";

  return {
    mannequinTemplateId: body.mannequinTemplateId?.toString() ??
      existing.mannequinTemplateId?.toString() ??
      (mannequinId ?? "default_thobe_v1"),
    garmentType,
    primaryColour,
    accentColour,
    fabricProfile,
    printImageUrl,
    printTransform: {
      placement: printPlacement,
      x: printOffsetX,
      y: printOffsetY,
      scale: printScale,
    },
    textLayers,
    exportTier: body.exportTier?.toString() ?? existing.exportTier?.toString() ?? "editor",
  };
}

designRoutes.delete("/:id", async (c) => {
  const userId = c.get("userId") as string;
  const id = c.req.param("id");
  const existing = await c.env.DB.prepare(
    "SELECT id FROM designs WHERE id = ? AND user_id = ?",
  )
    .bind(id, userId)
    .first<{ id: string }>();
  if (!existing) return apiError(c, 404, "DESIGN_NOT_FOUND", "Design not found");

  await c.env.DB.prepare("DELETE FROM designs WHERE id = ? AND user_id = ?")
    .bind(id, userId)
    .run();
  return c.json({ success: true });
});
