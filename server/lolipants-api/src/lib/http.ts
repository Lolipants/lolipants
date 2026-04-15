import type { Context } from "hono";
import type { AppVariables, Env } from "../types";

export function getBearerToken(
  c: Context<{ Bindings: Env; Variables: AppVariables }>,
): string | null {
  const authHeader = c.req.header("Authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) return null;
  return authHeader.replace("Bearer ", "").trim();
}

export function badRequest(
  c: Context<{ Bindings: Env; Variables: AppVariables }>,
  message: string,
  details?: unknown,
) {
  return c.json({ error: message, details }, 400);
}
