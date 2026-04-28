import { Hono } from "hono";
import { v4 as uuidv4 } from "uuid";
import { apiError } from "../lib/http";
import { sendToUser } from "../lib/onesignal";
import { requireAuth } from "../middleware/auth";
import type { AppVariables, Env } from "../types";

export const postRoutes = new Hono<{ Bindings: Env; Variables: AppVariables }>();
postRoutes.use("*", requireAuth);

const VALID_REACTION_TYPES = new Set(["love", "fire", "clap", "wow"]);
const DEFAULT_PAGE_SIZE = 20;
const MAX_BODY_LENGTH = 2000;
const MAX_IMAGES_PER_POST = 4;
const MAX_TAGS_PER_POST = 8;
const MAX_COMMENT_LENGTH = 1000;

function parseJsonList(raw: unknown): string[] {
  if (Array.isArray(raw)) return raw.map((x) => String(x));
  if (typeof raw !== "string" || raw.length === 0) return [];
  try {
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed.map((x) => String(x)) : [];
  } catch {
    return [];
  }
}

type PostRow = {
  id: string;
  author_id: string;
  body: string;
  image_urls: string | null;
  tags: string | null;
  reaction_count: number;
  comment_count: number;
  posted_at: string;
  author_name: string | null;
  author_avatar_url: string | null;
  author_is_pro_designer: number | null;
  my_reaction: string | null;
};

function shapePost(row: PostRow) {
  return {
    id: row.id,
    authorId: row.author_id,
    authorName: row.author_name ?? "Lolipants User",
    authorAvatarUrl: row.author_avatar_url ?? null,
    isVerifiedDesigner: Boolean(row.author_is_pro_designer),
    body: row.body,
    imageUrls: parseJsonList(row.image_urls),
    tags: parseJsonList(row.tags),
    reactionCount: Number(row.reaction_count ?? 0),
    commentCount: Number(row.comment_count ?? 0),
    currentUserReaction: row.my_reaction ?? null,
    currentUserReacted: Boolean(row.my_reaction),
    postedAt: row.posted_at,
  };
}

postRoutes.get("/", async (c) => {
  const viewerId = c.get("userId") as string;
  const tag = c.req.query("tag")?.trim();
  const cursor = c.req.query("cursor")?.trim();
  const pageSize = Math.min(
    Math.max(Number(c.req.query("pageSize") ?? DEFAULT_PAGE_SIZE) || DEFAULT_PAGE_SIZE, 1),
    50,
  );

  const wheres: string[] = [];
  const binds: unknown[] = [];
  if (tag) {
    wheres.push("p.tags LIKE ?");
    binds.push(`%"${tag}"%`);
  }
  if (cursor) {
    wheres.push("p.posted_at < ?");
    binds.push(cursor);
  }
  const whereSql = wheres.length > 0 ? `WHERE ${wheres.join(" AND ")}` : "";

  // Use a JOIN for the viewer's reaction (not a correlated subquery). D1/SQLite
  // can be picky about parameter binding inside subqueries; UNIQUE(post_id,
  // user_id) on post_reactions ensures at most one joined row per post.
  const sql = `
    SELECT p.*, u.name AS author_name, u.avatar_url AS author_avatar_url,
           u.is_pro_designer AS author_is_pro_designer,
           r.reaction_type AS my_reaction
    FROM posts p
    LEFT JOIN users u ON u.id = p.author_id
    LEFT JOIN post_reactions r ON r.post_id = p.id AND r.user_id = ?
    ${whereSql}
    ORDER BY p.posted_at DESC
    LIMIT ?
  `;
  try {
    const { results } = await c.env.DB.prepare(sql)
      .bind(viewerId, ...binds, pageSize + 1)
      .all<PostRow>();

    const rows = (results ?? []) as PostRow[];
    const hasMore = rows.length > pageSize;
    const pageRows = hasMore ? rows.slice(0, pageSize) : rows;
    const nextCursor = hasMore ? pageRows[pageRows.length - 1].posted_at : null;
    return c.json({
      posts: pageRows.map(shapePost),
      nextCursor,
    });
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    console.error("[posts] GET / feed query failed:", message);
    return apiError(c, 500, "FEED_QUERY_FAILED", "Could not load posts");
  }
});

postRoutes.get("/:id", async (c) => {
  const viewerId = c.get("userId") as string;
  const id = c.req.param("id");
  try {
    const row = await c.env.DB.prepare(
      `SELECT p.*, u.name AS author_name, u.avatar_url AS author_avatar_url,
              u.is_pro_designer AS author_is_pro_designer,
              r.reaction_type AS my_reaction
       FROM posts p
       LEFT JOIN users u ON u.id = p.author_id
       LEFT JOIN post_reactions r ON r.post_id = p.id AND r.user_id = ?
       WHERE p.id = ?`,
    )
      .bind(viewerId, id)
      .first<PostRow>();
    if (!row) return apiError(c, 404, "POST_NOT_FOUND", "Post not found");
    return c.json(shapePost(row));
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    console.error("[posts] GET /:id failed:", message);
    return apiError(c, 500, "POST_LOAD_FAILED", "Could not load post");
  }
});

postRoutes.post("/", async (c) => {
  const userId = c.get("userId") as string;
  const body = (await c.req.json()) as Record<string, unknown>;
  const text = String(body.body ?? "").trim();
  if (!text) return apiError(c, 400, "BODY_REQUIRED", "Post body is required");
  if (text.length > MAX_BODY_LENGTH) {
    return apiError(c, 400, "BODY_TOO_LONG", `Post body must be under ${MAX_BODY_LENGTH} chars`);
  }
  const imageUrls = Array.isArray(body.imageUrls)
    ? (body.imageUrls as unknown[]).map((x) => String(x)).slice(0, MAX_IMAGES_PER_POST)
    : [];
  const tags = Array.isArray(body.tags)
    ? (body.tags as unknown[])
        .map((x) => String(x).trim().toLowerCase())
        .filter((t) => t.length > 0)
        .slice(0, MAX_TAGS_PER_POST)
    : [];

  const id = uuidv4();
  await c.env.DB.prepare(
    "INSERT INTO posts (id, author_id, body, image_urls, tags) VALUES (?, ?, ?, ?, ?)",
  )
    .bind(id, userId, text, JSON.stringify(imageUrls), JSON.stringify(tags))
    .run();

  const row = await c.env.DB.prepare(
    `SELECT p.*, u.name AS author_name, u.avatar_url AS author_avatar_url,
            u.is_pro_designer AS author_is_pro_designer,
            NULL AS my_reaction
     FROM posts p LEFT JOIN users u ON u.id = p.author_id
     WHERE p.id = ?`,
  )
    .bind(id)
    .first<PostRow>();

  // Fan-out a push to everyone who follows this author so feeds feel alive.
  try {
    const followers = await c.env.DB.prepare(
      "SELECT follower_id FROM follows WHERE following_id = ? LIMIT 500",
    )
      .bind(userId)
      .all<{ follower_id: string }>();
    const followerIds = (followers.results ?? []).map((r) => r.follower_id);
    if (followerIds.length > 0) {
      const authorName = row?.author_name ?? "A designer";
      await sendToUser({
        env: c.env,
        userIds: followerIds,
        headings: { en: "New post", ar: "منشور جديد" },
        contents: {
          en: `${authorName} just shared a new design`,
          ar: `${authorName} شارك تصميمًا جديدًا`,
        },
        route: `/community/post/${id}`,
      });
    }
  } catch {
    // Push best-effort; never fail post creation on notification errors.
  }
  return c.json(row ? shapePost(row) : { id }, 201);
});

postRoutes.post("/:id/reactions", async (c) => {
  const userId = c.get("userId") as string;
  const postId = c.req.param("id");
  const body = (await c.req.json().catch(() => ({}))) as Record<string, unknown>;
  const type = String(body.type ?? body.reactionType ?? "").trim().toLowerCase();
  if (!VALID_REACTION_TYPES.has(type)) {
    return apiError(c, 400, "INVALID_REACTION_TYPE", "Invalid reaction type");
  }

  const post = await c.env.DB.prepare("SELECT id FROM posts WHERE id = ?")
    .bind(postId)
    .first<{ id: string }>();
  if (!post) return apiError(c, 404, "POST_NOT_FOUND", "Post not found");

  const existing = await c.env.DB.prepare(
    "SELECT id, reaction_type FROM post_reactions WHERE post_id = ? AND user_id = ?",
  )
    .bind(postId, userId)
    .first<{ id: string; reaction_type: string }>();

  let currentReaction: string | null;
  if (!existing) {
    await c.env.DB.prepare(
      "INSERT INTO post_reactions (id, post_id, user_id, reaction_type) VALUES (?, ?, ?, ?)",
    )
      .bind(uuidv4(), postId, userId, type)
      .run();
    currentReaction = type;
  } else if (existing.reaction_type === type) {
    await c.env.DB.prepare("DELETE FROM post_reactions WHERE id = ?")
      .bind(existing.id)
      .run();
    currentReaction = null;
  } else {
    await c.env.DB.prepare(
      "UPDATE post_reactions SET reaction_type = ? WHERE id = ?",
    )
      .bind(type, existing.id)
      .run();
    currentReaction = type;
  }

  await c.env.DB.prepare(
    "UPDATE posts SET reaction_count = (SELECT COUNT(*) FROM post_reactions WHERE post_id = ?) WHERE id = ?",
  )
    .bind(postId, postId)
    .run();

  const total = await c.env.DB.prepare(
    "SELECT reaction_count FROM posts WHERE id = ?",
  )
    .bind(postId)
    .first<{ reaction_count: number }>();

  return c.json({
    postId,
    currentUserReaction: currentReaction,
    reactionCount: Number(total?.reaction_count ?? 0),
  });
});

postRoutes.get("/:id/comments", async (c) => {
  const postId = c.req.param("id");
  const post = await c.env.DB.prepare("SELECT id FROM posts WHERE id = ?")
    .bind(postId)
    .first<{ id: string }>();
  if (!post) return apiError(c, 404, "POST_NOT_FOUND", "Post not found");

  const { results } = await c.env.DB.prepare(
    `SELECT c.id, c.post_id, c.author_id, c.body, c.created_at,
            u.name AS author_name, u.avatar_url AS author_avatar_url,
            u.is_pro_designer AS author_is_pro_designer
     FROM post_comments c
     LEFT JOIN users u ON u.id = c.author_id
     WHERE c.post_id = ?
     ORDER BY c.created_at ASC
     LIMIT 200`,
  )
    .bind(postId)
    .all<{
      id: string;
      post_id: string;
      author_id: string;
      body: string;
      created_at: string;
      author_name: string | null;
      author_avatar_url: string | null;
      author_is_pro_designer: number | null;
    }>();
  return c.json(
    (results ?? []).map((r) => ({
      id: r.id,
      postId: r.post_id,
      authorId: r.author_id,
      authorName: r.author_name ?? "Lolipants User",
      authorAvatarUrl: r.author_avatar_url,
      isVerifiedDesigner: Boolean(r.author_is_pro_designer),
      body: r.body,
      createdAt: r.created_at,
    })),
  );
});

postRoutes.post("/:id/comments", async (c) => {
  const userId = c.get("userId") as string;
  const postId = c.req.param("id");
  const body = (await c.req.json()) as Record<string, unknown>;
  const text = String(body.body ?? "").trim();
  if (!text) return apiError(c, 400, "BODY_REQUIRED", "Comment body is required");
  if (text.length > MAX_COMMENT_LENGTH) {
    return apiError(
      c,
      400,
      "BODY_TOO_LONG",
      `Comment must be under ${MAX_COMMENT_LENGTH} chars`,
    );
  }

  const post = await c.env.DB.prepare("SELECT id FROM posts WHERE id = ?")
    .bind(postId)
    .first<{ id: string }>();
  if (!post) return apiError(c, 404, "POST_NOT_FOUND", "Post not found");

  const id = uuidv4();
  await c.env.DB.prepare(
    "INSERT INTO post_comments (id, post_id, author_id, body) VALUES (?, ?, ?, ?)",
  )
    .bind(id, postId, userId, text)
    .run();
  await c.env.DB.prepare(
    "UPDATE posts SET comment_count = (SELECT COUNT(*) FROM post_comments WHERE post_id = ?) WHERE id = ?",
  )
    .bind(postId, postId)
    .run();

  const created = await c.env.DB.prepare(
    `SELECT c.id, c.post_id, c.author_id, c.body, c.created_at,
            u.name AS author_name, u.avatar_url AS author_avatar_url,
            u.is_pro_designer AS author_is_pro_designer
     FROM post_comments c LEFT JOIN users u ON u.id = c.author_id
     WHERE c.id = ?`,
  )
    .bind(id)
    .first<{
      id: string;
      post_id: string;
      author_id: string;
      body: string;
      created_at: string;
      author_name: string | null;
      author_avatar_url: string | null;
      author_is_pro_designer: number | null;
    }>();
  if (!created) return apiError(c, 500, "COMMENT_CREATE_FAILED", "Could not create comment");
  return c.json(
    {
      id: created.id,
      postId: created.post_id,
      authorId: created.author_id,
      authorName: created.author_name ?? "Lolipants User",
      authorAvatarUrl: created.author_avatar_url,
      isVerifiedDesigner: Boolean(created.author_is_pro_designer),
      body: created.body,
      createdAt: created.created_at,
    },
    201,
  );
});
