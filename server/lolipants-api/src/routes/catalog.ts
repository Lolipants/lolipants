import { Hono } from "hono";
import { requireAuth } from "../middleware/auth";
import type { AppVariables, Env } from "../types";

export const catalogRoutes = new Hono<{ Bindings: Env; Variables: AppVariables }>();

const VALID_GENDER_LANES = new Set(["men", "women", "kids"]);

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

/** Featured editor flat-lays for home — filtered by `users.gender` in D1. */
catalogRoutes.get("/designs/featured", requireAuth, async (c) => {
  const userId = c.get("userId") as string;
  let gender: string | null = null;
  try {
    const row = await c.env.DB.prepare("SELECT gender FROM users WHERE id = ?")
      .bind(userId)
      .first<{ gender: string | null }>();
    gender = row?.gender?.trim().toLowerCase() || null;
  } catch {
    gender = null;
  }

  const lane =
    gender === "kids"
      ? "women"
      : gender && VALID_GENDER_LANES.has(gender)
        ? gender
        : "women";

  const { results } = await c.env.DB.prepare(
    `SELECT id, section_title, label_en, label_ar, image_url, garment_type, gender_lane, sort_order
     FROM design_catalog_items
     WHERE is_active = 1
       AND (
         gender_lane = ?
         OR gender_lane IS NULL
         OR TRIM(gender_lane) = ''
       )
     ORDER BY sort_order ASC, label_en ASC
     LIMIT 32`,
  )
    .bind(lane)
    .all<DesignCatalogRow>();

  const items = (results ?? []).filter((row) => {
    const explicit = row.gender_lane?.trim().toLowerCase();
    if (explicit && explicit !== lane) return false;
    return true;
  });

  return c.json({
    gender: gender,
    lane,
    items: items.map((item) => ({
      id: item.id,
      labelEn: item.label_en,
      labelAr: item.label_ar,
      imageUrl: item.image_url,
      garmentType: item.garment_type,
      genderLane: item.gender_lane,
      sortOrder: item.sort_order ?? 0,
    })),
  });
});
