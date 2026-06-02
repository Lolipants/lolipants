import { Hono } from "hono";
import { apiError } from "../lib/http";
import {
  buildGarmentLookPrompt,
  CATALOG_DRESS_REF_CAPTION,
  COMPOSE_PREVIEW_LAYOUT_REF_CAPTION,
  COMPOSE_PREVIEW_REF_CAPTION,
  DEFAULT_LOLIPANTS_LOOK_SUFFIX,
  FABRIC_MATERIAL_LOOK_SUFFIX,
  FABRIC_SWATCH_REF_CAPTION,
  fetchUrlAsInlinePart,
  generateGarmentLookImage,
  inlinePartToBytes,
  type GeminiInlinePart,
} from "../lib/geminiImageClient";
import {
  DEFAULT_OPENAI_IMAGE_MODEL,
  generateGarmentLookImageEditOpenAI,
  generateGarmentLookImageOpenAI,
} from "../lib/openaiImageClient";
import { buildR2PublicUrl, resolveCatalogAssetPublicUrl } from "../lib/r2PublicUrl";
import {
  AI_RENDER_WEEKLY_LIMIT,
  getAiRenderQuota,
} from "../lib/aiRenderQuota";
import { normalizeRenderMetadata } from "../lib/renderNormalization";
import { requireAuth } from "../middleware/auth";
import type { AppVariables, Env } from "../types";

const DEFAULT_GEMINI_IMAGE_MODEL = "gemini-2.5-flash-image";
const MAX_REFERENCE_IMAGE_BYTES = 4 * 1024 * 1024;

export const aiRoutes = new Hono<{ Bindings: Env; Variables: AppVariables }>();
aiRoutes.use("*", requireAuth);

type MannequinJobRow = {
  id: string;
  user_id: string;
  status: string;
  source_url: string;
  preview_url: string | null;
  provider: string | null;
  provider_job_id: string | null;
  provider_status: string | null;
  artifact_urls: string | null;
  error_message: string | null;
  retry_count: number | null;
};

type DesignRenderJobRow = {
  id: string;
  user_id: string;
  design_id: string;
  mannequin_id: string | null;
  status: string;
  provider: string | null;
  provider_job_id: string | null;
  provider_status: string | null;
  artifact_urls: string | null;
  error_message: string | null;
  attempt_count: number | null;
};

type DesignRenderSourceRow = {
  print_image_url: string | null;
  sketch_image_url: string | null;
  render_metadata: string | null;
  garment_type: string | null;
  mannequin_id: string | null;
  primary_colour: string | null;
  accent_colour: string | null;
  fabric_quality: string | null;
  fabric_name: string | null;
  fabric_swatch_url: string | null;
};

aiRoutes.post("/design", async (c) => {
  const { prompt, garmentType, currentStyle, gender } = await c.req.json();

  const genderLine =
    typeof gender === "string" && gender.trim().length > 0
      ? `\nShopper gender lane: ${gender.trim()} — suggest modest formalwear appropriate for this lane.`
      : "";

  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${c.env.OPENAI_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: "gpt-4o-mini",
      messages: [
        {
          role: "system",
          content:
            "Return ONLY JSON for fashion design suggestion fields: primaryColour, accentColour, fabricId, patternId, embroideryId, description, descriptionAr. " +
            "primaryColour and accentColour MUST be #RRGGBB hex codes (e.g. #FFFFFF for white, #C9A84C for gold), never colour names.",
        },
        {
          role: "user",
          content: `Garment: ${garmentType}\nStyle: ${currentStyle ?? "none"}${genderLine}\nPrompt: ${prompt}`,
        },
      ],
      temperature: 0.7,
      max_tokens: 350,
    }),
  });

  if (!response.ok) {
    return apiError(c, 503, "AI_SERVICE_UNAVAILABLE", "AI service unavailable");
  }
  const data = (await response.json()) as { choices?: Array<{ message?: { content?: string } }> };
  const raw = data.choices?.[0]?.message?.content ?? "{}";
  try {
    return c.json(JSON.parse(raw));
  } catch {
    return apiError(c, 500, "AI_PARSE_FAILED", "Could not parse AI response");
  }
});

aiRoutes.post("/measure", async (c) => {
  const { imageBase64 } = await c.req.json();
  if (!imageBase64) {
    return apiError(c, 400, "IMAGE_BASE64_REQUIRED", "imageBase64 is required");
  }

  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${c.env.OPENAI_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: "gpt-4o",
      messages: [
        {
          role: "user",
          content: [
            {
              type: "text",
              text: "Estimate body measurements in cm from this image. Return ONLY JSON with chest, waist, hips, shoulderWidth, height, armLength.",
            },
            {
              type: "image_url",
              image_url: {
                url: `data:image/jpeg;base64,${imageBase64}`,
                detail: "high",
              },
            },
          ],
        },
      ],
      max_tokens: 200,
    }),
  });

  if (!response.ok) {
    return apiError(
      c,
      503,
      "AI_MEASURE_SERVICE_UNAVAILABLE",
      "AI measurement service unavailable",
    );
  }
  const data = (await response.json()) as { choices?: Array<{ message?: { content?: string } }> };
  const raw = data.choices?.[0]?.message?.content ?? "{}";
  try {
    return c.json(JSON.parse(raw));
  } catch {
    return apiError(
      c,
      500,
      "AI_MEASURE_PARSE_FAILED",
      "Could not parse measurement response",
    );
  }
});

aiRoutes.post("/mannequin", async (c) => {
  return apiError(
    c,
    503,
    "MANNEQUIN_GENERATION_DISABLED",
    "Custom photo mannequin generation is disabled in low-cost mode",
  );
});

aiRoutes.get("/mannequin/:jobId", async (c) => {
  const userId = c.get("userId") as string;
  const jobId = c.req.param("jobId");
  const row = await c.env.DB.prepare(
    `SELECT id, user_id, status, source_url, preview_url, provider, provider_job_id,
      provider_status, artifact_urls, error_message, retry_count
     FROM mannequin_jobs WHERE id = ? AND user_id = ?`,
  )
    .bind(jobId, userId)
    .first<MannequinJobRow>();
  if (!row) {
    return apiError(c, 404, "MANNEQUIN_JOB_NOT_FOUND", "Mannequin job not found");
  }

  if (row.status === "completed" && row.preview_url) {
    return c.json({
      jobId,
      status: "completed",
      providerStatus: row.provider_status ?? "completed",
      artifacts: _safeParseArtifactUrls(row.artifact_urls),
      mannequin: {
        id: `generated_${jobId}`,
        labelEn: "My 3D Mannequin",
        labelAr: "مانيكاني ثلاثي الأبعاد",
        previewUrl: row.preview_url,
      },
    });
  }
  if (row.status === "failed") {
    return c.json(
      {
        jobId,
        status: "failed",
        providerStatus: row.provider_status ?? "failed",
        error: row.error_message ?? "Mannequin generation failed",
      },
      200,
    );
  }
  return c.json(
    {
      jobId,
      status: row.status,
      providerStatus: row.provider_status ?? "queued",
      progress: _providerProgressFromStatus(row.provider_status),
    },
    200,
  );
});

aiRoutes.get("/design-render/quota", async (c) => {
  const userId = c.get("userId") as string;
  const quota = await getAiRenderQuota(c.env.DB, userId);
  return c.json(quota);
});

aiRoutes.post("/design-render", async (c) => {
  const userId = c.get("userId") as string;
  const quota = await getAiRenderQuota(c.env.DB, userId);
  if (quota.remaining <= 0) {
    return apiError(
      c,
      429,
      "AI_RENDER_WEEKLY_LIMIT",
      `You've used all ${AI_RENDER_WEEKLY_LIMIT} AI renders for this week. Try again after your quota resets.`,
      quota,
    );
  }

  const body = (await c.req.json()) as Record<string, unknown>;
  const designId = body.designId?.toString().trim() ?? "";
  if (designId.length === 0) {
    return apiError(c, 400, "DESIGN_ID_REQUIRED", "designId is required");
  }

  const design = await c.env.DB.prepare(
    "SELECT id, mannequin_id, print_image_url FROM designs WHERE id = ? AND user_id = ?",
  )
    .bind(designId, userId)
    .first<{ id: string; mannequin_id: string | null; print_image_url: string | null }>();
  if (!design) {
    return apiError(c, 404, "DESIGN_NOT_FOUND", "Design not found");
  }

  const renderProvider = _resolveInitialRenderProvider(c.env);

  const jobId = crypto.randomUUID();
  await c.env.DB.prepare(
    `INSERT INTO design_render_jobs (
      id, user_id, design_id, mannequin_id, status, provider, provider_status, started_at
    ) VALUES (?, ?, ?, ?, 'queued', ?, 'queued', datetime('now'))`,
  )
    .bind(jobId, userId, designId, design.mannequin_id, renderProvider)
    .run();

  return c.json({ jobId, status: "queued" }, 202);
});

aiRoutes.get("/design-render/:jobId", async (c) => {
  const userId = c.get("userId") as string;
  const jobId = c.req.param("jobId");
  let row = await c.env.DB.prepare(
    `SELECT id, user_id, design_id, mannequin_id, status, provider, provider_job_id,
      provider_status, artifact_urls, error_message, attempt_count
     FROM design_render_jobs WHERE id = ? AND user_id = ?`,
  )
    .bind(jobId, userId)
    .first<DesignRenderJobRow>();
  if (!row) {
    return apiError(c, 404, "DESIGN_RENDER_JOB_NOT_FOUND", "Render job not found");
  }

  // Run AI work on the poll request so the client connection stays open (waitUntil
  // is capped at ~30s — too short for gpt-image-1 / Gemini image generation).
  if (row.status === "queued" || row.status === "rendering") {
    try {
      await _advanceDesignRenderJob(c.env, jobId);
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      console.error(JSON.stringify({ event: "design_render_unhandled", jobId, error: msg }));
      await c.env.DB.prepare(
        `UPDATE design_render_jobs
         SET status = 'failed', provider_status = 'failed', error_message = ?,
           failed_at = datetime('now'), updated_at = datetime('now')
         WHERE id = ?`,
      )
        .bind("AI preview failed on the server. Please try again.", jobId)
        .run();
    }
    row =
      (await c.env.DB.prepare(
        `SELECT id, user_id, design_id, mannequin_id, status, provider, provider_job_id,
          provider_status, artifact_urls, error_message, attempt_count
         FROM design_render_jobs WHERE id = ? AND user_id = ?`,
      )
        .bind(jobId, userId)
        .first<DesignRenderJobRow>()) ?? row;
  }

  return c.json({
    jobId,
    designId: row.design_id,
    status: row.status,
    providerStatus: row.provider_status ?? "queued",
    progress: _providerProgressFromStatus(row.provider_status),
    artifacts: _safeParseArtifactUrls(row.artifact_urls),
    error: row.error_message,
  });
});

async function _advanceDesignRenderJob(env: Env, jobId: string) {
  const startMs = Date.now();
  const row = await env.DB.prepare(
    `SELECT id, user_id, design_id, mannequin_id, status, provider, provider_job_id,
      provider_status, artifact_urls, error_message, attempt_count
     FROM design_render_jobs WHERE id = ?`,
  )
    .bind(jobId)
    .first<DesignRenderJobRow>();
  if (!row || row.status === "completed" || row.status === "failed") return;

  const claim = await env.DB.prepare(
    `UPDATE design_render_jobs
     SET status = 'rendering', provider_status = 'processing', updated_at = datetime('now')
     WHERE id = ?
       AND status IN ('queued', 'rendering')
       AND (
         status = 'queued'
         OR datetime(updated_at) < datetime('now', '-45 seconds')
       )`,
  )
    .bind(jobId)
    .run();
  if ((claim.meta?.changes ?? 0) === 0) return;

  console.info(
    JSON.stringify({
      event: "design_render_start",
      jobId: row.id,
      designId: row.design_id,
      userId: row.user_id,
    }),
  );

  const design = await env.DB.prepare(
    `SELECT d.print_image_url, d.sketch_image_url, d.render_metadata, d.garment_type, d.mannequin_id,
      d.primary_colour, d.accent_colour, d.fabric_quality,
      fo.name AS fabric_name, fo.swatch_url AS fabric_swatch_url,
      mo.preview_url AS mannequin_preview_url
     FROM designs d
     LEFT JOIN mannequin_options mo ON mo.id = d.mannequin_id
     LEFT JOIN fabric_options fo ON fo.id = d.fabric_id
     WHERE d.id = ? AND d.user_id = ?`,
  )
    .bind(row.design_id, row.user_id)
    .first<DesignRenderSourceRow & { mannequin_preview_url: string | null }>();

  const normalized = normalizeRenderMetadata({
    garmentType: design?.garment_type,
    mannequinId: design?.mannequin_id,
    primaryColour: design?.primary_colour,
    accentColour: design?.accent_colour,
    printImageUrl: design?.print_image_url,
    renderMetadataRaw: design?.render_metadata,
  });

  const artifacts = _buildDeterministicArtifacts({
    printImageUrl: design?.print_image_url ?? null,
    mannequinPreviewUrl: design?.mannequin_preview_url ?? null,
    templateId: normalized.templateId,
    materialPreset: normalized.materialPreset,
  });
  const geminiKey = env.GEMINI_API_KEY?.trim();
  const openaiKey = env.OPENAI_API_KEY?.trim();
  const hasAiImageProvider = Boolean(geminiKey || openaiKey);
  const hasRasterSource = (artifacts.heroFrontUrl ?? "").trim().length > 0;

  // Without a print/mannequin preview URL, the deterministic pipeline has nothing
  // to echo. AI image providers can still generate from garment metadata alone.
  if (!hasRasterSource && !hasAiImageProvider) {
    await env.DB.prepare(
      `UPDATE design_render_jobs
       SET status = 'failed', provider_status = 'failed', error_message = ?,
         artifact_urls = ?,
         failed_at = datetime('now'), updated_at = datetime('now')
       WHERE id = ?`,
    )
      .bind(
        "No print or mannequin preview on file. Add a print (or sketch), pick a catalogue mannequin with a preview, or configure GEMINI_API_KEY / OPENAI_API_KEY for AI-only previews.",
        JSON.stringify(_fallbackArtifacts(design?.print_image_url ?? null)),
        jobId,
      )
      .run();
    console.warn(JSON.stringify({ event: "design_render_failed", jobId, error: "no_raster_no_ai" }));
    return;
  }

  let finalArtifacts: Record<string, string> = { ...artifacts };
  let aiResult: Record<string, string> | null = null;

  if (geminiKey) {
    aiResult = await _runGeminiGarmentRefinement({
      env,
      jobId,
      userId: row.user_id,
      design: design ?? null,
      baseArtifacts: artifacts,
      normalizedTemplateId: normalized.templateId,
      geminiKey,
    });
  }

  if (!aiResult && openaiKey) {
    aiResult = await _runOpenAiGarmentRefinement({
      env,
      jobId,
      userId: row.user_id,
      design: design ?? null,
      baseArtifacts: artifacts,
      normalizedTemplateId: normalized.templateId,
      openaiKey,
      afterGeminiFailure: Boolean(geminiKey),
    });
  }

  if (aiResult) {
    finalArtifacts = aiResult;
  } else if (!hasRasterSource) {
    await env.DB.prepare(
      `UPDATE design_render_jobs
       SET status = 'failed', provider_status = 'failed', error_message = ?,
         artifact_urls = ?,
         failed_at = datetime('now'), updated_at = datetime('now')
       WHERE id = ?`,
    )
      .bind(
        "AI preview failed. Add a print or sketch image, save, and try again.",
        JSON.stringify(_fallbackArtifacts(design?.print_image_url ?? null)),
        jobId,
      )
      .run();
    console.warn(JSON.stringify({ event: "design_render_failed", jobId, error: "ai_image_failed_no_fallback" }));
    return;
  }

  const elapsedMs = Date.now() - startMs;
  await env.DB.prepare(
    `UPDATE design_render_jobs
     SET status = 'completed', provider_status = 'completed', attempt_count = ?, artifact_urls = ?,
       completed_at = datetime('now'), updated_at = datetime('now')
     WHERE id = ?`,
  )
    .bind(1, JSON.stringify(finalArtifacts), jobId)
    .run();
  console.info(
    JSON.stringify({
      event: "design_render_completed",
      jobId,
      retries: 1,
      elapsedMs,
      templateId: normalized.templateId,
      materialPreset: normalized.materialPreset,
      renderMode: finalArtifacts["renderMode"] ?? artifacts["renderMode"],
    }),
  );
}

function _readEditorRenderHints(renderMetadata: string | null): {
  editorMannequinImageUrl: string | null;
  aiLookUserPrompt: string | null;
  aiLookPromptSuffix: string | null;
  configuratorSummary: string | null;
  configuratorAiLayerNotes: string | null;
  configuratorComposeImageUrl: string | null;
  catalogFlatImageUrl: string | null;
  buildStyleMode: string | null;
} {
  const empty = {
    editorMannequinImageUrl: null as string | null,
    aiLookUserPrompt: null as string | null,
    aiLookPromptSuffix: null as string | null,
    configuratorSummary: null as string | null,
    configuratorAiLayerNotes: null as string | null,
    configuratorComposeImageUrl: null as string | null,
    catalogFlatImageUrl: null as string | null,
    buildStyleMode: null as string | null,
  };
  if (!renderMetadata?.trim()) return empty;
  try {
    const o = JSON.parse(renderMetadata) as Record<string, unknown>;
    const pick = (k: string) => (typeof o[k] === "string" ? (o[k] as string).trim() : "");
    const man = pick("editorMannequinImageUrl");
    const user = pick("aiLookUserPrompt");
    const suf = pick("aiLookPromptSuffix");
    const compose = pick("configuratorComposeImageUrl");
    const catalogFlat = pick("catalogFlatImageUrl");
    const buildStyleMode = pick("buildStyleMode");
    let summary = "";
    let aiLayerNotes = "";
    const cfg = o["configurator"];
    if (typeof cfg === "object" && cfg !== null) {
      const block = cfg as Record<string, unknown>;
      summary = typeof block["summary"] === "string" ? block["summary"].trim() : "";
      aiLayerNotes =
        typeof block["aiLayerNotes"] === "string" ? block["aiLayerNotes"].trim() : "";
    }
    const resolvedAiLayerNotes =
      aiLayerNotes.length > 0
        ? aiLayerNotes
        : _inferConfiguratorAiLayerNotesFromSummary(summary);
    return {
      editorMannequinImageUrl: man.length > 0 ? man : null,
      aiLookUserPrompt: user.length > 0 ? user : null,
      aiLookPromptSuffix: suf.length > 0 ? suf : null,
      configuratorSummary: summary.length > 0 ? summary : null,
      configuratorAiLayerNotes:
        resolvedAiLayerNotes.length > 0 ? resolvedAiLayerNotes : null,
      configuratorComposeImageUrl: compose.length > 0 ? compose : null,
      catalogFlatImageUrl: catalogFlat.length > 0 ? catalogFlat : null,
      buildStyleMode: buildStyleMode.length > 0 ? buildStyleMode : null,
    };
  } catch {
    return empty;
  }
}

/** Fallback when older saves lack `configurator.aiLayerNotes`. */
function _inferConfiguratorAiLayerNotesFromSummary(summary: string): string {
  const trimmed = summary.trim();
  if (!trimmed) return "";
  const lines = [
    "AI layer interpretation (inferred from slot summary — follow strictly):",
    "- CHEST / OVERLAY panels are front-torso decorations ONLY — never extend them as sleeves.",
  ];
  const lower = trimmed.toLowerCase();
  if (
    lower.includes("no sleeves") ||
    lower.includes("sleeveless") ||
    /sleeves?\s*—\s*no\b/.test(lower)
  ) {
    lines.push(
      "- NO SLEEVES on this design — arms stay bare; do NOT add or infer sleeve fabric.",
    );
  }
  if (lower.includes("chest panel") || lower.includes("overlay")) {
    lines.push(
      "- Overlay / chest panel is a front decoration only — NOT sleeves, NOT arm extensions.",
    );
  }
  return lines.length > 2 ? lines.join("\n") : "";
}

function _resolveInitialRenderProvider(env: Env): string {
  if (env.GEMINI_API_KEY?.trim()) return "gemini";
  if (env.OPENAI_API_KEY?.trim()) return "openai";
  return "template";
}

function _resolveFabricSwatchUrl(
  env: Env,
  swatchPath: string | null | undefined,
): string | null {
  const resolved = resolveCatalogAssetPublicUrl(env, swatchPath)?.trim();
  if (resolved) return resolved;
  const raw = swatchPath?.trim() ?? "";
  if (raw.startsWith("http://") || raw.startsWith("https://")) return raw;
  return null;
}

function _buildGarmentLookPromptForDesign(
  design: (DesignRenderSourceRow & { mannequin_preview_url: string | null }) | null,
  env: Env,
): string {
  const placement = _readPrintPlacement(design?.render_metadata ?? null);
  const textSummary = _summarizeTextLayers(design?.render_metadata ?? null);
  const hints = _readEditorRenderHints(design?.render_metadata ?? null);
  const isCatalogDesign = hints.buildStyleMode === "catalog";
  const catalogDressUrl =
    hints.catalogFlatImageUrl?.trim() || design?.print_image_url?.trim() || null;
  const hasPreview = isCatalogDesign
    ? Boolean(catalogDressUrl)
    : Boolean(hints.configuratorComposeImageUrl?.trim() || design?.print_image_url?.trim());
  const fabricName = isCatalogDesign ? null : design?.fabric_name?.trim() || null;
  const hasFabricSwatch = isCatalogDesign
    ? false
    : Boolean(_resolveFabricSwatchUrl(env, design?.fabric_swatch_url));
  const brandSuffix = isCatalogDesign
    ? (hints.aiLookPromptSuffix ?? DEFAULT_LOLIPANTS_LOOK_SUFFIX)
    : fabricName
      ? FABRIC_MATERIAL_LOOK_SUFFIX
      : (hints.aiLookPromptSuffix ?? DEFAULT_LOLIPANTS_LOOK_SUFFIX);

  return buildGarmentLookPrompt({
    garmentType: design?.garment_type ?? "garment",
    primaryColour: design?.primary_colour ?? "#162F28",
    accentColour: design?.accent_colour ?? "#C9A84C",
    fabricName,
    hasFabricSwatchReference: hasFabricSwatch,
    fabricQuality: design?.fabric_quality ?? "standard",
    printPlacement: placement,
    textLayersSummary: textSummary,
    userExtra: hints.aiLookUserPrompt,
    configuratorSummary: isCatalogDesign ? null : hints.configuratorSummary,
    configuratorAiLayerNotes: isCatalogDesign ? null : hints.configuratorAiLayerNotes,
    brandSuffix,
    hasDesignPreviewReference: hasPreview,
    isCatalogDesignMode: isCatalogDesign,
  });
}

async function _loadGarmentLookReferenceParts(
  design: (DesignRenderSourceRow & { mannequin_preview_url: string | null }) | null,
  env: Env,
): Promise<GeminiInlinePart[]> {
  const hints = _readEditorRenderHints(design?.render_metadata ?? null);
  const isCatalogDesign = hints.buildStyleMode === "catalog";
  const swatchUrl = isCatalogDesign
    ? null
    : _resolveFabricSwatchUrl(env, design?.fabric_swatch_url);
  const refs: GeminiInlinePart[] = [];
  const useFabricSwatch = Boolean(swatchUrl);

  async function appendSwatchIfPresent(): Promise<void> {
    if (!swatchUrl) return;
    const part = await fetchUrlAsInlinePart(swatchUrl, fetch, MAX_REFERENCE_IMAGE_BYTES);
    if (part) {
      refs.push({ ...part, caption: FABRIC_SWATCH_REF_CAPTION });
    }
  }

  if (isCatalogDesign) {
    const dressUrl =
      hints.catalogFlatImageUrl?.trim() || design?.print_image_url?.trim() || null;
    if (dressUrl) {
      const part = await fetchUrlAsInlinePart(dressUrl, fetch, MAX_REFERENCE_IMAGE_BYTES);
      if (part) {
        refs.push({ ...part, caption: CATALOG_DRESS_REF_CAPTION });
      }
    }
    const mannequinUrl =
      hints.editorMannequinImageUrl ?? design?.mannequin_preview_url ?? null;
    if (mannequinUrl?.trim()) {
      const part = await fetchUrlAsInlinePart(
        mannequinUrl,
        fetch,
        MAX_REFERENCE_IMAGE_BYTES,
      );
      if (part) {
        refs.push({
          ...part,
          caption: "Mannequin pose reference — match this body pose and framing:",
        });
      }
    }
    return refs;
  }

  const composeUrl = hints.configuratorComposeImageUrl?.trim() || null;

  // Compose preview already includes mannequin + garment — use it alone when present.
  if (composeUrl) {
    const part = await fetchUrlAsInlinePart(composeUrl, fetch, MAX_REFERENCE_IMAGE_BYTES);
    if (part) {
      refs.push({
        ...part,
        caption: useFabricSwatch
          ? COMPOSE_PREVIEW_LAYOUT_REF_CAPTION
          : COMPOSE_PREVIEW_REF_CAPTION,
      });
    }
    await appendSwatchIfPresent();
    return refs;
  }

  const candidates: Array<{ url: string | null; caption: string }> = [
    {
      url: design?.print_image_url?.trim() ?? null,
      caption:
        "PRIMARY garment reference — refine on pure white background; keep layout and colours identical:",
    },
    {
      url: hints.editorMannequinImageUrl ?? design?.mannequin_preview_url ?? null,
      caption: "Mannequin reference — keep this exact pose and proportions:",
    },
    { url: design?.sketch_image_url ?? null, caption: "Silhouette / sketch reference (optional):" },
  ];

  for (const c of candidates) {
    if (!c.url?.trim()) continue;
    const part = await fetchUrlAsInlinePart(c.url, fetch, MAX_REFERENCE_IMAGE_BYTES);
    if (part) {
      refs.push({ ...part, caption: c.caption });
    }
    if (refs.length >= 3) break;
  }

  await appendSwatchIfPresent();

  return refs;
}

async function _uploadGeneratedLookArtifacts(input: {
  env: Env;
  jobId: string;
  userId: string;
  baseArtifacts: Record<string, string>;
  normalizedTemplateId: string;
  mimeType: string;
  bytes: Uint8Array;
  renderMode: string;
  modelMeta: Record<string, string>;
  uploadEvent: string;
}): Promise<Record<string, string> | null> {
  const {
    env,
    jobId,
    userId,
    baseArtifacts,
    normalizedTemplateId,
    mimeType,
    bytes,
    renderMode,
    modelMeta,
    uploadEvent,
  } = input;

  const ext = mimeType.includes("jpeg") || mimeType.includes("jpg") ? "jpg" : "png";
  const objectKey = `renders/${userId}/${jobId}.${ext}`;
  try {
    await env.R2.put(objectKey, bytes, {
      httpMetadata: { contentType: mimeType },
    });
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    console.warn(JSON.stringify({ event: uploadEvent, jobId, error: msg }));
    return null;
  }

  const publicUrl = buildR2PublicUrl(env, objectKey);
  if (!publicUrl) {
    console.warn(
      JSON.stringify({
        event: uploadEvent,
        jobId,
        error: "CLOUDFLARE_R2_BASE_URL is not configured on the worker",
      }),
    );
    return null;
  }

  return {
    ...baseArtifacts,
    fallbackPreviewUrl: baseArtifacts["heroFrontUrl"] ?? "",
    thumbnailUrl: publicUrl,
    heroFrontUrl: publicUrl,
    heroSideUrl: baseArtifacts["heroSideUrl"] ?? publicUrl,
    heroBackUrl: baseArtifacts["heroBackUrl"] ?? publicUrl,
    templateId: normalizedTemplateId,
    materialPreset: baseArtifacts["materialPreset"] ?? "",
    renderMode,
    deterministicHeroUrl: baseArtifacts["heroFrontUrl"] ?? "",
    ...modelMeta,
  };
}

async function _runGeminiGarmentRefinement(input: {
  env: Env;
  jobId: string;
  userId: string;
  design: (DesignRenderSourceRow & { mannequin_preview_url: string | null }) | null;
  baseArtifacts: Record<string, string>;
  normalizedTemplateId: string;
  geminiKey: string;
}): Promise<Record<string, string> | null> {
  const { env, jobId, userId, design, baseArtifacts, normalizedTemplateId, geminiKey } = input;
  const model =
    env.GEMINI_IMAGE_MODEL?.trim() && env.GEMINI_IMAGE_MODEL.trim().length > 0
      ? env.GEMINI_IMAGE_MODEL.trim()
      : DEFAULT_GEMINI_IMAGE_MODEL;

  const prompt = _buildGarmentLookPromptForDesign(design, env);
  const refs = await _loadGarmentLookReferenceParts(design, env);

  const gen = await generateGarmentLookImage({
    apiKey: geminiKey,
    model,
    prompt,
    referenceParts: refs,
  });

  if (!gen.ok) {
    console.warn(JSON.stringify({ event: "gemini_render_skipped", jobId, error: gen.error }));
    return null;
  }

  return _uploadGeneratedLookArtifacts({
    env,
    jobId,
    userId,
    baseArtifacts,
    normalizedTemplateId,
    mimeType: gen.mimeType,
    bytes: gen.bytes,
    renderMode: "gemini_image_v1",
    modelMeta: { geminiModel: model },
    uploadEvent: "gemini_r2_upload_failed",
  });
}

async function _runOpenAiGarmentRefinement(input: {
  env: Env;
  jobId: string;
  userId: string;
  design: (DesignRenderSourceRow & { mannequin_preview_url: string | null }) | null;
  baseArtifacts: Record<string, string>;
  normalizedTemplateId: string;
  openaiKey: string;
  afterGeminiFailure: boolean;
}): Promise<Record<string, string> | null> {
  const {
    env,
    jobId,
    userId,
    design,
    baseArtifacts,
    normalizedTemplateId,
    openaiKey,
    afterGeminiFailure,
  } = input;

  const model =
    env.OPENAI_IMAGE_MODEL?.trim() && env.OPENAI_IMAGE_MODEL.trim().length > 0
      ? env.OPENAI_IMAGE_MODEL.trim()
      : DEFAULT_OPENAI_IMAGE_MODEL;

  const prompt = _buildGarmentLookPromptForDesign(design, env);
  const refs = await _loadGarmentLookReferenceParts(design, env);

  console.info(
    JSON.stringify({
      event: afterGeminiFailure ? "openai_render_fallback" : "openai_render_primary",
      jobId,
      model,
      refineFromPreview: refs.length > 0,
    }),
  );

  let gen;
  if (refs.length > 0) {
    const primary = refs[0]!;
    gen = await generateGarmentLookImageEditOpenAI({
      apiKey: openaiKey,
      model,
      prompt,
      imageBytes: inlinePartToBytes(primary),
      mimeType: primary.mimeType,
    });
  } else {
    gen = await generateGarmentLookImageOpenAI({
      apiKey: openaiKey,
      model,
      prompt,
    });
  }

  if (!gen.ok) {
    console.warn(JSON.stringify({ event: "openai_render_skipped", jobId, error: gen.error }));
    return null;
  }

  return _uploadGeneratedLookArtifacts({
    env,
    jobId,
    userId,
    baseArtifacts,
    normalizedTemplateId,
    mimeType: gen.mimeType,
    bytes: gen.bytes,
    renderMode: "openai_image_v1",
    modelMeta: { openaiImageModel: model },
    uploadEvent: "openai_r2_upload_failed",
  });
}

function _readPrintPlacement(renderMetadata: string | null): string | null {
  if (!renderMetadata?.trim()) return null;
  try {
    const meta = JSON.parse(renderMetadata) as Record<string, unknown>;
    const pt = meta["printTransform"] as Record<string, unknown> | undefined;
    const pl = pt?.["placement"] ?? meta["printPlacement"];
    return typeof pl === "string" ? pl : null;
  } catch {
    return null;
  }
}

function _summarizeTextLayers(renderMetadata: string | null): string | null {
  if (!renderMetadata?.trim()) return null;
  try {
    const meta = JSON.parse(renderMetadata) as Record<string, unknown>;
    const raw = meta["textLayers"];
    if (!Array.isArray(raw) || raw.length === 0) return null;
    const parts: string[] = [];
    for (const layer of raw.slice(0, 6)) {
      if (typeof layer !== "object" || layer === null) continue;
      const L = layer as Record<string, unknown>;
      const text = typeof L["text"] === "string" ? L["text"] : "";
      if (text.trim()) parts.push(text.trim());
    }
    return parts.length > 0 ? parts.join(" · ") : null;
  } catch {
    return null;
  }
}

function _buildDeterministicArtifacts(input: {
  printImageUrl: string | null;
  mannequinPreviewUrl: string | null;
  templateId: string;
  materialPreset: string;
}) {
  const source =
    input.printImageUrl?.trim() ||
    input.mannequinPreviewUrl?.trim() ||
    "";
  return {
    fallbackPreviewUrl: source,
    thumbnailUrl: source,
    heroFrontUrl: source,
    heroSideUrl: source,
    heroBackUrl: source,
    templateId: input.templateId,
    materialPreset: input.materialPreset,
    renderMode: "template_static_v1",
  };
}

function _fallbackArtifacts(printImageUrl: string | null) {
  const fallback = printImageUrl?.trim() ?? "";
  return {
    fallbackPreviewUrl: fallback,
    thumbnailUrl: fallback,
    heroFrontUrl: fallback,
    heroSideUrl: fallback,
    heroBackUrl: fallback,
  };
}

function _safeParseArtifactUrls(value: string | null): Record<string, string> {
  if (!value) return {};
  try {
    const parsed = JSON.parse(value) as Record<string, unknown>;
    const out: Record<string, string> = {};
    for (const [k, v] of Object.entries(parsed)) {
      if (typeof v === "string" && v.length > 0) out[k] = v;
    }
    return out;
  } catch {
    return {};
  }
}

function _providerProgressFromStatus(status: string | null): number {
  switch ((status ?? "").toLowerCase()) {
    case "queued":
      return 0.1;
    case "processing":
      return 0.55;
    case "completed":
      return 1;
    case "failed":
      return 1;
    default:
      return 0.2;
  }
}
