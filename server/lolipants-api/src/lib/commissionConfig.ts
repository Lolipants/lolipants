import type { Env } from "../types";

const DEFAULT_PCT = 10;

/** Designer commission percentage from env (default 10). */
export function designerCommissionPct(env: Env): number {
  const raw = env.DESIGNER_COMMISSION_PCT?.trim();
  if (!raw) return DEFAULT_PCT;
  const n = Number(raw);
  if (!Number.isFinite(n) || n <= 0 || n > 100) return DEFAULT_PCT;
  return n;
}
