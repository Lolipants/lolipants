/** v1 cap: AI garment renders per user per rolling 7-day window. */
export const AI_RENDER_WEEKLY_LIMIT = 3;
export const AI_RENDER_WINDOW_DAYS = 7;

export type AiRenderQuota = {
  limit: number;
  used: number;
  remaining: number;
  resetsAt: string | null;
};

export async function getAiRenderQuota(
  db: D1Database,
  userId: string,
): Promise<AiRenderQuota> {
  const row = await db
    .prepare(
      `SELECT COUNT(*) AS used,
        CASE
          WHEN COUNT(*) > 0 THEN datetime(
            MIN(datetime(COALESCE(started_at, created_at))),
            '+${AI_RENDER_WINDOW_DAYS} days'
          )
          ELSE NULL
        END AS resets_at
       FROM design_render_jobs
       WHERE user_id = ?
         AND datetime(COALESCE(started_at, created_at)) >= datetime('now', '-${AI_RENDER_WINDOW_DAYS} days')`,
    )
    .bind(userId)
    .first<{ used: number; resets_at: string | null }>();

  const used = Number(row?.used ?? 0);
  const remaining = Math.max(0, AI_RENDER_WEEKLY_LIMIT - used);

  return {
    limit: AI_RENDER_WEEKLY_LIMIT,
    used,
    remaining,
    resetsAt: row?.resets_at ?? null,
  };
}
