import { Hono } from "hono";
import { v4 as uuidv4 } from "uuid";
import { requireAuth } from "../middleware/auth";
import type { AppVariables, Env } from "../types";

export const uploadRoutes = new Hono<{ Bindings: Env; Variables: AppVariables }>();
uploadRoutes.use("*", requireAuth);

uploadRoutes.post("/", async (c) => {
  const formData = await c.req.formData();
  const file = formData.get("file") as File | null;
  if (!file) return c.json({ error: "No file provided" }, 400);

  const allowedTypes = ["image/jpeg", "image/png", "image/webp"];
  if (!allowedTypes.includes(file.type)) {
    return c.json({ error: "Unsupported file type" }, 400);
  }

  if (file.size > 5 * 1024 * 1024) {
    return c.json({ error: "File exceeds 5MB limit" }, 400);
  }

  const userId = c.get("userId") as string;
  const ext = file.type.split("/")[1] ?? "jpg";
  const key = `uploads/${userId}/${uuidv4()}.${ext}`;

  await c.env.R2.put(key, await file.arrayBuffer(), {
    httpMetadata: { contentType: file.type },
  });

  const url = `${c.env.CLOUDFLARE_R2_BASE_URL}/${key}`;
  return c.json({ url, key }, 201);
});
