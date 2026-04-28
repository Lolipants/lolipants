import { Hono } from "hono";
import { v4 as uuidv4 } from "uuid";
import { apiError } from "../lib/http";
import { requireAuth } from "../middleware/auth";
import type { AppVariables, Env } from "../types";

const REQUESTABLE = new Set(["tailor", "delivery"]);

export const roleRequestRoutes = new Hono<{ Bindings: Env; Variables: AppVariables }>();
roleRequestRoutes.use("*", requireAuth);

roleRequestRoutes.post("/", async (c) => {
  const userId = c.get("userId") as string;
  const body = (await c.req.json().catch(() => ({}))) as Record<string, unknown>;
  const requestedRaw = String(
    body.requestedRole ?? body.requested_role ?? "",
  )
    .trim()
    .toLowerCase();
  const message = body.message != null ? String(body.message).trim() : "";

  if (!REQUESTABLE.has(requestedRaw)) {
    return apiError(
      c,
      400,
      "INVALID_REQUESTED_ROLE",
      "requestedRole must be tailor or delivery",
    );
  }

  const userRow = await c.env.DB.prepare(
    "SELECT id, role FROM users WHERE id = ?",
  )
    .bind(userId)
    .first<{ id: string; role: string | null }>();

  const currentRole = (userRow?.role ?? "user").trim().toLowerCase();
  if (currentRole !== "user") {
    return apiError(
      c,
      400,
      "ROLE_NOT_ELIGIBLE",
      "Only customer accounts can request a partner role",
    );
  }

  const pending = await c.env.DB.prepare(
    "SELECT id FROM role_requests WHERE user_id = ? AND status = 'pending' LIMIT 1",
  )
    .bind(userId)
    .first<{ id: string }>();
  if (pending) {
    return apiError(
      c,
      409,
      "PENDING_EXISTS",
      "You already have a pending request",
    );
  }

  const id = uuidv4();
  await c.env.DB.prepare(
    `INSERT INTO role_requests (id, user_id, requested_role, message, status)
     VALUES (?, ?, ?, ?, 'pending')`,
  )
    .bind(id, userId, requestedRaw, message.length > 0 ? message : null)
    .run();

  return c.json(
    {
      id,
      userId,
      requestedRole: requestedRaw,
      message: message.length > 0 ? message : null,
      status: "pending",
    },
    201,
  );
});

roleRequestRoutes.get("/mine", async (c) => {
  const userId = c.get("userId") as string;
  const { results } = await c.env.DB.prepare(
    `SELECT id, user_id, requested_role, message, status, admin_note, created_at, resolved_at, resolved_by
     FROM role_requests
     WHERE user_id = ?
     ORDER BY created_at DESC
     LIMIT 100`,
  )
    .bind(userId)
    .all();
  return c.json(results);
});
