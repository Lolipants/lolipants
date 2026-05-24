/**
 * OpenAI Images API fallback when Gemini native image generation is unavailable.
 * Uses /images/edits when a design preview reference exists, else /images/generations.
 */

const OPENAI_GENERATIONS_URL = "https://api.openai.com/v1/images/generations";
const OPENAI_EDITS_URL = "https://api.openai.com/v1/images/edits";

/** gpt-image-1 is the current OpenAI image model (dall-e-3 is deprecated on many accounts). */
export const DEFAULT_OPENAI_IMAGE_MODEL = "gpt-image-1";

export type OpenAiImageGenerateResult =
  | { ok: true; mimeType: string; bytes: Uint8Array }
  | { ok: false; error: string };

function portraitSizeForModel(model: string): string {
  if (model === "dall-e-3") return "1024x1792";
  if (model.startsWith("dall-e-")) return "1024x1024";
  return "1024x1536";
}

function parseOpenAiImageResponse(data: {
  data?: Array<{ b64_json?: string; url?: string }>;
}): OpenAiImageGenerateResult {
  const first = data.data?.[0];
  if (!first) {
    return { ok: false, error: "OpenAI returned no image data" };
  }
  if (typeof first.b64_json === "string" && first.b64_json.length > 0) {
    try {
      const bytes = base64ToBytes(first.b64_json);
      return { ok: true, mimeType: "image/png", bytes };
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      return { ok: false, error: `OpenAI image decode failed: ${msg}` };
    }
  }
  return { ok: false, error: "OpenAI returned no b64_json" };
}

/** Refine an existing design preview (preferred when compose PNG is available). */
export async function generateGarmentLookImageEditOpenAI(input: {
  apiKey: string;
  model?: string;
  prompt: string;
  imageBytes: Uint8Array;
  mimeType: string;
  fetchFn?: typeof fetch;
}): Promise<OpenAiImageGenerateResult> {
  const fetchFn = input.fetchFn ?? fetch;
  const model =
    input.model?.trim() && input.model.trim().length > 0
      ? input.model.trim()
      : DEFAULT_OPENAI_IMAGE_MODEL;

  const prompt = input.prompt.trim().slice(0, 3900);
  const size = portraitSizeForModel(model);
  const ext =
    input.mimeType.includes("jpeg") || input.mimeType.includes("jpg") ? "jpg" : "png";

  console.log(
    JSON.stringify({
      event: "openai_image_edit_prompt",
      model,
      size,
      promptLength: prompt.length,
      inputBytes: input.imageBytes.byteLength,
    }),
  );

  const form = new FormData();
  form.append("model", model);
  form.append("prompt", prompt);
  form.append("size", size);
  form.append(
    "image",
    new Blob([input.imageBytes], { type: input.mimeType }),
    `preview.${ext}`,
  );

  const res = await fetchFn(OPENAI_EDITS_URL, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${input.apiKey}`,
    },
    body: form,
  });

  if (!res.ok) {
    const errText = await res.text().catch(() => "");
    return {
      ok: false,
      error: `OpenAI edit HTTP ${res.status}: ${errText.slice(0, 400)}`,
    };
  }

  return parseOpenAiImageResponse((await res.json()) as {
    data?: Array<{ b64_json?: string; url?: string }>;
  });
}

export async function generateGarmentLookImageOpenAI(input: {
  apiKey: string;
  model?: string;
  prompt: string;
  fetchFn?: typeof fetch;
}): Promise<OpenAiImageGenerateResult> {
  const fetchFn = input.fetchFn ?? fetch;
  const model =
    input.model?.trim() && input.model.trim().length > 0
      ? input.model.trim()
      : DEFAULT_OPENAI_IMAGE_MODEL;

  const prompt = input.prompt.trim().slice(0, 3900);
  const size = portraitSizeForModel(model);

  console.log(
    JSON.stringify({
      event: "openai_image_prompt",
      model,
      size,
      promptLength: prompt.length,
    }),
  );

  const body: Record<string, unknown> = {
    model,
    prompt,
    n: 1,
    size,
  };
  if (model === "dall-e-3") {
    body.quality = "standard";
  } else if (model === "dall-e-2") {
    body.response_format = "b64_json";
  }

  const res = await fetchFn(OPENAI_GENERATIONS_URL, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${input.apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    const errText = await res.text().catch(() => "");
    return {
      ok: false,
      error: `OpenAI HTTP ${res.status}: ${errText.slice(0, 400)}`,
    };
  }

  const data = (await res.json()) as {
    data?: Array<{ b64_json?: string; url?: string }>;
  };
  const parsed = parseOpenAiImageResponse(data);
  if (!parsed.ok) return parsed;

  const first = data.data?.[0];
  if (typeof first?.url === "string" && first.url.startsWith("http")) {
    const imgRes = await fetchFn(first.url, { redirect: "follow" });
    if (!imgRes.ok) {
      return { ok: false, error: `OpenAI image download HTTP ${imgRes.status}` };
    }
    const buf = new Uint8Array(await imgRes.arrayBuffer());
    if (buf.byteLength === 0) {
      return { ok: false, error: "OpenAI image download was empty" };
    }
    const mimeType =
      imgRes.headers.get("content-type")?.split(";")[0]?.trim() || "image/png";
    return { ok: true, mimeType, bytes: buf };
  }

  return parsed;
}

function base64ToBytes(b64: string): Uint8Array {
  const binary = atob(b64);
  const out = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) out[i] = binary.charCodeAt(i);
  return out;
}
