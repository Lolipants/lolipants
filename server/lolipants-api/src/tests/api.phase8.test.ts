/**
 * Phase 8 RBAC regression.
 *
 * Exercises the new /delivery and /admin surfaces with role and scope
 * enforcement. The mock D1 is aware of both the `users` table (so
 * requireAuth can resolve the authoritative role + admin_scopes) and the
 * tables touched by each endpoint.
 */
import { beforeEach, describe, expect, it } from "vitest";
import app from "../index";

type Row = Record<string, unknown>;

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

type UserRow = {
  id: string;
  name: string;
  email: string;
  role: string;
  admin_scopes: string | null;
  banned_at: string | null;
};

type OrderRow = {
  id: string;
  user_id: string;
  design_id: string | null;
  tailor_id: string | null;
  courier_id: string | null;
  status: string;
  delivery_proof_url: string | null;
  delivered_at: string | null;
};

class MockDb {
  users = new Map<string, UserRow>();
  orders = new Map<string, OrderRow>();
  designs = new Map<string, Row>();
  commissions = new Map<string, Row>();
  complaints = new Map<string, Row>();
  posts = new Map<string, Row>();
  mannequins = new Map<string, Row>();
  fabrics = new Map<string, Row>();
  presets = new Map<string, Row>();
  renderJobs: Row[] = [];

  prepare(sql: string) {
    return new MockPreparedStatement(this, sql);
  }

  select(sql: string, binds: unknown[]): Row[] {
    if (sql.includes("FROM users") && sql.includes("ORDER BY created_at DESC LIMIT 200")) {
      return [...this.users.values()];
    }
    if (sql.includes("FROM orders o") && sql.includes("courier_id IS NULL")) {
      return [...this.orders.values()].filter(
        (o) => o.status === "ready_to_ship" && !o.courier_id,
      );
    }
    if (sql.includes("FROM orders o") && sql.includes("courier_id = ?")) {
      const courierId = String(binds[0] ?? "");
      return [...this.orders.values()].filter(
        (o) => o.courier_id === courierId && o.status === "out_for_delivery",
      );
    }
    if (sql.includes("FROM orders o") && sql.includes("status = ?") && sql.includes("delivered")) {
      const courierId = String(binds[1] ?? "");
      return [...this.orders.values()].filter(
        (o) => o.courier_id === courierId && o.status === "delivered",
      );
    }
    if (sql.includes("FROM orders")) {
      return [...this.orders.values()];
    }
    if (sql.includes("FROM commissions")) {
      return [...this.commissions.values()];
    }
    if (sql.includes("FROM complaints")) {
      return [...this.complaints.values()];
    }
    if (sql.includes("FROM mannequin_options")) {
      return [...this.mannequins.values()];
    }
    if (sql.includes("FROM fabric_options")) {
      return [...this.fabrics.values()];
    }
    if (sql.includes("FROM presets WHERE type = 'pattern'")) {
      return [...this.presets.values()].filter((p) => p.type === "pattern");
    }
    if (sql.includes("FROM presets")) {
      return [...this.presets.values()];
    }
    if (sql.includes("GROUP BY role")) {
      const out = new Map<string, number>();
      for (const u of this.users.values()) {
        out.set(u.role, (out.get(u.role) ?? 0) + 1);
      }
      return [...out.entries()].map(([role, count]) => ({ role, count }));
    }
    if (sql.includes("GROUP BY status") && sql.includes("FROM orders")) {
      const out = new Map<string, number>();
      for (const o of this.orders.values()) {
        out.set(o.status, (out.get(o.status) ?? 0) + 1);
      }
      return [...out.entries()].map(([status, count]) => ({ status, count }));
    }
    if (sql.includes("GROUP BY status") && sql.includes("FROM commissions")) {
      return [];
    }
    if (sql.includes("FROM design_render_jobs")) {
      return this.renderJobs;
    }
    return [];
  }

  first(sql: string, binds: unknown[]): Row | null {
    if (sql.includes("FROM users WHERE id = ?") && sql.includes("role")) {
      const id = String(binds[0] ?? "");
      const user = this.users.get(id);
      if (!user) return null;
      return {
        role: user.role,
        admin_scopes: user.admin_scopes,
        banned_at: user.banned_at,
        id: user.id,
        name: user.name,
        email: user.email,
      };
    }
    if (sql.includes("FROM orders WHERE id = ?")) {
      const id = String(binds[0] ?? "");
      return this.orders.get(id) ?? null;
    }
    if (sql.includes("FROM commissions WHERE id = ?")) {
      const id = String(binds[0] ?? "");
      return this.commissions.get(id) ?? null;
    }
    if (sql.includes("FROM complaints WHERE id = ?")) {
      const id = String(binds[0] ?? "");
      return this.complaints.get(id) ?? null;
    }
    if (sql.includes("FROM posts WHERE id = ?")) {
      const id = String(binds[0] ?? "");
      return this.posts.get(id) ?? null;
    }
    if (sql.includes("FROM mannequin_options WHERE id = ?")) {
      return this.mannequins.get(String(binds[0] ?? "")) ?? null;
    }
    if (sql.includes("FROM fabric_options WHERE id = ?")) {
      return this.fabrics.get(String(binds[0] ?? "")) ?? null;
    }
    if (sql.includes("FROM presets WHERE id = ?")) {
      return this.presets.get(String(binds[0] ?? "")) ?? null;
    }
    if (sql.includes("COUNT(*)") && sql.includes("complaints")) {
      return { count: 0 };
    }
    return null;
  }

  run(sql: string, binds: unknown[]): { changes: number } {
    if (sql.includes("INSERT INTO users")) {
      const id = String(binds[0]);
      if (!this.users.has(id)) {
        this.users.set(id, {
          id,
          name: String(binds[1] ?? ""),
          email: String(binds[2] ?? ""),
          role: String(binds[3] ?? "user"),
          admin_scopes: null,
          banned_at: null,
        });
      }
      return { changes: 1 };
    }
    if (sql.startsWith("UPDATE users")) {
      const id = String(binds[binds.length - 1]);
      const existing = this.users.get(id);
      if (!existing) return { changes: 0 };
      if (sql.includes("role = ?")) {
        existing.role = String(binds[0]);
      }
      if (sql.includes("admin_scopes = ?")) {
        existing.admin_scopes = binds[sql.split(",").findIndex((p) => p.includes("admin_scopes"))] as string;
      }
      if (sql.includes("banned_at = ?")) {
        existing.banned_at = binds[sql.split(",").findIndex((p) => p.includes("banned_at"))] as string | null;
      }
      return { changes: 1 };
    }
    if (
      sql.startsWith("UPDATE orders") &&
      sql.includes("courier_id = ?") &&
      sql.includes("AND status = ?")
    ) {
      const status = String(binds[0]);
      const courierId = String(binds[1]);
      const id = String(binds[2]);
      const expectedStatus = String(binds[4]);
      const existing = this.orders.get(id);
      if (!existing) return { changes: 0 };
      if (existing.status !== expectedStatus) return { changes: 0 };
      if (existing.courier_id && existing.courier_id !== courierId) {
        return { changes: 0 };
      }
      existing.status = status;
      existing.courier_id = courierId;
      return { changes: 1 };
    }
    if (
      sql.startsWith("UPDATE orders") &&
      sql.includes("courier_id = ?") &&
      sql.includes("courier_id IS NULL")
    ) {
      const courierId = String(binds[0]);
      const id = String(binds[1]);
      const existing = this.orders.get(id);
      if (!existing) return { changes: 0 };
      if (existing.courier_id && existing.courier_id !== courierId) {
        return { changes: 0 };
      }
      existing.courier_id = courierId;
      return { changes: 1 };
    }
    if (sql.startsWith("UPDATE orders SET status")) {
      const id = String(binds[binds.length - 1]);
      const existing = this.orders.get(id);
      if (!existing) return { changes: 0 };
      existing.status = String(binds[0]);
      return { changes: 1 };
    }
    if (sql.startsWith("UPDATE orders")) {
      return { changes: 1 };
    }
    if (sql.startsWith("DELETE FROM posts")) {
      this.posts.delete(String(binds[0]));
      return { changes: 1 };
    }
    if (sql.includes("INSERT INTO order_status_history")) {
      return { changes: 1 };
    }
    if (sql.startsWith("INSERT INTO mannequin_options")) {
      const id = String(binds[0]);
      this.mannequins.set(id, { id, label_en: binds[1], label_ar: binds[2] });
      return { changes: 1 };
    }
    if (sql.startsWith("UPDATE mannequin_options")) {
      const id = String(binds[binds.length - 1]);
      const existing = this.mannequins.get(id);
      if (!existing) return { changes: 0 };
      this.mannequins.set(id, { ...existing });
      return { changes: 1 };
    }
    if (sql.startsWith("DELETE FROM mannequin_options")) {
      this.mannequins.delete(String(binds[0]));
      return { changes: 1 };
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
      const url = new URL(req.url);
      if (url.pathname.startsWith("/internal/")) {
        return new Response("ok", { status: 200 });
      }
      const token =
        req.headers.get("Authorization")?.replace("Bearer ", "") ?? "";
      const who = TOKENS[token];
      if (!who) return new Response("unauthorized", { status: 401 });
      return new Response(
        JSON.stringify({
          user: {
            id: who.id,
            role: who.role,
            name: who.name,
            email: who.email,
          },
        }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      );
    },
  } as Fetcher,
  BETTER_AUTH_BASE_URL: "https://auth.local",
  INTERNAL_SYNC_SECRET: "test-sync",
  ENVIRONMENT: "test",
} as unknown as Parameters<typeof app.fetch>[1];

type TokenRecord = { id: string; role: string; name: string; email: string };
const TOKENS: Record<string, TokenRecord> = {
  "user-token": {
    id: "user-1",
    role: "user",
    name: "Regular",
    email: "user@example.com",
  },
  "courier-token": {
    id: "courier-1",
    role: "delivery",
    name: "Courier",
    email: "courier@example.com",
  },
  "admin-scoped": {
    id: "admin-1",
    role: "admin",
    name: "Scoped",
    email: "scoped@example.com",
  },
  "admin-super": {
    id: "admin-2",
    role: "admin",
    name: "Super",
    email: "super@example.com",
  },
};

function seedUsers() {
  mockDb.users.set("user-1", {
    id: "user-1",
    role: "user",
    name: "Regular",
    email: "user@example.com",
    admin_scopes: null,
    banned_at: null,
  });
  mockDb.users.set("courier-1", {
    id: "courier-1",
    role: "delivery",
    name: "Courier",
    email: "courier@example.com",
    admin_scopes: null,
    banned_at: null,
  });
  mockDb.users.set("admin-1", {
    id: "admin-1",
    role: "admin",
    name: "Scoped",
    email: "scoped@example.com",
    admin_scopes: JSON.stringify(["users_mgmt"]),
    banned_at: null,
  });
  mockDb.users.set("admin-2", {
    id: "admin-2",
    role: "admin",
    name: "Super",
    email: "super@example.com",
    admin_scopes: JSON.stringify(["*"]),
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
  const request = new Request(`http://local${path}`, {
    method,
    headers,
    body: options.body ? JSON.stringify(options.body) : undefined,
  });
  return app.fetch(request, env, {} as ExecutionContext);
}

describe("phase 8 / delivery RBAC", () => {
  beforeEach(() => {
    mockDb.users.clear();
    mockDb.orders.clear();
    mockDb.renderJobs = [];
    seedUsers();
  });

  it("blocks non-delivery roles from the queue", async () => {
    const response = await apiRequest("GET", "/delivery/queue", {
      token: "user-token",
    });
    expect(response.status).toBe(403);
  });

  it("lets couriers list their queue", async () => {
    mockDb.orders.set("order-1", {
      id: "order-1",
      user_id: "user-1",
      design_id: null,
      tailor_id: null,
      courier_id: null,
      status: "ready_to_ship",
      delivery_proof_url: null,
      delivered_at: null,
    });
    const response = await apiRequest("GET", "/delivery/queue", {
      token: "courier-token",
    });
    expect(response.status).toBe(200);
    const rows = (await response.json()) as unknown[];
    expect(rows.length).toBe(1);
  });

  it("lets a courier claim a ready order", async () => {
    mockDb.orders.set("order-1", {
      id: "order-1",
      user_id: "user-1",
      design_id: null,
      tailor_id: null,
      courier_id: null,
      status: "ready_to_ship",
      delivery_proof_url: null,
      delivered_at: null,
    });
    const response = await apiRequest("POST", "/delivery/orders/order-1/claim", {
      token: "courier-token",
    });
    expect(response.status).toBe(200);
    expect(mockDb.orders.get("order-1")?.courier_id).toBe("courier-1");
  });

  it("lets a courier mark picked up when tailor pre-assigned them", async () => {
    mockDb.orders.set("order-2", {
      id: "order-2",
      user_id: "user-1",
      design_id: null,
      tailor_id: null,
      courier_id: "courier-1",
      status: "ready_to_ship",
      delivery_proof_url: null,
      delivered_at: null,
    });
    const response = await apiRequest(
      "PATCH",
      "/delivery/orders/order-2/status",
      {
        token: "courier-token",
        body: { status: "out_for_delivery" },
      },
    );
    expect(response.status).toBe(200);
    expect(mockDb.orders.get("order-2")?.status).toBe("out_for_delivery");
  });

  it("claims on pickup when the order is still unassigned", async () => {
    mockDb.orders.set("order-3", {
      id: "order-3",
      user_id: "user-1",
      design_id: null,
      tailor_id: null,
      courier_id: null,
      status: "ready_to_ship",
      delivery_proof_url: null,
      delivered_at: null,
    });
    const response = await apiRequest(
      "PATCH",
      "/delivery/orders/order-3/status",
      {
        token: "courier-token",
        body: { status: "out_for_delivery" },
      },
    );
    expect(response.status).toBe(200);
    const row = mockDb.orders.get("order-3");
    expect(row?.courier_id).toBe("courier-1");
    expect(row?.status).toBe("out_for_delivery");
  });
});

describe("phase 8 / admin RBAC", () => {
  beforeEach(() => {
    mockDb.users.clear();
    mockDb.orders.clear();
    seedUsers();
  });

  it("blocks non-admin roles", async () => {
    const response = await apiRequest("GET", "/admin/stats", {
      token: "user-token",
    });
    expect(response.status).toBe(403);
  });

  it("lets super admins into every area without explicit scope", async () => {
    const response = await apiRequest("GET", "/admin/orders", {
      token: "admin-super",
    });
    expect(response.status).toBe(200);
  });

  it("enforces scoped access for regular admins", async () => {
    const blocked = await apiRequest("GET", "/admin/orders", {
      token: "admin-scoped",
    });
    expect(blocked.status).toBe(403);

    const allowed = await apiRequest("GET", "/admin/users", {
      token: "admin-scoped",
    });
    expect(allowed.status).toBe(200);
  });

  it("allows any admin to see dashboard stats", async () => {
    const response = await apiRequest("GET", "/admin/stats", {
      token: "admin-scoped",
    });
    expect(response.status).toBe(200);
    const body = (await response.json()) as { usersByRole: unknown[] };
    expect(Array.isArray(body.usersByRole)).toBe(true);
  });

  it("rejects invalid admin status updates", async () => {
    mockDb.orders.set("order-1", {
      id: "order-1",
      user_id: "user-1",
      design_id: null,
      tailor_id: null,
      courier_id: null,
      status: "placed",
      delivery_proof_url: null,
      delivered_at: null,
    });
    const response = await apiRequest("PATCH", "/admin/orders/order-1", {
      token: "admin-super",
      body: { status: "in_production" },
    });
    expect(response.status).toBe(400);
  });

  it("rejects invalid admin status transitions", async () => {
    mockDb.orders.set("order-2", {
      id: "order-2",
      user_id: "user-1",
      design_id: null,
      tailor_id: null,
      courier_id: null,
      status: "placed",
      delivery_proof_url: null,
      delivered_at: null,
    });
    const response = await apiRequest("PATCH", "/admin/orders/order-2", {
      token: "admin-super",
      body: { status: "ready_to_ship" },
    });
    expect(response.status).toBe(409);
  });

  it("returns render diagnostics metrics for admins", async () => {
    const now = Date.now();
    mockDb.renderJobs = [
      {
        status: "completed",
        provider_status: "completed",
        error_message: null,
        created_at: new Date(now - 12_000).toISOString(),
        completed_at: new Date(now - 2_000).toISOString(),
        failed_at: null,
        attempt_count: 1,
      },
      {
        status: "failed",
        provider_status: "failed",
        error_message: "provider unavailable (503)",
        created_at: new Date(now - 20_000).toISOString(),
        completed_at: null,
        failed_at: new Date(now - 15_000).toISOString(),
        attempt_count: 2,
      },
    ];
    const response = await apiRequest("GET", "/admin/render-metrics", {
      token: "admin-super",
    });
    expect(response.status).toBe(200);
    const body = (await response.json()) as {
      totalJobs: number;
      p50LatencyMs: number;
      failuresByCategory: Record<string, number>;
      retries: { jobsWithRetry: number };
    };
    expect(body.totalJobs).toBe(2);
    expect(body.p50LatencyMs).toBeGreaterThan(0);
    expect(body.failuresByCategory.provider_5xx).toBe(1);
    expect(body.retries.jobsWithRetry).toBe(1);
  });
});
