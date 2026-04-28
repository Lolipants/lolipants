import { Hono } from "hono";
import { v4 as uuidv4 } from "uuid";
import { apiError } from "../lib/http";
import { requireAuth } from "../middleware/auth";
import type { AppVariables, Env } from "../types";

/**
 * User-facing complaint submission. Moderators / admins consume these via
 * `/admin/complaints`.
 */
export const complaintRoutes = new Hono<{ Bindings: Env; Variables: AppVariables }>();
complaintRoutes.use("*", requireAuth);

const VALID_TARGET_TYPES = new Set(["order", "post", "showcase", "user", "other"]);

complaintRoutes.post("/", async (c) => {
  const userId = c.get("userId") as string;
  const body = (await c.req.json().catch(() => ({}))) as Record<string, unknown>;
  const targetType = String(body.targetType ?? body.target_type ?? "other")
    .trim()
    .toLowerCase();
  const targetId = String(body.targetId ?? body.target_id ?? "").trim();
  const subject = String(body.subject ?? "").trim();
  const bodyText = String(body.body ?? "").trim();
  if (!VALID_TARGET_TYPES.has(targetType)) {
    return apiError(c, 400, "INVALID_TARGET_TYPE", "Invalid target type");
  }
  if (!subject || subject.length < 3) {
    return apiError(c, 400, "SUBJECT_REQUIRED", "Subject is required");
  }
  if (!bodyText || bodyText.length < 10) {
    return apiError(c, 400, "BODY_REQUIRED", "Please describe the issue");
  }
  const id = uuidv4();
  await c.env.DB.prepare(
    `INSERT INTO complaints (id, user_id, target_type, target_id, subject, body, status)
     VALUES (?, ?, ?, ?, ?, ?, 'open')`,
  )
    .bind(id, userId, targetType, targetId || "", subject, bodyText)
    .run();
  return c.json(
    {
      id,
      userId,
      targetType,
      targetId,
      subject,
      body: bodyText,
      status: "open",
    },
    201,
  );
});

/** List complaints submitted by the signed-in user. */
complaintRoutes.get("/mine", async (c) => {
  const userId = c.get("userId") as string;
  const { results } = await c.env.DB.prepare(
    "SELECT * FROM complaints WHERE user_id = ? ORDER BY created_at DESC LIMIT 100",
  )
    .bind(userId)
    .all();
  return c.json(results);
});
