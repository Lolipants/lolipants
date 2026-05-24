import { describe, expect, it } from "vitest";
import {
  AI_RENDER_WEEKLY_LIMIT,
  getAiRenderQuota,
} from "../lib/aiRenderQuota";

type Row = Record<string, unknown>;

class QuotaMockDb {
  jobs: Row[] = [];

  prepare(sql: string) {
    return new QuotaStmt(this, sql);
  }
}

class QuotaStmt {
  constructor(
    private readonly db: QuotaMockDb,
    private readonly sql: string,
    private binds: unknown[] = [],
  ) {}

  bind(...values: unknown[]) {
    this.binds = values;
    return this;
  }

  async first<T>() {
    if (this.sql.includes("COUNT(*)") && this.sql.includes("design_render_jobs")) {
      const userId = String(this.binds[0]);
      const matching = this.db.jobs.filter((j) => j.user_id === userId);
      const count = matching.length;
      let oldest: string | null = null;
      for (const job of matching) {
        const ts = String(job.started_at ?? job.created_at ?? "");
        if (!oldest || ts < oldest) oldest = ts;
      }
      return {
        used: count,
        resets_at: count > 0 ? `${oldest} +7` : null,
      } as T;
    }
    return null;
  }
}

describe("getAiRenderQuota", () => {
  it("returns full remaining allowance when no recent jobs", async () => {
    const db = new QuotaMockDb();
    const quota = await getAiRenderQuota(db as unknown as D1Database, "user-1");
    expect(quota.limit).toBe(AI_RENDER_WEEKLY_LIMIT);
    expect(quota.used).toBe(0);
    expect(quota.remaining).toBe(3);
    expect(quota.resetsAt).toBeNull();
  });

  it("subtracts used jobs from the weekly allowance", async () => {
    const db = new QuotaMockDb();
    db.jobs.push(
      {
        user_id: "user-1",
        started_at: "2026-05-20 10:00:00",
        created_at: "2026-05-20 10:00:00",
      },
      {
        user_id: "user-1",
        started_at: "2026-05-21 10:00:00",
        created_at: "2026-05-21 10:00:00",
      },
    );
    const quota = await getAiRenderQuota(db as unknown as D1Database, "user-1");
    expect(quota.used).toBe(2);
    expect(quota.remaining).toBe(1);
    expect(quota.resetsAt).toBeTruthy();
  });
});
