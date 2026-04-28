import { Hono } from "hono";
import { v4 as uuidv4 } from "uuid";
import { apiError } from "../lib/http";
import { sendToUser } from "../lib/onesignal";
import { requireAuth } from "../middleware/auth";
import type { AppVariables, Env } from "../types";

export const communityRoutes = new Hono<{ Bindings: Env; Variables: AppVariables }>();
communityRoutes.use("*", requireAuth);

communityRoutes.post("/consultations", async (c) => {
  const userId = c.get("userId") as string;
  const body = (await c.req.json()) as Record<string, unknown>;
  const id = uuidv4();

  await c.env.DB.prepare(
    "INSERT INTO consultations (id, user_id, garment_type, description, budget_min, budget_max) VALUES (?, ?, ?, ?, ?, ?)",
  )
    .bind(
      id,
      userId,
      body.garmentType ?? "other",
      body.description ?? "",
      body.budgetMin ?? null,
      body.budgetMax ?? null,
    )
    .run();

  return c.json({ id, submitted: true }, 201);
});

communityRoutes.get("/consultations", async (c) => {
  const userId = c.get("userId") as string;
  const role = c.req.query("role")?.trim().toLowerCase() ?? "mine";
  const column = role === "designer" ? "designer_id" : "user_id";
  const { results } = await c.env.DB.prepare(
    `SELECT * FROM consultations WHERE ${column} = ? ORDER BY created_at DESC LIMIT 200`,
  )
    .bind(userId)
    .all<Record<string, unknown>>();
  return c.json(results ?? []);
});

communityRoutes.patch("/consultations/:id", async (c) => {
  const userId = c.get("userId") as string;
  const userRole = c.get("userRole") as string | undefined;
  const id = c.req.param("id");
  const body = (await c.req.json()) as Record<string, unknown>;
  const status = body.status ? String(body.status).trim().toLowerCase() : null;
  const description = body.description ? String(body.description).trim() : null;

  const current = await c.env.DB.prepare(
    "SELECT id, user_id, designer_id FROM consultations WHERE id = ?",
  )
    .bind(id)
    .first<{ id: string; user_id: string; designer_id: string | null }>();
  if (!current) {
    return apiError(c, 404, "CONSULTATION_NOT_FOUND", "Consultation not found");
  }
  const isOwner = current.user_id === userId;
  const isAssignedDesigner = current.designer_id === userId;
  const isAdmin = userRole === "admin";
  if (!isOwner && !isAssignedDesigner && !isAdmin) {
    // Allow any designer to self-assign when no designer yet.
    if (!(current.designer_id === null && (userRole === "designer" || userRole === "admin"))) {
      return apiError(c, 403, "FORBIDDEN", "Not allowed");
    }
  }

  const sets: string[] = [];
  const binds: unknown[] = [];
  if (status) {
    sets.push("status = ?");
    binds.push(status);
  }
  if (description) {
    sets.push("description = ?");
    binds.push(description);
  }
  if (body.assignSelf === true && (userRole === "designer" || userRole === "admin")) {
    sets.push("designer_id = ?");
    binds.push(userId);
  }
  if (sets.length === 0) {
    return apiError(c, 400, "NO_FIELDS", "No fields to update");
  }
  binds.push(id);
  await c.env.DB.prepare(
    `UPDATE consultations SET ${sets.join(", ")} WHERE id = ?`,
  )
    .bind(...binds)
    .run();
  const updated = await c.env.DB.prepare("SELECT * FROM consultations WHERE id = ?")
    .bind(id)
    .first<Record<string, unknown>>();

  // Notify the consultation owner when a designer engages or status changes.
  try {
    const targetUserId = current.user_id;
    if (targetUserId && targetUserId !== userId) {
      let headings: { en: string; ar: string } | null = null;
      let contents: { en: string; ar: string } | null = null;
      if (body.assignSelf === true) {
        headings = {
          en: "A designer is on your consultation",
          ar: "مصمم التقط استشارتك",
        };
        contents = {
          en: "Tap to continue the conversation",
          ar: "تابع المحادثة الآن",
        };
      } else if (status) {
        headings = {
          en: "Consultation update",
          ar: "تحديث الاستشارة",
        };
        contents = {
          en: `Status is now ${status}`,
          ar: `الحالة الآن: ${status}`,
        };
      }
      if (headings && contents) {
        await sendToUser({
          env: c.env,
          userIds: [targetUserId],
          headings,
          contents,
          route: `/consultations/detail/${id}`,
        });
      }
    }
  } catch {
    // Best-effort notifications only.
  }
  return c.json(updated);
});

communityRoutes.post("/follow/:designerId", async (c) => {
  const followerId = c.get("userId") as string;
  const followingId = c.req.param("designerId");
  if (followerId === followingId) {
    return apiError(c, 400, "CANNOT_FOLLOW_SELF", "You cannot follow yourself");
  }
  const target = await c.env.DB.prepare("SELECT id FROM users WHERE id = ?")
    .bind(followingId)
    .first<{ id: string }>();
  if (!target) return apiError(c, 404, "USER_NOT_FOUND", "User not found");

  const result = await c.env.DB.prepare(
    "INSERT OR IGNORE INTO follows (follower_id, following_id) VALUES (?, ?)",
  )
    .bind(followerId, followingId)
    .run();
  if (result.meta?.changes ?? 0) {
    await c.env.DB.prepare(
      "UPDATE users SET follower_count = (SELECT COUNT(*) FROM follows WHERE following_id = ?) WHERE id = ?",
    )
      .bind(followingId, followingId)
      .run();
  }
  const row = await c.env.DB.prepare(
    "SELECT follower_count FROM users WHERE id = ?",
  )
    .bind(followingId)
    .first<{ follower_count: number }>();
  return c.json({
    followed: true,
    followerCount: Number(row?.follower_count ?? 0),
  });
});

communityRoutes.delete("/follow/:designerId", async (c) => {
  const followerId = c.get("userId") as string;
  const followingId = c.req.param("designerId");
  const result = await c.env.DB.prepare(
    "DELETE FROM follows WHERE follower_id = ? AND following_id = ?",
  )
    .bind(followerId, followingId)
    .run();
  if (result.meta?.changes ?? 0) {
    await c.env.DB.prepare(
      "UPDATE users SET follower_count = (SELECT COUNT(*) FROM follows WHERE following_id = ?) WHERE id = ?",
    )
      .bind(followingId, followingId)
      .run();
  }
  const row = await c.env.DB.prepare(
    "SELECT follower_count FROM users WHERE id = ?",
  )
    .bind(followingId)
    .first<{ follower_count: number }>();
  return c.json({
    followed: false,
    followerCount: Number(row?.follower_count ?? 0),
  });
});
