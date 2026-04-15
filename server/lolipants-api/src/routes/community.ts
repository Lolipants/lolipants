import { Hono } from "hono";
import { v4 as uuidv4 } from "uuid";
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

communityRoutes.post("/follow/:designerId", async (c) => {
  const followerId = c.get("userId") as string;
  const followingId = c.req.param("designerId");
  await c.env.DB.prepare(
    "INSERT OR IGNORE INTO follows (follower_id, following_id) VALUES (?, ?)",
  )
    .bind(followerId, followingId)
    .run();
  return c.json({ followed: true });
});

communityRoutes.delete("/follow/:designerId", async (c) => {
  const followerId = c.get("userId") as string;
  const followingId = c.req.param("designerId");
  await c.env.DB.prepare(
    "DELETE FROM follows WHERE follower_id = ? AND following_id = ?",
  )
    .bind(followerId, followingId)
    .run();
  return c.json({ followed: false });
});
