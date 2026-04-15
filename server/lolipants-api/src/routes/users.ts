import { Hono } from "hono";
import { requireAuth } from "../middleware/auth";
import type { AppVariables, Env } from "../types";

export const userRoutes = new Hono<{ Bindings: Env; Variables: AppVariables }>();
userRoutes.use("*", requireAuth);

userRoutes.post("/push-token", async (c) => {
  const userId = c.get("userId") as string;
  const body = (await c.req.json()) as { oneSignalId?: string };
  if (!body.oneSignalId) return c.json({ error: "oneSignalId is required" }, 400);

  await c.env.DB.prepare(
    `INSERT INTO push_tokens (user_id, onesignal_id, updated_at)
     VALUES (?, ?, datetime('now'))
     ON CONFLICT(user_id) DO UPDATE SET onesignal_id = excluded.onesignal_id, updated_at = datetime('now')`,
  )
    .bind(userId, body.oneSignalId)
    .run();

  return c.json({ saved: true });
});
