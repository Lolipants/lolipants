/**
 * Role request intake: POST/GET /role-requests, admin list/approve.
 */
import { beforeEach, describe, expect, it } from "vitest";
import app from "../index";

type Row = Record<string, unknown>;

type UserRow = {
  id: string;
  name: string;
  email: string;
  role: string;
  admin_scopes: string | null;
  banned_at: string | null;
};

type RoleRequestRow = {
  id: string;
  user_id: string;
  requested_role: string;
  message: string | null;
  status: string;
  admin_note: string | null;
  created_at: string;
  resolved_at: string | null;
  resolved_by: string | null;
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
    this.db.run(this.sql, this.binds);
    return { success: true, meta: { changes: 1 } };
  }
}

class MockDb {
  users = new Map<string, UserRow>();
  roleRequests = new Map<string, RoleRequestRow>();

  prepare(sql: string) {
    return new MockPreparedStatement(this, sql);
  }

  select(sql: string, binds: unknown[]): Row[] {
    if (sql.includes("role_requests r") && sql.includes("JOIN users u")) {
      const out: Row[] = [];
      const statusFilter = sql.includes("WHERE r.status = ?");
      const st = statusFilter ? String(binds[0] ?? "") : "";
      for (const r of this.roleRequests.values()) {
        if (statusFilter && r.status !== st) continue;
        const u = this.users.get(r.user_id);
        if (!u) continue;
        out.push({
          ...r,
          requester_name: u.name,
          requester_email: u.email,
          requester_current_role: u.role,
        });
      }
      return out.sort(
        (a, b) =>
          String(b.created_at ?? "").localeCompare(String(a.created_at ?? "")),
      );
    }
    if (
      sql.includes("FROM role_requests") &&
      sql.includes("WHERE user_id = ?") &&
      sql.includes("ORDER BY")
    ) {
      const uid = String(binds[0] ?? "");
      return [...this.roleRequests.values()]
        .filter((r) => r.user_id === uid)
        .sort((a, b) => b.created_at.localeCompare(a.created_at));
    }
    return [];
  }

  first(sql: string, binds: unknown[]): Row | null {
    if (sql.includes("FROM users WHERE id = ?") && sql.includes("admin_scopes")) {
      const id = String(binds[0] ?? "");
      const u = this.users.get(id);
      if (!u) return null;
      return {
        role: u.role,
        admin_scopes: u.admin_scopes,
        banned_at: u.banned_at,
        id: u.id,
        name: u.name,
        email: u.email,
      };
    }
    if (sql.includes("SELECT id, role FROM users WHERE id = ?")) {
      const id = String(binds[0] ?? "");
      const u = this.users.get(id);
      if (!u) return null;
      return { id: u.id, role: u.role };
    }
    if (sql.includes("SELECT id, role, admin_scopes FROM users WHERE id = ?")) {
      const id = String(binds[0] ?? "");
      const u = this.users.get(id);
      if (!u) return null;
      return { id: u.id, role: u.role, admin_scopes: u.admin_scopes };
    }
    if (
      sql.includes("FROM role_requests") &&
      sql.includes("user_id = ?") &&
      sql.includes("pending")
    ) {
      const uid = String(binds[0] ?? "");
      for (const r of this.roleRequests.values()) {
        if (r.user_id === uid && r.status === "pending") return { id: r.id };
      }
      return null;
    }
    if (sql.includes("FROM role_requests WHERE id = ?") && !sql.includes("JOIN")) {
      return this.roleRequests.get(String(binds[0] ?? "")) ?? null;
    }
    if (sql.includes("FROM role_requests") && sql.includes("WHERE r.id = ?")) {
      const id = String(binds[0] ?? "");
      const r = this.roleRequests.get(id);
      if (!r) return null;
      const u = this.users.get(r.user_id);
      if (!u) return null;
      return { ...r, requester_name: u.name, requester_email: u.email };
    }
    return null;
  }

  run(sql: string, binds: unknown[]): void {
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
      return;
    }
    if (sql.startsWith("INSERT INTO role_requests")) {
      const id = String(binds[0]);
      const user_id = String(binds[1]);
      const requested_role = String(binds[2]);
      const message = binds[3] as string | null;
      this.roleRequests.set(id, {
        id,
        user_id,
        requested_role,
        message,
        status: "pending",
        admin_note: null,
        created_at: new Date().toISOString(),
        resolved_at: null,
        resolved_by: null,
      });
      return;
    }
    if (sql.startsWith("UPDATE users SET role = ?")) {
      const newRole = String(binds[0]);
      const id = String(binds[1]);
      const u = this.users.get(id);
      if (u) u.role = newRole;
      return;
    }
    if (sql.startsWith("UPDATE users SET") && sql.includes("excluded.name")) {
      return;
    }
    if (sql.startsWith("UPDATE role_requests")) {
      const id = String(binds[binds.length - 1]);
      const row = this.roleRequests.get(id);
      if (!row) return;
      if (sql.includes("status = ?") && sql.includes("resolved")) {
        row.status = String(binds[0]);
        row.admin_note = binds[1] as string | null;
        row.resolved_at = String(binds[2]);
        row.resolved_by = binds[3] as string | null;
      }
    }
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
    id: "u1",
    role: "user",
    name: "Regular",
    email: "u@e.com",
  },
  "admin-token": {
    id: "a1",
    role: "admin",
    name: "Admin",
    email: "a@e.com",
  },
};

function seed() {
  mockDb.users.set("u1", {
    id: "u1",
    name: "Regular",
    email: "u@e.com",
    role: "user",
    admin_scopes: null,
    banned_at: null,
  });
  mockDb.users.set("a1", {
    id: "a1",
    name: "Admin",
    email: "a@e.com",
    role: "admin",
    admin_scopes: JSON.stringify(["users_mgmt"]),
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

describe("role requests", () => {
  beforeEach(() => {
    mockDb.users.clear();
    mockDb.roleRequests.clear();
    seed();
  });

  it("creates a tailor request for a customer", async () => {
    const res = await apiRequest("POST", "/role-requests", {
      token: "user-token",
      body: { requestedRole: "tailor", message: "I sew well" },
    });
    expect(res.status).toBe(201);
    const body = (await res.json()) as { status: string; requestedRole: string };
    expect(body.status).toBe("pending");
    expect(body.requestedRole).toBe("tailor");
    expect([...mockDb.roleRequests.values()].length).toBe(1);
  });

  it("rejects a second request while one is pending", async () => {
    await apiRequest("POST", "/role-requests", {
      token: "user-token",
      body: { requestedRole: "tailor" },
    });
    const res = await apiRequest("POST", "/role-requests", {
      token: "user-token",
      body: { requestedRole: "delivery" },
    });
    expect(res.status).toBe(409);
  });

  it("lists mine", async () => {
    await apiRequest("POST", "/role-requests", {
      token: "user-token",
      body: { requestedRole: "delivery" },
    });
    const res = await apiRequest("GET", "/role-requests/mine", {
      token: "user-token",
    });
    expect(res.status).toBe(200);
    const rows = (await res.json()) as unknown[];
    expect(rows.length).toBe(1);
  });

  it("admin approves and updates user role", async () => {
    await apiRequest("POST", "/role-requests", {
      token: "user-token",
      body: { requestedRole: "tailor" },
    });
    const reqId = [...mockDb.roleRequests.keys()][0]!;
    const res = await apiRequest("PATCH", `/admin/role-requests/${reqId}`, {
      token: "admin-token",
      body: { status: "approved" },
    });
    expect(res.status).toBe(200);
    expect(mockDb.users.get("u1")?.role).toBe("tailor");
    expect(mockDb.roleRequests.get(reqId)?.status).toBe("approved");
  });
});
