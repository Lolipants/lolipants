import { Hono } from "hono";
import { v4 as uuidv4 } from "uuid";
import { apiError } from "../lib/http";
import { requireAuth } from "../middleware/auth";
import type { AppVariables, Env } from "../types";

export const uploadRoutes = new Hono<{ Bindings: Env; Variables: AppVariables }>();
uploadRoutes.use("*", requireAuth);

uploadRoutes.post("/", async (c) => {
  const formData = await c.req.formData();
  const file = formData.get("file") as File | null;
  if (!file) return apiError(c, 400, "FILE_REQUIRED", "No file provided");

  const allowedTypes = ["image/jpeg", "image/png", "image/webp"];
  if (!allowedTypes.includes(file.type)) {
    return apiError(c, 400, "UNSUPPORTED_FILE_TYPE", "Unsupported file type");
  }

  if (file.size > 5 * 1024 * 1024) {
    return apiError(c, 400, "FILE_TOO_LARGE", "File exceeds 5MB limit");
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
