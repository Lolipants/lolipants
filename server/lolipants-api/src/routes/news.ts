import { Hono } from "hono";
import { apiError } from "../lib/http";
import { requireAuth } from "../middleware/auth";
import type { AppVariables, Env } from "../types";

export const newsRoutes = new Hono<{ Bindings: Env; Variables: AppVariables }>();
newsRoutes.use("*", requireAuth);

const DEFAULT_PAGE_SIZE = 20;

type NewsRow = {
  id: string;
  title_en: string;
  title_ar: string;
  summary_en: string;
  summary_ar: string;
  body_en: string;
  body_ar: string;
  cover_image_url: string | null;
  is_published: number;
  is_featured: number;
  published_at: string | null;
  author_id: string;
  created_at: string;
  updated_at: string;
  author_name?: string | null;
};

function resolveLang(c: { req: { query: (k: string) => string | undefined; header: (k: string) => string | undefined } }): "en" | "ar" {
  const q = c.req.query("lang")?.trim().toLowerCase();
  if (q === "ar") return "ar";
  const accept = c.req.header("Accept-Language")?.toLowerCase() ?? "";
  if (accept.includes("ar")) return "ar";
  return "en";
}

function shapePublicArticle(row: NewsRow, lang: "en" | "ar") {
  const isAr = lang === "ar";
  return {
    id: row.id,
    title: isAr ? row.title_ar : row.title_en,
    summary: isAr ? row.summary_ar : row.summary_en,
    body: isAr ? row.body_ar : row.body_en,
    coverImageUrl: row.cover_image_url ?? null,
    isFeatured: Boolean(row.is_featured),
    publishedAt: row.published_at,
    authorId: row.author_id,
    authorName: row.author_name ?? "Lolipants",
  };
}

newsRoutes.get("/", async (c) => {
  const lang = resolveLang(c);
  const cursor = c.req.query("cursor")?.trim();
  const pageSize = Math.min(
    Math.max(Number(c.req.query("pageSize") ?? DEFAULT_PAGE_SIZE) || DEFAULT_PAGE_SIZE, 1),
    50,
  );

  const featuredRow = await c.env.DB.prepare(
    `SELECT n.*, u.name AS author_name
     FROM fashion_news n
     LEFT JOIN users u ON u.id = n.author_id
     WHERE n.is_published = 1 AND n.is_featured = 1
     ORDER BY n.published_at DESC
     LIMIT 1`,
  ).first<NewsRow>();

  const wheres = ["n.is_published = 1"];
  const binds: unknown[] = [];
  if (featuredRow) {
    wheres.push("n.id != ?");
    binds.push(featuredRow.id);
  }
  if (cursor) {
    wheres.push("n.published_at < ?");
    binds.push(cursor);
  }
  const whereSql = `WHERE ${wheres.join(" AND ")}`;

  const { results } = await c.env.DB.prepare(
    `SELECT n.*, u.name AS author_name
     FROM fashion_news n
     LEFT JOIN users u ON u.id = n.author_id
     ${whereSql}
     ORDER BY n.published_at DESC
     LIMIT ?`,
  )
    .bind(...binds, pageSize + 1)
    .all<NewsRow>();

  const rows = results ?? [];
  const hasMore = rows.length > pageSize;
  const page = hasMore ? rows.slice(0, pageSize) : rows;
  const nextCursor =
    hasMore && page.length > 0 ? page[page.length - 1]?.published_at ?? null : null;

  return c.json({
    featured: featuredRow ? shapePublicArticle(featuredRow, lang) : null,
    articles: page.map((row) => shapePublicArticle(row, lang)),
    nextCursor,
  });
});

newsRoutes.get("/:id", async (c) => {
  const id = c.req.param("id");
  const lang = resolveLang(c);
  const row = await c.env.DB.prepare(
    `SELECT n.*, u.name AS author_name
     FROM fashion_news n
     LEFT JOIN users u ON u.id = n.author_id
     WHERE n.id = ? AND n.is_published = 1`,
  )
    .bind(id)
    .first<NewsRow>();

  if (!row) {
    return apiError(c, 404, "NOT_FOUND", "News article not found");
  }
  return c.json(shapePublicArticle(row, lang));
});
