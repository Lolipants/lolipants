/**
 * Thin REST adapter for Gemini native image generation ("Nano Banana" models).
 * https://ai.google.dev/gemini-api/docs/image-generation
 */

const GEMINI_GENERATE_BASE = "https://generativelanguage.googleapis.com/v1beta/models";

export type GeminiInlinePart = { mimeType: string; base64: string; caption?: string };

export type GarmentLookPromptInput = {
  garmentType: string;
  primaryColour: string;
  accentColour: string;
  fabricQuality: string;
  printPlacement?: string | null;
  textLayersSummary?: string | null;
  /** Optional client free-text (editor AI bar). */
  userExtra?: string | null;
  /** Modular configurator summary (slot picks). */
  configuratorSummary?: string | null;
  /** Explicit sleeve vs overlay semantics for AI (from client configurator). */
  configuratorAiLayerNotes?: string | null;
  /** Consistent catalogue / brand suffix. */
  brandSuffix?: string | null;
  /** When true, prompt targets refining the attached preview (not a new photoshoot). */
  hasDesignPreviewReference?: boolean;
};

/** Server default when client omits `aiLookPromptSuffix` in render metadata. */
export const DEFAULT_LOLIPANTS_LOOK_SUFFIX =
  "Lolipants refine rules: pure solid white background (#FFFFFF). " +
  "Keep the EXACT same mannequin, pose, proportions, framing, colours, panels, trim, and slot layout as the primary design-preview reference — do not swap the model or redesign the garment. " +
  "Only refine layered configurator graphics into ONE unified photorealistic sewn garment (natural fabric drape, subtle stitching, cohesive material). " +
  "No studio set, scenery, props, watermarks, or readable text/logos. SynthID from the API is acceptable.";

export const COMPOSE_PREVIEW_REF_CAPTION =
  "PRIMARY design preview — refine this image. Keep the exact same mannequin, pose, scale, colours, and garment layout. " +
  "Output on pure white background (#FFFFFF). Merge layered pieces into one realistic garment.";

export function buildGarmentLookPrompt(input: GarmentLookPromptInput): string {
  const textExtra =
    input.textLayersSummary != null && input.textLayersSummary.trim().length > 0
      ? `\nEmbroidery / text on garment (preserve placement): ${input.textLayersSummary.trim()}`
      : "";
  const placement = input.printPlacement?.trim() || "chest";

  const userBlock =
    input.userExtra != null && input.userExtra.trim().length > 0
      ? `\n\nSubtle refinement only (do not redesign):\n${input.userExtra.trim()}`
      : "";
  const configuratorBlock =
    input.configuratorSummary != null && input.configuratorSummary.trim().length > 0
      ? `\n\nModular design (slot selections — preserve exactly):\n${input.configuratorSummary.trim()}`
      : "";
  const aiLayerNotesBlock =
    input.configuratorAiLayerNotes != null &&
    input.configuratorAiLayerNotes.trim().length > 0
      ? `\n\nLayer semantics (follow strictly — do not confuse overlays with sleeves):\n${input.configuratorAiLayerNotes.trim()}`
      : "";
  const suffixBlock =
    input.brandSuffix != null && input.brandSuffix.trim().length > 0
      ? `\n\n${input.brandSuffix.trim()}`
      : "";

  if (input.hasDesignPreviewReference) {
    return (
      [
        "Edit and refine the attached design preview image. This is a REFINE task — not a new photoshoot.",
        "Background: pure solid white (#FFFFFF). No gradients, scenery, or studio props.",
        "Mannequin: keep IDENTICAL — same silhouette, pose, proportions, and camera framing as the preview.",
        "Garment design: preserve EXACT colours, cut lines, panels, trim placement, prints, and slot selections from the preview.",
        "Refinement goal: turn stacked/layered configurator graphics into ONE cohesive, photorealistic sewn garment with natural fabric drape.",
        "Do NOT invent new garment parts, change the colour palette, or replace the mannequin.",
        "Do NOT misread chest/overlay panels as sleeves — overlay graphics stay on the front torso only.",
        "",
        `Garment type (reference): ${input.garmentType}`,
        `Primary fabric colour: ${input.primaryColour}`,
        `Accent / trim colour: ${input.accentColour}`,
        `Fabric quality tier: ${input.fabricQuality}`,
        textExtra,
      ].join("\n") +
      configuratorBlock +
      aiLayerNotesBlock +
      userBlock +
      suffixBlock
    );
  }

  return (
    [
      "Generate exactly ONE refined fashion preview on a pure white background (#FFFFFF).",
      "One modest mannequin or model wearing the described custom garment, full-length, catalogue clarity.",
      "",
      `Garment type: ${input.garmentType}`,
      `Primary fabric colour (approximate hex reference): ${input.primaryColour}`,
      `Accent / trim colour: ${input.accentColour}`,
      `Fabric quality tier: ${input.fabricQuality}`,
      `Integrate the user's print artwork from the supplied reference image onto the garment (${placement} placement unless the sketch suggests otherwise).`,
      textExtra,
      "",
      "If reference images are provided: honor the mannequin/body reference for pose; honor the garment reference for colours and layout.",
      "Output must be modest formalwear appropriate for Gulf / Middle Eastern contexts.",
    ].join("\n") +
    configuratorBlock +
    aiLayerNotesBlock +
    userBlock +
    suffixBlock
  );
}

/** Fetch a remote image URL and return base64 + mime type for Gemini inline_data. */
export async function fetchUrlAsInlinePart(
  url: string,
  fetchFn: typeof fetch,
  maxBytes: number,
): Promise<GeminiInlinePart | null> {
  const trimmed = url.trim();
  if (!trimmed.startsWith("http://") && !trimmed.startsWith("https://")) {
    return null;
  }
  const res = await fetchFn(trimmed, { redirect: "follow" });
  if (!res.ok) {
    console.warn(
      JSON.stringify({
        event: "gemini_ref_fetch_failed",
        status: res.status,
        url: trimmed.slice(0, 120),
      }),
    );
    return null;
  }
  const buf = new Uint8Array(await res.arrayBuffer());
  if (buf.byteLength === 0 || buf.byteLength > maxBytes) {
    console.warn(JSON.stringify({ event: "gemini_ref_size_skip", bytes: buf.byteLength }));
    return null;
  }
  const mimeType =
    res.headers.get("content-type")?.split(";")[0]?.trim() ||
    sniffImageMime(buf) ||
    "image/png";
  let binary = "";
  for (let i = 0; i < buf.length; i++) binary += String.fromCharCode(buf[i]!);
  const base64 = btoa(binary);
  return { mimeType, base64 };
}

function sniffImageMime(bytes: Uint8Array): string | null {
  if (bytes.length >= 3 && bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff) {
    return "image/jpeg";
  }
  if (
    bytes.length >= 8 &&
    bytes[0] === 0x89 &&
    bytes[1] === 0x50 &&
    bytes[2] === 0x4e &&
    bytes[3] === 0x47
  ) {
    return "image/png";
  }
  if (bytes.length >= 12 && bytes[0] === 0x52 && bytes[1] === 0x49 && bytes[2] === 0x46 && bytes[3] === 0x46) {
    return "image/webp";
  }
  return null;
}

export type GeminiGenerateResult =
  | { ok: true; mimeType: string; bytes: Uint8Array }
  | { ok: false; error: string };

export async function generateGarmentLookImage(input: {
  apiKey: string;
  model: string;
  prompt: string;
  referenceParts: GeminiInlinePart[];
  fetchFn?: typeof fetch;
}): Promise<GeminiGenerateResult> {
  const fetchFn = input.fetchFn ?? fetch;
  const parts: Record<string, unknown>[] = [{ text: input.prompt }];
  for (const ref of input.referenceParts.slice(0, 3)) {
    const label = ref.caption?.trim();
    if (label) parts.push({ text: label });
    parts.push({
      inline_data: {
        mime_type: ref.mimeType,
        data: ref.base64,
      },
    });
  }

  const url = `${GEMINI_GENERATE_BASE}/${encodeURIComponent(input.model)}:generateContent`;

  console.log(
    JSON.stringify({
      event: "gemini_image_prompt",
      model: input.model,
      referenceCount: Math.min(input.referenceParts.length, 3),
      prompt: input.prompt,
    }),
  );

  const res = await fetchFn(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-goog-api-key": input.apiKey,
    },
    body: JSON.stringify({
      contents: [{ role: "user", parts }],
      generationConfig: {
        responseModalities: ["TEXT", "IMAGE"],
      },
    }),
  });

  if (!res.ok) {
    const errText = await res.text().catch(() => "");
    return {
      ok: false,
      error: `Gemini HTTP ${res.status}: ${errText.slice(0, 400)}`,
    };
  }

  const data = (await res.json()) as Record<string, unknown>;
  const extracted = extractInlineImageFromGeminiResponse(data);
  if (!extracted) {
    return { ok: false, error: "Gemini returned no image inline_data" };
  }

  try {
    const bytes = base64ToBytes(extracted.base64);
    return { ok: true, mimeType: extracted.mimeType, bytes };
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    return { ok: false, error: `Gemini image decode failed: ${msg}` };
  }
}

export function extractInlineImageFromGeminiResponse(data: Record<string, unknown>): {
  mimeType: string;
  base64: string;
} | null {
  const candidates = data["candidates"];
  if (!Array.isArray(candidates) || candidates.length === 0) return null;
  const first = candidates[0] as Record<string, unknown>;
  const content = first["content"] as Record<string, unknown> | undefined;
  const partsRaw = content?.["parts"];
  if (!Array.isArray(partsRaw)) return null;

  for (const p of partsRaw) {
    if (typeof p !== "object" || p === null) continue;
    const part = p as Record<string, unknown>;
    const inline =
      (part["inline_data"] as Record<string, unknown> | undefined) ??
      (part["inlineData"] as Record<string, unknown> | undefined);
    if (!inline) continue;
    const mime =
      (inline["mime_type"] as string | undefined) ??
      (inline["mimeType"] as string | undefined) ??
      "image/png";
    const b64 = inline["data"];
    if (typeof b64 === "string" && b64.length > 0 && mime.startsWith("image/")) {
      return { mimeType: mime, base64: b64 };
    }
  }
  return null;
}

function base64ToBytes(b64: string): Uint8Array {
  const binary = atob(b64);
  const out = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) out[i] = binary.charCodeAt(i);
  return out;
}

export function inlinePartToBytes(part: GeminiInlinePart): Uint8Array {
  return base64ToBytes(part.base64);
}
