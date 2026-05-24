import { Hono } from "hono";
import type { AppVariables, Env } from "../types";

export const catalogRoutes = new Hono<{ Bindings: Env; Variables: AppVariables }>();

type DesignCatalogRow = {
  id: string;
  section_title: string;
  label_en: string;
  label_ar: string;
  image_url: string;
  garment_type: string | null;
  gender_lane: string | null;
  sort_order: number | null;
};

catalogRoutes.get("/designs", async (c) => {
  const { results } = await c.env.DB.prepare(
    `SELECT id, section_title, label_en, label_ar, image_url, garment_type, gender_lane, sort_order
     FROM design_catalog_items
     WHERE is_active = 1
     ORDER BY section_title ASC, sort_order ASC, label_en ASC`,
  ).all<DesignCatalogRow>();

  const bySection = new Map<string, DesignCatalogRow[]>();
  for (const row of results ?? []) {
    const title = row.section_title?.trim() || "Catalog";
    const bucket = bySection.get(title) ?? [];
    bucket.push(row);
    bySection.set(title, bucket);
  }

  const sections = [...bySection.entries()].map(([sectionTitle, items]) => ({
    sectionTitle,
    items: items.map((item) => ({
      id: item.id,
      labelEn: item.label_en,
      labelAr: item.label_ar,
      imageUrl: item.image_url,
      garmentType: item.garment_type,
      genderLane: item.gender_lane,
      sortOrder: item.sort_order ?? 0,
    })),
  }));

  return c.json({ sections });
});
