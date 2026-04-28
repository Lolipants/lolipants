import { Hono } from "hono";
import { apiError } from "../lib/http";
import { normalizeRenderMetadata } from "../lib/renderNormalization";
import { requireAuth } from "../middleware/auth";
import type { AppVariables, Env } from "../types";

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
  render_metadata: string | null;
  garment_type: string | null;
  mannequin_id: string | null;
  primary_colour: string | null;
  accent_colour: string | null;
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
  const userId = c.get("userId") as string;
  const formData = await c.req.formData();
  const photo = formData.get("photo");
  if (!(photo instanceof File)) {
    return apiError(c, 400, "PHOTO_REQUIRED", "photo is required");
  }
  if (photo.size > 12 * 1024 * 1024) {
    return apiError(c, 400, "PHOTO_TOO_LARGE", "photo exceeds 12MB limit");
  }

  const sourceKey = `mannequin-jobs/${userId}/${crypto.randomUUID()}-source.jpg`;
  await c.env.R2.put(sourceKey, await photo.arrayBuffer(), {
    httpMetadata: { contentType: photo.type || "image/jpeg" },
  });
  const sourceUrl = `${c.env.CLOUDFLARE_R2_BASE_URL}/${sourceKey}`;
  const jobId = crypto.randomUUID();

  await c.env.DB.prepare(
    `INSERT INTO mannequin_jobs (
      id, user_id, source_url, status, provider, provider_status, retry_count, started_at
    ) VALUES (?, ?, ?, 'queued', 'meshy', 'queued', 0, datetime('now'))`,
  )
    .bind(jobId, userId, sourceUrl)
    .run();

  c.executionCtx.waitUntil(_advanceMannequinJob(c.env, jobId));
  return c.json({ jobId, status: "queued" }, 202);
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

  const jobId = crypto.randomUUID();
  await c.env.DB.prepare(
    `INSERT INTO design_render_jobs (
      id, user_id, design_id, mannequin_id, status, provider, provider_status, started_at
    ) VALUES (?, ?, ?, ?, 'queued', 'meshy', 'queued', datetime('now'))`,
  )
    .bind(jobId, userId, designId, design.mannequin_id)
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

async function _advanceMannequinJob(env: Env, jobId: string) {
  const row = await env.DB.prepare(
    `SELECT id, user_id, status, source_url, preview_url, provider, provider_job_id,
      provider_status, artifact_urls, error_message, retry_count
     FROM mannequin_jobs WHERE id = ?`,
  )
    .bind(jobId)
    .first<MannequinJobRow>();
  if (!row || row.status === "completed" || row.status === "failed") return;
  console.info(
    JSON.stringify({
      event: "mannequin_job_start",
      jobId: row.id,
      userId: row.user_id,
      provider: row.provider ?? "meshy",
    }),
  );

  await env.DB.prepare(
    `UPDATE mannequin_jobs
     SET status = 'rendering', provider_status = 'processing', updated_at = datetime('now')
     WHERE id = ?`,
  )
    .bind(row.id)
    .run();

  const result = await _generateMannequinPreviewWithRetry(env, row.source_url);
  if (!result.ok) {
    await env.DB.prepare(
      `UPDATE mannequin_jobs
       SET status = 'failed', provider_status = 'failed', error_message = ?, retry_count = ?,
         failed_at = datetime('now'), updated_at = datetime('now')
       WHERE id = ?`,
    )
      .bind(result.message, result.retries, row.id)
      .run();
    console.warn(
      JSON.stringify({
        event: "mannequin_job_failed",
        jobId: row.id,
        retries: result.retries,
        error: result.message,
      }),
    );
    return;
  }

  await env.DB.prepare(
    `UPDATE mannequin_jobs
     SET status = 'completed', provider_status = 'completed', preview_url = ?, retry_count = ?,
       artifact_urls = ?, completed_at = datetime('now'), updated_at = datetime('now')
     WHERE id = ?`,
  )
    .bind(
      result.previewUrl,
      result.retries,
      JSON.stringify({ thumbnailUrl: result.previewUrl, heroFrontUrl: result.previewUrl }),
      row.id,
    )
    .run();

  const optionId = `generated_${row.id}`;
  await env.DB.prepare(
    `INSERT INTO mannequin_options (id, label_en, label_ar, preview_url, is_active, sort_order)
     VALUES (?, ?, ?, ?, 0, 9999)
     ON CONFLICT(id) DO UPDATE SET preview_url = excluded.preview_url`,
  )
    .bind(optionId, "My 3D Mannequin", "مانيكاني ثلاثي الأبعاد", result.previewUrl)
    .run();
  console.info(
    JSON.stringify({
      event: "mannequin_job_completed",
      jobId: row.id,
      retries: result.retries,
    }),
  );

}

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
    `SELECT print_image_url, render_metadata, garment_type, mannequin_id,
      primary_colour, accent_colour
     FROM designs WHERE id = ? AND user_id = ?`,
  )
    .bind(row.design_id, row.user_id)
    .first<DesignRenderSourceRow>();

  const normalized = normalizeRenderMetadata({
    garmentType: design?.garment_type,
    mannequinId: design?.mannequin_id,
    primaryColour: design?.primary_colour,
    accentColour: design?.accent_colour,
    printImageUrl: design?.print_image_url,
    renderMetadataRaw: design?.render_metadata,
  });

  const previewSource = await _composeRenderTextureSource(env, row, normalized);
  if (previewSource.length === 0) {
    await env.DB.prepare(
      `UPDATE design_render_jobs
       SET status = 'failed', provider_status = 'failed', error_message = ?,
         artifact_urls = ?,
         failed_at = datetime('now'), updated_at = datetime('now')
       WHERE id = ?`,
    )
      .bind(
        "Design has no print image to render",
        JSON.stringify(_fallbackArtifacts(design?.print_image_url ?? null)),
        jobId,
      )
      .run();
    console.warn(JSON.stringify({ event: "design_render_failed", jobId, error: "missing_print_image" }));
    return;
  }

  const generated = await _generateMannequinPreviewWithRetry(
    env,
    previewSource,
    {
      maxAttempts: 2,
      requestTimeoutMs: 9_000,
    },
  );
  if (!generated.ok) {
    await env.DB.prepare(
      `UPDATE design_render_jobs
       SET status = 'failed', provider_status = 'failed', error_message = ?, attempt_count = ?,
         artifact_urls = ?,
         failed_at = datetime('now'), updated_at = datetime('now')
       WHERE id = ?`,
    )
      .bind(
        generated.message,
        generated.retries,
        JSON.stringify(_fallbackArtifacts(design?.print_image_url ?? null)),
        jobId,
      )
      .run();
    console.warn(
      JSON.stringify({
        event: "design_render_failed",
        jobId,
        retries: generated.retries,
        error: generated.message,
      }),
    );
    return;
  }

  const artifacts = await _persistRenderArtifacts(env, row, generated.previewUrl, normalized);
  const elapsedMs = Date.now() - startMs;
  await env.DB.prepare(
    `UPDATE design_render_jobs
     SET status = 'completed', provider_status = 'completed', attempt_count = ?, artifact_urls = ?,
       completed_at = datetime('now'), updated_at = datetime('now')
     WHERE id = ?`,
  )
    .bind(generated.retries, JSON.stringify(artifacts), jobId)
    .run();
  console.info(
    JSON.stringify({
      event: "design_render_completed",
      jobId,
      retries: generated.retries,
      elapsedMs,
      templateId: normalized.templateId,
      materialPreset: normalized.materialPreset,
    }),
  );
}

async function _generateMannequinPreviewWithRetry(
  env: Env,
  sourceUrl: string,
  options?: {
    maxAttempts?: number;
    requestTimeoutMs?: number;
  },
): Promise<
  | { ok: true; previewUrl: string; retries: number }
  | { ok: false; message: string; retries: number }
> {
  const apiKey = env.MESHY_API_KEY?.trim();
  const apiBase = env.MESHY_API_BASE_URL?.trim() || "https://api.meshy.ai/openapi/v1";
  if (!apiKey) {
    return { ok: false, message: "Meshy API is not configured", retries: 0 };
  }

  const maxAttempts = options?.maxAttempts ?? 3;
  const requestTimeoutMs = options?.requestTimeoutMs ?? 12_000;
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), requestTimeoutMs);
      const response = await fetch(`${apiBase}/image-to-3d`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${apiKey}`,
          "Content-Type": "application/json",
        },
        signal: controller.signal,
        body: JSON.stringify({
          image_url: sourceUrl,
          topology: "quad",
        }),
      });
      clearTimeout(timeoutId);
      if (!response.ok) {
        if (attempt < maxAttempts && response.status >= 500) {
          await _sleep(350 * attempt);
          continue;
        }
        return {
          ok: false,
          message: `Meshy request failed (${response.status})`,
          retries: attempt,
        };
      }

      const data = (await response.json()) as Record<string, unknown>;
      const previewUrl =
        data["thumbnail_url"]?.toString() ||
        data["preview_url"]?.toString() ||
        data["image_url"]?.toString() ||
        "";
      if (previewUrl.length === 0) {
        if (attempt < maxAttempts) {
          await _sleep(350 * attempt);
          continue;
        }
        return {
          ok: false,
          message: "Meshy response missing preview URL",
          retries: attempt,
        };
      }
      return { ok: true, previewUrl, retries: attempt };
    } catch {
      if (attempt < maxAttempts) {
        await _sleep(350 * attempt);
        continue;
      }
      return {
        ok: false,
        message: "Meshy request failed after retries",
        retries: attempt,
      };
    }
  }
  return { ok: false, message: "Meshy request failed", retries: maxAttempts };
}

async function _composeRenderTextureSource(
  env: Env,
  row: DesignRenderJobRow,
  normalized: ReturnType<typeof normalizeRenderMetadata>,
) {
  const sourceImage = normalized.overlay.printImageUrl?.trim() ?? "";
  if (sourceImage.length === 0) return "";
  const key = `render-jobs/${row.user_id}/${row.id}/texture-input.json`;
  const payload = {
    sourceImageUrl: sourceImage,
    templateId: normalized.templateId,
    materialPreset: normalized.materialPreset,
    cameraPreset: normalized.cameraPreset,
    palette: normalized.palette,
    printTransform: {
      placement: normalized.overlay.placement,
      x: normalized.overlay.x,
      y: normalized.overlay.y,
      scale: normalized.overlay.scale,
    },
    textLayers: normalized.overlay.textLayers,
    composedAt: new Date().toISOString(),
  };
  await env.R2.put(key, JSON.stringify(payload), {
    httpMetadata: { contentType: "application/json" },
  });
  // Fast path: we still render from source image URL, but we persist normalized
  // composition metadata in R2 for deterministic reproducibility.
  return sourceImage;
}

async function _persistRenderArtifacts(
  env: Env,
  row: DesignRenderJobRow,
  previewUrl: string,
  normalized: ReturnType<typeof normalizeRenderMetadata>,
) {
  const copiedPreview = await _copyExternalImageToR2(
    env,
    previewUrl,
    `render-jobs/${row.user_id}/${row.id}/hero-front.jpg`,
  );
  const base = copiedPreview ?? previewUrl;
  const artifacts = {
    thumbnailUrl: base,
    heroFrontUrl: base,
    heroSideUrl: base,
    heroBackUrl: base,
    templateId: normalized.templateId,
    materialPreset: normalized.materialPreset,
  };
  return artifacts;
}

async function _copyExternalImageToR2(
  env: Env,
  sourceUrl: string,
  key: string,
): Promise<string | null> {
  try {
    const response = await fetch(sourceUrl);
    if (!response.ok) return null;
    const body = await response.arrayBuffer();
    await env.R2.put(key, body, {
      httpMetadata: { contentType: response.headers.get("content-type") ?? "image/jpeg" },
    });
    return `${env.CLOUDFLARE_R2_BASE_URL}/${key}`;
  } catch {
    return null;
  }
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

function _sleep(ms: number) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
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
