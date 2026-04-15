import { Hono } from "hono";
import { v4 as uuidv4 } from "uuid";
import { requireAuth } from "../middleware/auth";
import type { AppVariables, Env } from "../types";

export const measurementRoutes = new Hono<{ Bindings: Env; Variables: AppVariables }>();
measurementRoutes.use("*", requireAuth);

measurementRoutes.get("/me", async (c) => {
  const userId = c.get("userId") as string;
  const measurement = await c.env.DB.prepare(
    "SELECT * FROM measurements WHERE user_id = ? ORDER BY saved_at DESC LIMIT 1",
  )
    .bind(userId)
    .first();
  return c.json(measurement ?? null);
});

measurementRoutes.post("/", async (c) => {
  const userId = c.get("userId") as string;
  const body = (await c.req.json()) as Record<string, unknown>;
  const id = uuidv4();

  await c.env.DB.prepare(
    `INSERT INTO measurements (id, user_id, chest, waist, hips, shoulder_width, height, arm_length, preferred_size)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
  )
    .bind(
      id,
      userId,
      body.chest ?? null,
      body.waist ?? null,
      body.hips ?? null,
      body.shoulderWidth ?? null,
      body.height ?? null,
      body.armLength ?? null,
      body.preferredSize ?? null,
    )
    .run();

  const saved = await c.env.DB.prepare("SELECT * FROM measurements WHERE id = ?")
    .bind(id)
    .first();
  return c.json(saved, 201);
});
