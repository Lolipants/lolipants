import { Hono } from "hono";
import { v4 as uuidv4 } from "uuid";
import { apiError } from "../lib/http";
import { requireAuth } from "../middleware/auth";
import { designerCommissionPct } from "../lib/commissionConfig";
import {
  designHasRenderablePreview,
  designPreviewImageUrl,
} from "../lib/designPreview";
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
      primary_colour, accent_colour, pattern_id, print_image_url, sketch_image_url, preset_style_id, text_layers, render_metadata, is_public)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
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
      body.sketchImageUrl ?? null,
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
      primary_colour = ?, accent_colour = ?, pattern_id = ?, print_image_url = ?, sketch_image_url = ?,
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
      Object.prototype.hasOwnProperty.call(body, "sketchImageUrl")
        ? body.sketchImageUrl ?? null
        : existing.sketch_image_url,
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

  const clientMeta =
    body.renderMetadata != null &&
    typeof body.renderMetadata === "object" &&
    !Array.isArray(body.renderMetadata)
      ? (body.renderMetadata as Record<string, unknown>)
      : {};

  const existingPrint =
    (existing.printTransform as Record<string, unknown> | undefined) ?? {};
  const clientPrint =
    (clientMeta.printTransform as Record<string, unknown> | undefined) ?? {};

  const printPlacement =
    body.printPlacement?.toString() ??
    clientPrint.placement?.toString() ??
    existingPrint.placement?.toString() ??
    existing.printPlacement?.toString() ??
    "chest";
  const printOffsetX = Number(
    body.printOffsetX ?? clientPrint.x ?? existingPrint.x ?? existing.printOffsetX ?? 0,
  );
  const printOffsetY = Number(
    body.printOffsetY ?? clientPrint.y ?? existingPrint.y ?? existing.printOffsetY ?? 0,
  );
  const printScale = Number(
    body.printScale ?? clientPrint.scale ?? existingPrint.scale ?? existing.printScale ?? 40,
  );
  const textLayers =
    textLayersOverride ?? body.textLayers ?? clientMeta.textLayers ?? existing.textLayers ?? [];
  const printImageUrl =
    body.printImageUrl?.toString() ??
    clientMeta.printImageUrl?.toString() ??
    existing.printImageUrl?.toString() ??
    null;
  const primaryColour =
    body.primaryColour?.toString() ??
    clientMeta.primaryColour?.toString() ??
    existing.primaryColour?.toString() ??
    "#162F28";
  const accentColour =
    body.accentColour?.toString() ??
    clientMeta.accentColour?.toString() ??
    existing.accentColour?.toString() ??
    "#C9A84C";
  const garmentType =
    body.garmentType?.toString() ??
    clientMeta.garmentType?.toString() ??
    existing.garmentType?.toString() ??
    "thobe";
  const fabricProfile =
    body.fabricQuality?.toString() ??
    clientMeta.fabricProfile?.toString() ??
    existing.fabricProfile?.toString() ??
    "standard";

  const catalogDesignPath =
    clientMeta.catalogDesignPath?.toString() ??
    clientMeta.selectedCatalogDesignPath?.toString() ??
    existing.catalogDesignPath?.toString() ??
    existing.selectedCatalogDesignPath?.toString() ??
    null;

  return {
    ...existing,
    ...clientMeta,
    editorMannequinId:
      clientMeta.editorMannequinId?.toString() ??
      existing.editorMannequinId?.toString() ??
      mannequinId ??
      null,
    mannequinTemplateId:
      body.mannequinTemplateId?.toString() ??
      clientMeta.mannequinTemplateId?.toString() ??
      existing.mannequinTemplateId?.toString() ??
      (mannequinId ?? "default_thobe_v1"),
    garmentType,
    primaryColour,
    accentColour,
    fabricProfile,
    printImageUrl,
    catalogDesignPath,
    selectedCatalogDesignPath:
      clientMeta.selectedCatalogDesignPath?.toString() ??
      catalogDesignPath ??
      existing.selectedCatalogDesignPath?.toString() ??
      null,
    printTransform: {
      ...existingPrint,
      ...clientPrint,
      placement: printPlacement,
      x: printOffsetX,
      y: printOffsetY,
      scale: printScale,
    },
    textLayers,
    exportTier:
      body.exportTier?.toString() ??
      clientMeta.exportTier?.toString() ??
      existing.exportTier?.toString() ??
      "editor",
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

  const linkedOrder = await c.env.DB.prepare(
    "SELECT id FROM orders WHERE design_id = ? LIMIT 1",
  )
    .bind(id)
    .first<{ id: string }>();
  if (linkedOrder) {
    return apiError(
      c,
      409,
      "DESIGN_HAS_ORDERS",
      "This design has orders and cannot be deleted.",
    );
  }

  try {
    await c.env.DB.prepare("DELETE FROM designs WHERE id = ? AND user_id = ?")
      .bind(id, userId)
      .run();
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    if (/FOREIGN KEY constraint failed/i.test(message)) {
      return apiError(
        c,
        409,
        "DESIGN_IN_USE",
        "This design is linked to other records and cannot be deleted.",
      );
    }
    throw e;
  }
  return c.json({ success: true });
});

designRoutes.patch("/:id/publish", async (c) => {
  const userId = c.get("userId") as string;
  const id = c.req.param("id");
  const existing = await c.env.DB.prepare(
    "SELECT * FROM designs WHERE id = ? AND user_id = ?",
  )
    .bind(id, userId)
    .first<Record<string, unknown>>();
  if (!existing) return apiError(c, 404, "DESIGN_NOT_FOUND", "Design not found");
  if (!designHasRenderablePreview(existing)) {
    return apiError(
      c,
      400,
      "PREVIEW_REQUIRED",
      "Save a design preview before publishing to the showcase",
    );
  }
  const wasPublic = Boolean(existing.is_public);
  const pct = designerCommissionPct(c.env);
  await c.env.DB.prepare(
    `UPDATE designs SET is_public = 1, published_at = datetime('now'),
      commission_terms_version = 'v1', updated_at = datetime('now')
     WHERE id = ? AND user_id = ?`,
  )
    .bind(id, userId)
    .run();
  const updated = await c.env.DB.prepare("SELECT * FROM designs WHERE id = ?")
    .bind(id)
    .first<Record<string, unknown>>();
  if (updated && !wasPublic) {
    await _announceDesignToFeed(c.env.DB, userId, updated);
  }
  return c.json({ design: updated, commissionPct: pct, termsVersion: "v1" });
});

designRoutes.patch("/:id/unpublish", async (c) => {
  const userId = c.get("userId") as string;
  const id = c.req.param("id");
  const existing = await c.env.DB.prepare(
    "SELECT id FROM designs WHERE id = ? AND user_id = ?",
  )
    .bind(id, userId)
    .first<{ id: string }>();
  if (!existing) return apiError(c, 404, "DESIGN_NOT_FOUND", "Design not found");
  await c.env.DB.prepare(
    `UPDATE designs SET is_public = 0, updated_at = datetime('now')
     WHERE id = ? AND user_id = ?`,
  )
    .bind(id, userId)
    .run();
  const updated = await c.env.DB.prepare("SELECT * FROM designs WHERE id = ?")
    .bind(id)
    .first();
  return c.json(updated);
});

designRoutes.get("/me/public", async (c) => {
  const userId = c.get("userId") as string;
  const { results } = await c.env.DB.prepare(
    "SELECT * FROM designs WHERE user_id = ? AND is_public = 1 ORDER BY published_at DESC, updated_at DESC",
  )
    .bind(userId)
    .all();
  return c.json(results);
});

async function _announceDesignToFeed(
  db: Env["DB"],
  userId: string,
  design: Record<string, unknown>,
): Promise<void> {
  const name = String(design.name ?? "My design").trim() || "My design";
  const garment = String(design.garment_type ?? "design")
    .trim()
    .toLowerCase();
  const preview = designPreviewImageUrl({
    print_image_url: design.print_image_url as string | null | undefined,
    sketch_image_url: design.sketch_image_url as string | null | undefined,
    render_metadata: design.render_metadata as string | null | undefined,
  });
  const imageUrls = preview ? [preview] : [];
  const tags = garment === "showcase" ? ["showcase"] : [garment, "showcase"];
  const body = `${name} is on Showcase — order it to support my design!`;
  const postId = uuidv4();
  await db
    .prepare(
      "INSERT INTO posts (id, author_id, body, image_urls, tags) VALUES (?, ?, ?, ?, ?)",
    )
    .bind(
      postId,
      userId,
      body,
      JSON.stringify(imageUrls),
      JSON.stringify(tags),
    )
    .run();
}
