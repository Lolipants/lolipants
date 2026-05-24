import { Hono } from "hono";
import { apiError } from "../lib/http";
import { requireAuth } from "../middleware/auth";
import type { AppVariables, Env } from "../types";

export const userRoutes = new Hono<{ Bindings: Env; Variables: AppVariables }>();
userRoutes.use("*", requireAuth);

/// Current viewer role + admin scopes (same rules as [requireAuth] — D1 over session).
userRoutes.get("/me", async (c) => {
  const userId = c.get("userId") as string;
  const role = c.get("userRole") as string;
  const adminScopes = (c.get("adminScopes") as string[] | undefined) ?? [];
  let gender: string | null = null;
  try {
    const row = await c.env.DB.prepare("SELECT gender FROM users WHERE id = ?")
      .bind(userId)
      .first<{ gender: string | null }>();
    gender = row?.gender?.trim() || null;
  } catch {
    // Pre-migration databases omit gender.
  }
  return c.json({ id: userId, role, adminScopes, gender });
});

const VALID_GENDER_VALUES = new Set(["men", "women", "kids"]);

userRoutes.patch("/me", async (c) => {
  const userId = c.get("userId") as string;
  const body = (await c.req.json()) as { gender?: string };
  const gender = body.gender?.trim().toLowerCase() ?? "";
  if (!VALID_GENDER_VALUES.has(gender)) {
    return apiError(
      c,
      400,
      "INVALID_GENDER",
      "gender must be one of: men, women, kids",
    );
  }
  try {
    await c.env.DB.prepare(
      `UPDATE users SET gender = ?, updated_at = datetime('now') WHERE id = ?`,
    )
      .bind(gender, userId)
      .run();
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    return apiError(c, 500, "GENDER_UPDATE_FAILED", message);
  }
  return c.json({ gender });
});

userRoutes.post("/push-token", async (c) => {
  const userId = c.get("userId") as string;
  const body = (await c.req.json()) as { oneSignalId?: string };
  if (!body.oneSignalId) {
    return apiError(c, 400, "ONESIGNAL_ID_REQUIRED", "oneSignalId is required");
  }

  await c.env.DB.prepare(
    `INSERT INTO push_tokens (user_id, onesignal_id, updated_at)
     VALUES (?, ?, datetime('now'))
     ON CONFLICT(user_id) DO UPDATE SET onesignal_id = excluded.onesignal_id, updated_at = datetime('now')`,
  )
    .bind(userId, body.oneSignalId)
    .run();

  return c.json({ saved: true });
});

userRoutes.delete("/push-token", async (c) => {
  const userId = c.get("userId") as string;
  await c.env.DB.prepare("DELETE FROM push_tokens WHERE user_id = ?")
    .bind(userId)
    .run();
  return c.json({ cleared: true });
});
