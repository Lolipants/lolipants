/**
 * Fashion news public + admin RBAC tests.
 */
import { beforeEach, describe, expect, it } from "vitest";
import app from "../index";

type Row = Record<string, unknown>;

type NewsRow = {
  id: string;
  title_en: string;
  title_ar: string;
  summary_en: string;
  summary_ar: string;
  body_en: string;
  body_ar: string;
  cover_image_url: string | null;
  is_published: number;
  is_featured: number;
  published_at: string | null;
  author_id: string;
  created_at: string;
  updated_at: string;
};

type UserRow = {
  id: string;
  name: string;
  email: string;
  role: string;
  admin_scopes: string | null;
  banned_at: string | null;
};

class MockPreparedStatement {
  constructor(
    private readonly db: MockDb,
    private readonly sql: string,
    private binds: unknown[] = [],
  ) {}

  bind(...values: unknown[]) {
    this.binds = values;
    return this;
  }

  async all<T = Row>() {
    return { results: this.db.select(this.sql, this.binds) as T[] };
  }

  async first<T>() {
    return this.db.first(this.sql, this.binds) as T | null;
  }

  async run() {
    const meta = this.db.run(this.sql, this.binds) ?? { changes: 0 };
    return { success: true, meta };
  }
}

class MockDb {
  users = new Map<string, UserRow>();
  fashionNews = new Map<string, NewsRow>();

  prepare(sql: string) {
    return new MockPreparedStatement(this, sql);
  }

  select(sql: string, binds: unknown[]): Row[] {
    if (sql.includes("FROM users WHERE id = ?") && sql.includes("role")) {
      const id = String(binds[0] ?? "");
      const user = this.users.get(id);
      if (!user) return [];
      return [
        {
          role: user.role,
          admin_scopes: user.admin_scopes,
          banned_at: user.banned_at,
          id: user.id,
          name: user.name,
        },
      ];
    }
    if (sql.includes("FROM fashion_news n") && sql.includes("is_featured = 1")) {
      const featured = [...this.fashionNews.values()].find(
        (n) => n.is_published === 1 && n.is_featured === 1,
      );
      if (!featured) return [];
      const author = this.users.get(featured.author_id);
      return [{ ...featured, author_name: author?.name ?? "Admin" }];
    }
    if (sql.includes("FROM fashion_news n") && sql.includes("ORDER BY n.published_at DESC")) {
      let rows = [...this.fashionNews.values()].filter((n) => n.is_published === 1);
      let bindOffset = 0;
      if (sql.includes("n.id != ?")) {
        const excludeId = String(binds[0] ?? "");
        rows = rows.filter((n) => n.id !== excludeId);
        bindOffset = 1;
      }
      if (sql.includes("published_at < ?")) {
        const cursor = String(binds[bindOffset] ?? "");
        rows = rows.filter((n) => (n.published_at ?? "") < cursor);
        bindOffset += 1;
      }
      rows.sort((a, b) => (b.published_at ?? "").localeCompare(a.published_at ?? ""));
      const limit = Number(binds[binds.length - 1] ?? 20);
      return rows.slice(0, limit).map((n) => {
        const author = this.users.get(n.author_id);
        return { ...n, author_name: author?.name ?? "Admin" };
      });
    }
    if (sql.includes("FROM fashion_news n") && sql.includes("n.id = ? AND n.is_published = 1")) {
      const id = String(binds[0] ?? "");
      const row = this.fashionNews.get(id);
      if (!row || row.is_published !== 1) return [];
      const author = this.users.get(row.author_id);
      return [{ ...row, author_name: author?.name ?? "Admin" }];
    }
    if (sql.includes("FROM fashion_news") && sql.includes("ORDER BY created_at DESC")) {
      return [...this.fashionNews.values()].sort((a, b) =>
        b.created_at.localeCompare(a.created_at),
      );
    }
    if (sql.includes("FROM fashion_news WHERE id = ?")) {
      const id = String(binds[0] ?? "");
      const row = this.fashionNews.get(id);
      return row ? [row] : [];
    }
    return [];
  }

  first(sql: string, binds: unknown[]): Row | null {
    const rows = this.select(sql, binds);
    return rows[0] ?? null;
  }

  run(sql: string, binds: unknown[]): { changes: number } {
    if (sql.includes("UPDATE fashion_news SET is_featured = 0")) {
      for (const row of this.fashionNews.values()) {
        row.is_featured = 0;
      }
      return { changes: 1 };
    }
    if (sql.startsWith("INSERT INTO fashion_news")) {
      const id = String(binds[0]);
      this.fashionNews.set(id, {
        id,
        title_en: String(binds[1]),
        title_ar: String(binds[2]),
        summary_en: String(binds[3]),
        summary_ar: String(binds[4]),
        body_en: String(binds[5]),
        body_ar: String(binds[6]),
        cover_image_url: binds[7] as string | null,
        is_published: Number(binds[8]),
        is_featured: Number(binds[9]),
        published_at: binds[10] as string | null,
        author_id: String(binds[11]),
        created_at: String(binds[12]),
        updated_at: String(binds[13]),
      });
      return { changes: 1 };
    }
    if (sql.startsWith("UPDATE fashion_news SET")) {
      const id = String(binds[binds.length - 1]);
      const existing = this.fashionNews.get(id);
      if (!existing) return { changes: 0 };
      existing.title_en = String(binds[0]);
      existing.title_ar = String(binds[1]);
      existing.summary_en = String(binds[2]);
      existing.summary_ar = String(binds[3]);
      existing.body_en = String(binds[4]);
      existing.body_ar = String(binds[5]);
      existing.cover_image_url = binds[6] as string | null;
      existing.is_published = Number(binds[7]);
      existing.is_featured = Number(binds[8]);
      existing.published_at = binds[9] as string | null;
      existing.updated_at = String(binds[10]);
      return { changes: 1 };
    }
    if (sql.startsWith("DELETE FROM fashion_news")) {
      const id = String(binds[0]);
      const had = this.fashionNews.delete(id);
      return { changes: had ? 1 : 0 };
    }
    return { changes: 0 };
  }
}

const mockDb = new MockDb();

const env = {
  DB: mockDb as unknown as D1Database,
  R2: { put: async () => undefined } as unknown as R2Bucket,
  AUTH_SERVICE: {
    fetch: async (req: Request) => {
      const token = req.headers.get("Authorization")?.replace("Bearer ", "") ?? "";
      const who = TOKENS[token];
      if (!who) return new Response("unauthorized", { status: 401 });
      return new Response(
        JSON.stringify({ user: { id: who.id, role: who.role, name: who.name, email: who.email } }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      );
    },
  } as Fetcher,
  BETTER_AUTH_BASE_URL: "https://auth.local",
  INTERNAL_SYNC_SECRET: "test-sync",
  ENVIRONMENT: "test",
  CLOUDFLARE_R2_BASE_URL: "https://cdn.example.com",
} as unknown as Parameters<typeof app.fetch>[1];

const TOKENS: Record<string, { id: string; role: string; name: string; email: string }> = {
  "user-token": { id: "user-1", role: "user", name: "User", email: "user@example.com" },
  "news-admin": { id: "news-1", role: "admin", name: "News", email: "news@example.com" },
  "cms-admin": { id: "cms-1", role: "admin", name: "CMS", email: "cms@example.com" },
};

function seedUsers() {
  mockDb.users.set("user-1", {
    id: "user-1",
    role: "user",
    name: "User",
    email: "user@example.com",
    admin_scopes: null,
    banned_at: null,
  });
  mockDb.users.set("news-1", {
    id: "news-1",
    role: "admin",
    name: "News",
    email: "news@example.com",
    admin_scopes: JSON.stringify(["news"]),
    banned_at: null,
  });
  mockDb.users.set("cms-1", {
    id: "cms-1",
    role: "admin",
    name: "CMS",
    email: "cms@example.com",
    admin_scopes: JSON.stringify(["cms"]),
    banned_at: null,
  });
}

async function apiRequest(
  method: string,
  path: string,
  options: { token?: string; body?: unknown } = {},
) {
  const headers = new Headers();
  if (options.token) headers.set("Authorization", `Bearer ${options.token}`);
  if (options.body) headers.set("Content-Type", "application/json");
  return app.fetch(
    new Request(`http://local${path}`, {
      method,
      headers,
      body: options.body ? JSON.stringify(options.body) : undefined,
    }),
    env,
  );
}

describe("fashion news API", () => {
  beforeEach(() => {
    mockDb.users.clear();
    mockDb.fashionNews.clear();
    seedUsers();
  });

  it("lists only published articles for authenticated users", async () => {
    const now = new Date().toISOString();
    mockDb.fashionNews.set("pub-1", {
      id: "pub-1",
      title_en: "Trend",
      title_ar: "موضة",
      summary_en: "Summary",
      summary_ar: "ملخص",
      body_en: "Body",
      body_ar: "نص",
      cover_image_url: "https://cdn.example.com/a.jpg",
      is_published: 1,
      is_featured: 1,
      published_at: now,
      author_id: "news-1",
      created_at: now,
      updated_at: now,
    });
    mockDb.fashionNews.set("draft-1", {
      id: "draft-1",
      title_en: "Draft",
      title_ar: "مسودة",
      summary_en: "",
      summary_ar: "",
      body_en: "",
      body_ar: "",
      cover_image_url: null,
      is_published: 0,
      is_featured: 0,
      published_at: null,
      author_id: "news-1",
      created_at: now,
      updated_at: now,
    });

    const response = await apiRequest("GET", "/news", { token: "user-token" });
    expect(response.status).toBe(200);
    const body = (await response.json()) as {
      featured: { id: string } | null;
      articles: { id: string }[];
    };
    expect(body.featured?.id).toBe("pub-1");
    expect(body.articles.map((a) => a.id)).toEqual([]);
  });

  it("lets news-scoped admins create articles but blocks cms-only admins", async () => {
    const blocked = await apiRequest("POST", "/admin/news", {
      token: "cms-admin",
      body: { titleEn: "A", titleAr: "أ" },
    });
    expect(blocked.status).toBe(403);

    const created = await apiRequest("POST", "/admin/news", {
      token: "news-admin",
      body: {
        titleEn: "Runway",
        titleAr: "عرض",
        summaryEn: "Highlights",
        summaryAr: "أبرز",
        bodyEn: "Full story",
        bodyAr: "قصة",
        isPublished: true,
        isFeatured: true,
      },
    });
    expect(created.status).toBe(201);
    const row = (await created.json()) as { id: string; isFeatured: boolean };
    expect(row.isFeatured).toBe(true);

    const list = await apiRequest("GET", "/admin/news", { token: "news-admin" });
    expect(list.status).toBe(200);
    const items = (await list.json()) as unknown[];
    expect(items.length).toBe(1);
  });

  it("enforces a single featured article", async () => {
    const first = await apiRequest("POST", "/admin/news", {
      token: "news-admin",
      body: {
        titleEn: "One",
        titleAr: "واحد",
        isPublished: true,
        isFeatured: true,
      },
    });
    const firstBody = (await first.json()) as { id: string };
    await apiRequest("POST", "/admin/news", {
      token: "news-admin",
      body: {
        titleEn: "Two",
        titleAr: "اثنان",
        isPublished: true,
        isFeatured: true,
      },
    });
    const featured = [...mockDb.fashionNews.values()].filter((n) => n.is_featured === 1);
    expect(featured.length).toBe(1);
    expect(featured[0]?.id).not.toBe(firstBody.id);
  });
});
