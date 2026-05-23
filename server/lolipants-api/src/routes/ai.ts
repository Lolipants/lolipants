import { Hono } from "hono";
import { apiError } from "../lib/http";
import {
  buildGarmentLookPrompt,
  DEFAULT_LOLIPANTS_LOOK_SUFFIX,
  fetchUrlAsInlinePart,
  generateGarmentLookImage,
  type GeminiInlinePart,
} from "../lib/geminiImageClient";
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
};

aiRoutes.post("/design", async (c) => {
  const { prompt, garmentType, currentStyle } = await c.req.json();

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
            "Return ONLY JSON for fashion design suggestion fields: primaryColour, accentColour, fabricId, patternId, embroideryId, description, descriptionAr.",
        },
        {
          role: "user",
          content: `Garment: ${garmentType}\nStyle: ${currentStyle ?? "none"}\nPrompt: ${prompt}`,
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

aiRoutes.post("/design-render", async (c) => {
  const userId = c.get("userId") as string;
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

  const renderProvider = c.env.GEMINI_API_KEY?.trim() ? "gemini" : "template";

  const jobId = crypto.randomUUID();
  await c.env.DB.prepare(
    `INSERT INTO design_render_jobs (
      id, user_id, design_id, mannequin_id, status, provider, provider_status, started_at
    ) VALUES (?, ?, ?, ?, 'queued', ?, 'queued', datetime('now'))`,
  )
    .bind(jobId, userId, designId, design.mannequin_id, renderProvider)
    .run();

  c.executionCtx.waitUntil(_advanceDesignRenderJob(c.env, jobId));
  return c.json({ jobId, status: "queued" }, 202);
});

aiRoutes.get("/design-render/:jobId", async (c) => {
  const userId = c.get("userId") as string;
  const jobId = c.req.param("jobId");
  const row = await c.env.DB.prepare(
    `SELECT id, user_id, design_id, mannequin_id, status, provider, provider_job_id,
      provider_status, artifact_urls, error_message, attempt_count
     FROM design_render_jobs WHERE id = ? AND user_id = ?`,
  )
    .bind(jobId, userId)
    .first<DesignRenderJobRow>();
  if (!row) {
    return apiError(c, 404, "DESIGN_RENDER_JOB_NOT_FOUND", "Render job not found");
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
  console.info(
    JSON.stringify({
      event: "design_render_start",
      jobId: row.id,
      designId: row.design_id,
      userId: row.user_id,
    }),
  );

  await env.DB.prepare(
    `UPDATE design_render_jobs
     SET status = 'rendering', provider_status = 'processing', updated_at = datetime('now')
     WHERE id = ?`,
  )
    .bind(jobId)
    .run();

  const design = await env.DB.prepare(
    `SELECT d.print_image_url, d.sketch_image_url, d.render_metadata, d.garment_type, d.mannequin_id,
      d.primary_colour, d.accent_colour, d.fabric_quality, mo.preview_url AS mannequin_preview_url
     FROM designs d
     LEFT JOIN mannequin_options mo ON mo.id = d.mannequin_id
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
  const hasRasterSource = (artifacts.heroFrontUrl ?? "").trim().length > 0;

  // Without a print/mannequin preview URL, the deterministic pipeline has nothing
  // to echo. Gemini can still generate from garment metadata alone when configured.
  if (!hasRasterSource && !geminiKey) {
    await env.DB.prepare(
      `UPDATE design_render_jobs
       SET status = 'failed', provider_status = 'failed', error_message = ?,
         artifact_urls = ?,
         failed_at = datetime('now'), updated_at = datetime('now')
       WHERE id = ?`,
    )
      .bind(
        "No print or mannequin preview on file. Add a print (or sketch), pick a catalogue mannequin with a preview, or set GEMINI_API_KEY for AI-only previews.",
        JSON.stringify(_fallbackArtifacts(design?.print_image_url ?? null)),
        jobId,
      )
      .run();
    console.warn(JSON.stringify({ event: "design_render_failed", jobId, error: "no_raster_no_gemini" }));
    return;
  }

  let finalArtifacts: Record<string, string> = { ...artifacts };
  if (geminiKey) {
    const geminiResult = await _runGeminiGarmentRefinement({
      env,
      jobId,
      userId: row.user_id,
      design: design ?? null,
      baseArtifacts: artifacts,
      normalizedTemplateId: normalized.templateId,
      geminiKey,
    });
    if (geminiResult) {
      finalArtifacts = geminiResult;
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
      console.warn(JSON.stringify({ event: "design_render_failed", jobId, error: "gemini_failed_no_fallback" }));
      return;
    }
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
  configuratorComposeImageUrl: string | null;
} {
  const empty = {
    editorMannequinImageUrl: null as string | null,
    aiLookUserPrompt: null as string | null,
    aiLookPromptSuffix: null as string | null,
    configuratorSummary: null as string | null,
    configuratorComposeImageUrl: null as string | null,
  };
  if (!renderMetadata?.trim()) return empty;
  try {
    const o = JSON.parse(renderMetadata) as Record<string, unknown>;
    const pick = (k: string) => (typeof o[k] === "string" ? (o[k] as string).trim() : "");
    const man = pick("editorMannequinImageUrl");
    const user = pick("aiLookUserPrompt");
    const suf = pick("aiLookPromptSuffix");
    const compose = pick("configuratorComposeImageUrl");
    let summary = "";
    const cfg = o["configurator"];
    if (typeof cfg === "object" && cfg !== null) {
      const block = cfg as Record<string, unknown>;
      summary = typeof block["summary"] === "string" ? block["summary"].trim() : "";
    }
    return {
      editorMannequinImageUrl: man.length > 0 ? man : null,
      aiLookUserPrompt: user.length > 0 ? user : null,
      aiLookPromptSuffix: suf.length > 0 ? suf : null,
      configuratorSummary: summary.length > 0 ? summary : null,
      configuratorComposeImageUrl: compose.length > 0 ? compose : null,
    };
  } catch {
    return empty;
  }
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

  const placement = _readPrintPlacement(design?.render_metadata ?? null);
  const textSummary = _summarizeTextLayers(design?.render_metadata ?? null);
  const hints = _readEditorRenderHints(design?.render_metadata ?? null);

  const prompt = buildGarmentLookPrompt({
    garmentType: design?.garment_type ?? "garment",
    primaryColour: design?.primary_colour ?? "#162F28",
    accentColour: design?.accent_colour ?? "#C9A84C",
    fabricQuality: design?.fabric_quality ?? "standard",
    printPlacement: placement,
    textLayersSummary: textSummary,
    userExtra: hints.aiLookUserPrompt,
    configuratorSummary: hints.configuratorSummary,
    brandSuffix: hints.aiLookPromptSuffix ?? DEFAULT_LOLIPANTS_LOOK_SUFFIX,
  });

  const garmentRefUrl =
    hints.configuratorComposeImageUrl?.trim() ||
    design?.print_image_url?.trim() ||
    null;

  const refs: GeminiInlinePart[] = [];
  const candidates: Array<{ url: string | null; caption: string }> = [
    {
      url: garmentRefUrl,
      caption: "Reference — composed garment / flat (apply to model):",
    },
    {
      url: hints.editorMannequinImageUrl ?? design?.mannequin_preview_url ?? null,
      caption: "Reference — body pose / proportions (optional):",
    },
    { url: design?.sketch_image_url ?? null, caption: "Reference — silhouette / sketch (optional):" },
  ];

  for (const c of candidates) {
    if (!c.url?.trim()) continue;
    const part = await fetchUrlAsInlinePart(c.url, fetch, MAX_REFERENCE_IMAGE_BYTES);
    if (part) {
      refs.push({ ...part, caption: c.caption });
    }
    if (refs.length >= 3) break;
  }

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

  const ext = gen.mimeType.includes("jpeg") || gen.mimeType.includes("jpg") ? "jpg" : "png";
  const objectKey = `renders/${userId}/${jobId}.${ext}`;
  try {
    await env.R2.put(objectKey, gen.bytes, {
      httpMetadata: { contentType: gen.mimeType },
    });
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    console.warn(JSON.stringify({ event: "gemini_r2_upload_failed", jobId, error: msg }));
    return null;
  }

  const baseUrl = env.CLOUDFLARE_R2_BASE_URL.replace(/\/+$/, "");
  const publicUrl = `${baseUrl}/${objectKey}`;

  return {
    ...baseArtifacts,
    fallbackPreviewUrl: baseArtifacts["heroFrontUrl"] ?? "",
    thumbnailUrl: publicUrl,
    heroFrontUrl: publicUrl,
    heroSideUrl: baseArtifacts["heroSideUrl"] ?? publicUrl,
    heroBackUrl: baseArtifacts["heroBackUrl"] ?? publicUrl,
    templateId: normalizedTemplateId,
    materialPreset: baseArtifacts["materialPreset"] ?? "",
    renderMode: "gemini_image_v1",
    geminiModel: model,
    deterministicHeroUrl: baseArtifacts["heroFrontUrl"] ?? "",
  };
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
