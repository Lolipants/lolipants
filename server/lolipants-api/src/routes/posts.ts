import { Hono } from "hono";
import { v4 as uuidv4 } from "uuid";
import { requireAuth } from "../middleware/auth";
import type { AppVariables, Env } from "../types";

export const postRoutes = new Hono<{ Bindings: Env; Variables: AppVariables }>();
postRoutes.use("*", requireAuth);

postRoutes.get("/", async (c) => {
  const tag = c.req.query("tag");
  const page = Number(c.req.query("page") ?? "1");
  const pageSize = 20;
  const offset = (Math.max(page, 1) - 1) * pageSize;

  let sql = "SELECT * FROM posts";
  const binds: unknown[] = [];
  if (tag) {
    sql += " WHERE tags LIKE ?";
    binds.push(`%${tag}%`);
  }
  sql += " ORDER BY posted_at DESC LIMIT ? OFFSET ?";
  binds.push(pageSize, offset);

  const { results } = await c.env.DB.prepare(sql).bind(...binds).all();
  return c.json(results);
});

postRoutes.post("/", async (c) => {
  const userId = c.get("userId") as string;
  const body = (await c.req.json()) as Record<string, unknown>;
  const id = uuidv4();

  await c.env.DB.prepare(
    "INSERT INTO posts (id, author_id, body, image_urls, tags) VALUES (?, ?, ?, ?, ?)",
  )
    .bind(
      id,
      userId,
      body.body ?? "",
      JSON.stringify(body.imageUrls ?? []),
      JSON.stringify(body.tags ?? []),
    )
    .run();

  const post = await c.env.DB.prepare("SELECT * FROM posts WHERE id = ?")
    .bind(id)
    .first();
  return c.json(post, 201);
});
