import { Hono } from "hono";
import { v4 as uuidv4 } from "uuid";
import { requireAuth } from "../middleware/auth";
import type { AppVariables, Env } from "../types";

export const bookingRoutes = new Hono<{ Bindings: Env; Variables: AppVariables }>();
bookingRoutes.use("*", requireAuth);

bookingRoutes.post("/", async (c) => {
  const userId = c.get("userId") as string;
  const body = (await c.req.json()) as Record<string, unknown>;
  const id = uuidv4();
  const reference = `BK-${Date.now().toString().slice(-8)}`;

  await c.env.DB.prepare(
    "INSERT INTO bookings (id, user_id, type, address, city, date, time_slot, reference) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
  )
    .bind(
      id,
      userId,
      body.type ?? "workshop_visit",
      body.address ?? null,
      body.city ?? null,
      body.date ?? "",
      body.timeSlot ?? "",
      reference,
    )
    .run();

  return c.json({ bookingId: id, reference }, 201);
});
