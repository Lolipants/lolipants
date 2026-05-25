type PreviewRow = {
  print_image_url?: string | null;
  sketch_image_url?: string | null;
  render_metadata?: string | null;
};

const RENDER_META_PREVIEW_KEYS = [
  "configuratorComposeImageUrl",
  "aiRefinedLookUrl",
  "catalogFlatImageUrl",
] as const;

function previewFromRenderMetadata(raw: string | null | undefined): string | null {
  const trimmed = raw?.trim();
  if (!trimmed) return null;
  try {
    const meta = JSON.parse(trimmed) as Record<string, unknown>;
    for (const key of RENDER_META_PREVIEW_KEYS) {
      const v = meta[key]?.toString().trim();
      if (v) return v;
    }
  } catch {
    return null;
  }
  return null;
}

/** Best preview URL for feed cards and showcase thumbnails. */
export function designPreviewImageUrl(row: PreviewRow): string | null {
  const print = row.print_image_url?.trim();
  if (print) return print;
  const sketch = row.sketch_image_url?.trim();
  if (sketch) return sketch;
  return previewFromRenderMetadata(row.render_metadata);
}

/** Returns true when the design has a renderable preview for showcase publish. */
export function designHasRenderablePreview(row: PreviewRow): boolean {
  return designPreviewImageUrl(row) != null;
}
