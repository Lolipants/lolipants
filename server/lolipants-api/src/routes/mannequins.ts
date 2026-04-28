import { Hono } from "hono";
import { requireAuth } from "../middleware/auth";
import type { AppVariables, Env } from "../types";

export const mannequinRoutes = new Hono<{
  Bindings: Env;
  Variables: AppVariables;
}>();
mannequinRoutes.use("*", requireAuth);

mannequinRoutes.get("/", async (c) => {
  const { results } = await c.env.DB.prepare(
    `SELECT id, label_en, label_ar, preview_url
     FROM mannequin_options
     WHERE is_active = 1
     ORDER BY sort_order ASC, created_at ASC`,
  ).all<{
    id: string;
    label_en: string;
    label_ar: string;
    preview_url?: string | null;
  }>();

  const payload = results.map((row) => ({
    id: row.id,
    labelEn: row.label_en,
    labelAr: row.label_ar,
    previewUrl: row.preview_url ?? null,
  }));
  return c.json(payload);
});
