import { Hono } from "hono";
import type { Env } from "../types";

type TemplateRow = {
  id: string;
  name_en: string;
  name_ar: string;
  garment_type: string;
  region_tag: string;
  sort_order: number;
  required_slot_keys: string | null;
};

type SlotRow = {
  id: string;
  template_id: string;
  slot_key: string;
  title_en: string;
  title_ar: string;
  sort_order: number;
};

type OptionRow = {
  id: string;
  slot_id: string;
  option_key: string;
  label_en: string;
  label_ar: string;
  asset_url: string | null;
  metadata_json: string | null;
  sort_order: number;
};

function parseJsonArray(raw: string | null): string[] {
  if (!raw?.trim()) return [];
  try {
    const v = JSON.parse(raw) as unknown;
    if (!Array.isArray(v)) return [];
    return v.map((x) => String(x).trim()).filter((s) => s.length > 0);
  } catch {
    return [];
  }
}

function parseMetadata(raw: string | null): Record<string, unknown> {
  if (!raw?.trim()) return {};
  try {
    const v = JSON.parse(raw) as unknown;
    return v && typeof v === "object" && !Array.isArray(v)
      ? (v as Record<string, unknown>)
      : {};
  } catch {
    return {};
  }
}

export const configuratorRoutes = new Hono<{ Bindings: Env }>();

/** Nested templates → slots → options for the editor Build tab. */
configuratorRoutes.get("/templates", async (c) => {
  const { results: templates } = await c.env.DB.prepare(
    `SELECT id, name_en, name_ar, garment_type, region_tag, sort_order, required_slot_keys
     FROM configurator_templates
     WHERE is_active = 1
     ORDER BY sort_order ASC, name_en ASC`,
  ).all<TemplateRow>();

  const { results: slots } = await c.env.DB.prepare(
    `SELECT s.id, s.template_id, s.slot_key, s.title_en, s.title_ar, s.sort_order
     FROM configurator_slots s
     INNER JOIN configurator_templates t ON t.id = s.template_id
     WHERE s.is_active = 1 AND t.is_active = 1
     ORDER BY s.sort_order ASC, s.title_en ASC`,
  ).all<SlotRow>();

  const { results: options } = await c.env.DB.prepare(
    `SELECT o.id, o.slot_id, o.option_key, o.label_en, o.label_ar, o.asset_url, o.metadata_json, o.sort_order
     FROM configurator_options o
     INNER JOIN configurator_slots s ON s.id = o.slot_id
     INNER JOIN configurator_templates t ON t.id = s.template_id
     WHERE o.is_active = 1 AND s.is_active = 1 AND t.is_active = 1
     ORDER BY o.sort_order ASC, o.label_en ASC`,
  ).all<OptionRow>();

  const optionsBySlot = new Map<string, OptionRow[]>();
  for (const opt of options ?? []) {
    const list = optionsBySlot.get(opt.slot_id) ?? [];
    list.push(opt);
    optionsBySlot.set(opt.slot_id, list);
  }

  const slotsByTemplate = new Map<string, Array<Record<string, unknown>>>();
  for (const slot of slots ?? []) {
    const slotOptions = (optionsBySlot.get(slot.id) ?? []).map((o) => ({
      id: o.id,
      optionKey: o.option_key,
      labelEn: o.label_en,
      labelAr: o.label_ar,
      assetUrl: o.asset_url,
      metadata: parseMetadata(o.metadata_json),
      sortOrder: o.sort_order,
    }));
    const entry = {
      id: slot.id,
      slotKey: slot.slot_key,
      titleEn: slot.title_en,
      titleAr: slot.title_ar,
      sortOrder: slot.sort_order,
      options: slotOptions,
    };
    const list = slotsByTemplate.get(slot.template_id) ?? [];
    list.push(entry);
    slotsByTemplate.set(slot.template_id, list);
  }

  const payload = (templates ?? []).map((t) => ({
    id: t.id,
    nameEn: t.name_en,
    nameAr: t.name_ar,
    garmentType: t.garment_type,
    regionTag: t.region_tag,
    sortOrder: t.sort_order,
    requiredSlotKeys: parseJsonArray(t.required_slot_keys),
    slots: slotsByTemplate.get(t.id) ?? [],
  }));

  return c.json(payload);
});
