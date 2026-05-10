import { beforeEach, describe, expect, it, vi } from "vitest";
import app from "../index";

type Row = Record<string, unknown>;

class MockDb {
  designs = new Map<string, Row>();
  mannequinJobs = new Map<string, Row>();
  renderJobs = new Map<string, Row>();

  prepare(sql: string) {
    return new Stmt(this, sql);
  }
}

class Stmt {
  constructor(
    private readonly db: MockDb,
    private readonly sql: string,
    private binds: unknown[] = [],
  ) {}

  bind(...values: unknown[]) {
    this.binds = values;
    return this;
  }

  async first<T>() {
    const s = this.sql;
    const b = this.binds;
    if (s.includes("FROM designs WHERE id = ? AND user_id = ?")) {
      const design = this.db.designs.get(String(b[0]));
      if (!design || design.user_id !== b[1]) return null;
      return design as T;
    }
    if (s.includes("FROM designs d") && s.includes("LEFT JOIN mannequin_options")) {
      const design = this.db.designs.get(String(b[0]));
      if (!design || design.user_id !== b[1]) return null;
      return {
        print_image_url: design.print_image_url ?? null,
        render_metadata: design.render_metadata ?? null,
        garment_type: design.garment_type ?? "thobe",
        mannequin_id: design.mannequin_id ?? null,
        primary_colour: design.primary_colour ?? "#162F28",
        accent_colour: design.accent_colour ?? "#C9A84C",
        mannequin_preview_url: null,
      } as T;
    }
    if (s.includes("FROM design_render_jobs WHERE id = ? AND user_id = ?")) {
      const job = this.db.renderJobs.get(String(b[0]));
      if (!job || job.user_id !== b[1]) return null;
      return job as T;
    }
    if (s.includes("FROM design_render_jobs WHERE id = ?")) {
      return (this.db.renderJobs.get(String(b[0])) ?? null) as T | null;
    }
    if (s.includes("FROM mannequin_jobs WHERE id = ? AND user_id = ?")) {
      const job = this.db.mannequinJobs.get(String(b[0]));
      if (!job || job.user_id !== b[1]) return null;
      return job as T;
    }
    if (s.includes("FROM mannequin_jobs WHERE id = ?")) {
      return (this.db.mannequinJobs.get(String(b[0])) ?? null) as T | null;
    }
    return null;
  }

  async run() {
    const s = this.sql;
    const b = this.binds;
    if (s.includes("INSERT INTO design_render_jobs")) {
      this.db.renderJobs.set(String(b[0]), {
        id: b[0],
        user_id: b[1],
        design_id: b[2],
        mannequin_id: b[3] ?? null,
        status: "queued",
        provider_status: "queued",
        artifact_urls: "{}",
        attempt_count: 0,
      });
      return { success: true };
    }
    if (s.includes("UPDATE design_render_jobs")) {
      const id = String(b[b.length - 1]);
      const existing = this.db.renderJobs.get(id);
      if (!existing) return { success: true };
      // Best-effort update for the fields our handler sets.
      const merged = { ...existing };
      if (s.includes("status = 'rendering'")) {
        merged.status = "rendering";
        merged.provider_status = "processing";
      }
      if (s.includes("status = 'failed'")) {
        merged.status = "failed";
        merged.provider_status = "failed";
        merged.error_message = b[0];
        if (typeof b[1] === "number") {
          merged.attempt_count = b[1];
          merged.artifact_urls = b[2];
        } else {
          merged.artifact_urls = b[1];
        }
      }
      if (s.includes("status = 'completed'")) {
        merged.status = "completed";
        merged.provider_status = "completed";
        merged.attempt_count = b[0];
        merged.artifact_urls = b[1];
      }
      this.db.renderJobs.set(id, merged);
      return { success: true };
    }
    if (s.includes("INSERT INTO mannequin_jobs")) {
      this.db.mannequinJobs.set(String(b[0]), {
        id: b[0],
        user_id: b[1],
        source_url: b[2],
        status: "queued",
        provider_status: "queued",
        preview_url: null,
        artifact_urls: "{}",
        retry_count: 0,
      });
      return { success: true };
    }
    if (s.includes("UPDATE mannequin_jobs")) {
      const id = String(b[b.length - 1]);
      const existing = this.db.mannequinJobs.get(id);
      if (!existing) return { success: true };
      const merged = { ...existing };
      if (s.includes("status = 'rendering'")) {
        merged.status = "rendering";
        merged.provider_status = "processing";
      }
      if (s.includes("status = 'failed'")) {
        merged.status = "failed";
        merged.provider_status = "failed";
      }
      if (s.includes("status = 'completed'")) {
        merged.status = "completed";
        merged.provider_status = "completed";
        merged.preview_url = b[0];
        merged.artifact_urls = b[2];
      }
      this.db.mannequinJobs.set(id, merged);
      return { success: true };
    }
    return { success: true };
  }
}

const mockDb = new MockDb();

const env = {
  DB: mockDb as unknown as D1Database,
  R2: { put: async () => undefined } as unknown as R2Bucket,
  AUTH_SERVICE: {
    fetch: async (req: Request) => {
      const token = (req.headers.get("Authorization") ?? "").replace("Bearer ", "");
      if (token === "customer-token") {
        return new Response(
          JSON.stringify({
            user: {
              id: "user-1",
              role: "user",
              name: "Customer",
              email: "c@example.com",
            },
          }),
          { status: 200, headers: { "Content-Type": "application/json" } },
        );
      }
      return new Response("unauthorized", { status: 401 });
    },
  } as Fetcher,
  BETTER_AUTH_BASE_URL: "https://auth.local",
  OPENAI_API_KEY: "k",
  TAP_SECRET_KEY: "k",
  ONESIGNAL_API_KEY: "k",
  ONESIGNAL_APP_ID: "k",
  CLOUDFLARE_R2_BASE_URL: "https://files.example.com",
  ENVIRONMENT: "test",
} as const;

async function req(
  method: string,
  path: string,
  options: { token?: string; body?: unknown; formData?: FormData } = {},
) {
  const pending: Promise<unknown>[] = [];
  const headers = new Headers();
  if (options.token) headers.set("Authorization", `Bearer ${options.token}`);
  if (options.body !== undefined) headers.set("Content-Type", "application/json");
  const request = new Request(`http://local${path}`, {
    method,
    headers,
    body: options.formData ?? (options.body !== undefined ? JSON.stringify(options.body) : undefined),
  });
  const response = await app.fetch(request, env, {
    waitUntil: (p: Promise<unknown>) => {
      pending.push(p);
    },
    passThroughOnException: () => undefined,
  } as unknown as ExecutionContext);
  await Promise.all(pending);
  return response;
}

describe("AI render job endpoints", () => {
  beforeEach(() => {
    mockDb.designs.clear();
    mockDb.mannequinJobs.clear();
    mockDb.renderJobs.clear();
    vi.restoreAllMocks();
  });

  it("creates and fetches a design render job", async () => {
    mockDb.designs.set("design-1", {
      id: "design-1",
      user_id: "user-1",
      mannequin_id: null,
      print_image_url: "https://files.example.com/uploads/u/p.png",
      render_metadata: JSON.stringify({
        mannequinTemplateId: "male_thobe_v1",
        fabricProfile: "standard",
        printTransform: { placement: "chest", x: 0, y: 0, scale: 40 },
        textLayers: [{ text: "Hello", x: 0.5, y: 0.5 }],
      }),
    });

    const start = await req("POST", "/ai/design-render", {
      token: "customer-token",
      body: { designId: "design-1" },
    });
    expect(start.status).toBe(202);
    const startBody = (await start.json()) as { jobId: string; status: string };
    expect(startBody.jobId.length).toBeGreaterThan(0);
    expect(startBody.status).toBe("queued");

    // WaitUntil tasks are awaited inside req(), so the job should progress.
    const status = await req("GET", `/ai/design-render/${startBody.jobId}`, {
      token: "customer-token",
    });
    expect(status.status).toBe(200);
    const body = (await status.json()) as {
      jobId: string;
      status: string;
      artifacts: Record<string, string>;
    };
    expect(body.jobId).toBe(startBody.jobId);
    expect(body.artifacts.heroFrontUrl?.length ?? 0).toBeGreaterThan(0);
  });

  it("returns deterministic fallback artifacts without provider calls", async () => {
    mockDb.designs.set("design-fail", {
      id: "design-fail",
      user_id: "user-1",
      mannequin_id: null,
      print_image_url: "https://files.example.com/uploads/u/fallback.png",
      render_metadata: JSON.stringify({
        mannequinTemplateId: "default_thobe_v1",
        fabricProfile: "standard",
        printTransform: { placement: "chest", x: 0, y: 0, scale: 40 },
        textLayers: [],
      }),
    });

    const start = await req("POST", "/ai/design-render", {
      token: "customer-token",
      body: { designId: "design-fail" },
    });
    expect(start.status).toBe(202);
    const startBody = (await start.json()) as { jobId: string };

    const status = await req("GET", `/ai/design-render/${startBody.jobId}`, {
      token: "customer-token",
    });
    expect(status.status).toBe(200);
    const body = (await status.json()) as {
      status: string;
      artifacts: Record<string, string>;
    };
    expect(body.status).toBe("completed");
    expect(body.artifacts.heroFrontUrl).toBe(
      "https://files.example.com/uploads/u/fallback.png",
    );
  });
});

