export type RenderTemplateId =
  | "male_thobe_v1"
  | "female_abaya_v1"
  | "unisex_bisht_v1"
  | "default_thobe_v1";

export type RenderMetadata = {
  mannequinTemplateId: string;
  fabricProfile: string;
  printTransform: {
    placement: string;
    x: number;
    y: number;
    scale: number;
  };
  textLayers: Array<{
    text: string;
    fontFamily?: string;
    fontSize?: number;
    colour?: string;
    x?: number;
    y?: number;
    rotation?: number;
  }>;
  primaryColour?: string;
  accentColour?: string;
  garmentType?: string;
  printImageUrl?: string | null;
};

export type NormalizedRenderInput = {
  templateId: RenderTemplateId;
  materialPreset: "matte" | "satin" | "standard";
  cameraPreset: {
    frontYawDeg: number;
    sideYawDeg: number;
    backYawDeg: number;
  };
  overlay: {
    printImageUrl: string | null;
    placement: "chest" | "back" | "fullFront";
    x: number;
    y: number;
    scale: number;
    textLayers: RenderMetadata["textLayers"];
  };
  palette: {
    primaryColour: string;
    accentColour: string;
  };
};

function clamp(n: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, n));
}

function parseJsonRecord(value: string | null): Record<string, unknown> {
  if (!value) return {};
  try {
    const parsed = JSON.parse(value) as Record<string, unknown>;
    return parsed ?? {};
  } catch {
    return {};
  }
}

export function normalizeRenderMetadata(input: {
  garmentType?: string | null;
  mannequinId?: string | null;
  primaryColour?: string | null;
  accentColour?: string | null;
  printImageUrl?: string | null;
  renderMetadataRaw?: string | null;
}): NormalizedRenderInput {
  const metadata = parseJsonRecord(input.renderMetadataRaw);
  const garmentType = (
    metadata["garmentType"]?.toString() ??
    input.garmentType?.toString() ??
    "thobe"
  )
    .trim()
    .toLowerCase();
  const mannequinId = (input.mannequinId ?? "").toLowerCase();
  const templateHint = metadata["mannequinTemplateId"]?.toString().trim().toLowerCase();
  const templateId = resolveTemplateId({ garmentType, mannequinId, templateHint });

  const profile = (metadata["fabricProfile"]?.toString() ?? "standard").toLowerCase();
  const materialPreset = resolveMaterialPreset(profile);

  const printTransformRaw =
    (metadata["printTransform"] as Record<string, unknown> | undefined) ?? {};
  const placement = resolvePlacement(printTransformRaw["placement"]?.toString());
  const x = clamp(Number(printTransformRaw["x"] ?? 0), -100, 100);
  const y = clamp(Number(printTransformRaw["y"] ?? 0), -120, 120);
  const scale = clamp(Number(printTransformRaw["scale"] ?? 40), 10, 120);

  const textLayersRaw = Array.isArray(metadata["textLayers"])
    ? metadata["textLayers"]
    : [];
  const textLayers = textLayersRaw
    .filter((value): value is Record<string, unknown> => typeof value === "object" && value != null)
    .map((layer) => ({
      text: layer["text"]?.toString() ?? "",
      fontFamily: layer["fontFamily"]?.toString(),
      fontSize: Number(layer["fontSize"] ?? 16),
      colour: layer["colour"]?.toString(),
      x: Number(layer["x"] ?? 0.5),
      y: Number(layer["y"] ?? 0.5),
      rotation: Number(layer["rotation"] ?? 0),
    }))
    .filter((layer) => layer.text.trim().length > 0);

  const printImageUrl =
    metadata["printImageUrl"]?.toString() ?? input.printImageUrl ?? null;

  const primaryColour =
    metadata["primaryColour"]?.toString() ??
    input.primaryColour?.toString() ??
    "#162F28";
  const accentColour =
    metadata["accentColour"]?.toString() ??
    input.accentColour?.toString() ??
    "#C9A84C";

  return {
    templateId,
    materialPreset,
    cameraPreset: resolveCameraPreset(templateId),
    overlay: {
      printImageUrl,
      placement,
      x,
      y,
      scale,
      textLayers,
    },
    palette: {
      primaryColour,
      accentColour,
    },
  };
}

function resolveTemplateId(input: {
  garmentType: string;
  mannequinId: string;
  templateHint: string | undefined;
}): RenderTemplateId {
  if (input.templateHint === "male_thobe_v1") return "male_thobe_v1";
  if (input.templateHint === "female_abaya_v1") return "female_abaya_v1";
  if (input.templateHint === "unisex_bisht_v1") return "unisex_bisht_v1";
  if (input.garmentType === "abaya") return "female_abaya_v1";
  if (input.garmentType === "bisht") return "unisex_bisht_v1";
  if (input.mannequinId.includes("female")) return "female_abaya_v1";
  if (input.mannequinId.includes("male")) return "male_thobe_v1";
  return "default_thobe_v1";
}

function resolveMaterialPreset(profile: string): "matte" | "satin" | "standard" {
  if (profile.includes("premium") || profile.includes("luxury")) return "satin";
  if (profile.includes("matte")) return "matte";
  return "standard";
}

function resolvePlacement(value: string | undefined): "chest" | "back" | "fullFront" {
  if (value === "back") return "back";
  if (value === "fullFront") return "fullFront";
  return "chest";
}

function resolveCameraPreset(templateId: RenderTemplateId): {
  frontYawDeg: number;
  sideYawDeg: number;
  backYawDeg: number;
} {
  if (templateId === "unisex_bisht_v1") {
    return { frontYawDeg: 0, sideYawDeg: 35, backYawDeg: 180 };
  }
  if (templateId === "female_abaya_v1") {
    return { frontYawDeg: 0, sideYawDeg: 30, backYawDeg: 180 };
  }
  return { frontYawDeg: 0, sideYawDeg: 28, backYawDeg: 180 };
}
