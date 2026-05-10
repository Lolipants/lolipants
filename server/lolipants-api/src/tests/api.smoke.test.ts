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

  async all() {
    return { results: this.db.select(this.sql, this.binds) };
  }

  async first<T>() {
    return this.db.first(this.sql, this.binds) as T | null;
  }

  async run() {
    this.db.run(this.sql, this.binds);
    return { success: true };
  }
}

class MockDb {
  designs = new Map<string, Row>();
  orders = new Map<string, Row>();
  measurements: Row[] = [];
  posts = new Map<string, Row>();

  prepare(sql: string) {
    return new MockPreparedStatement(this, sql);
  }

  select(sql: string, binds: unknown[]) {
    if (sql.includes("FROM designs WHERE user_id = ?")) {
      const userId = String(binds[0] ?? "");
      return [...this.designs.values()].filter((d) => d.user_id === userId);
    }
    if (sql.includes("FROM orders WHERE user_id = ? ORDER BY")) {
      const userId = String(binds[0] ?? "");
      return [...this.orders.values()].filter((o) => o.user_id === userId);
    }
    if (sql.includes("FROM order_status_history")) {
      return [];
    }
    if (sql.includes("SELECT * FROM posts")) {
      return [...this.posts.values()];
    }
    if (sql.includes("FROM fabric_options")) {
      return [{ id: "fab-1", name: "Cotton", garment_type: "all", quality: "standard" }];
    }
    if (sql.includes("FROM presets")) {
      return [{ id: "preset-1", type: "style", garment_type: null }];
    }
    if (sql.includes("FROM mannequin_options")) {
      return [
        {
          id: "standard_male",
          label_en: "Standard (Male)",
          label_ar: "رجالي قياسي",
          preview_url: null,
        },
      ];
    }
    return [];
  }

  first(sql: string, binds: unknown[]) {
    if (sql.includes("SELECT * FROM designs WHERE id = ?")) {
      return this.designs.get(String(binds[0] ?? "")) ?? null;
    }
    if (sql.includes("SELECT * FROM designs WHERE id = ? AND user_id = ?")) {
      const design = this.designs.get(String(binds[0] ?? ""));
      if (!design || design.user_id !== binds[1]) return null;
      return design;
    }
    if (sql.includes("SELECT id, user_id, fabric_quality FROM designs WHERE id = ?")) {
      const design = this.designs.get(String(binds[0] ?? ""));
      if (!design) return null;
      return {
        id: design.id,
        user_id: design.user_id,
        fabric_quality: design.fabric_quality ?? "standard",
      };
    }
    if (sql.includes("SELECT id, user_id, fabric_quality, is_public FROM designs WHERE id = ?")) {
      const design = this.designs.get(String(binds[0] ?? ""));
      if (!design) return null;
      return {
        id: design.id,
        user_id: design.user_id,
        fabric_quality: design.fabric_quality ?? "standard",
        is_public: design.is_public ?? 0,
      };
    }
    if (sql.includes("SELECT id FROM measurements WHERE user_id = ? ORDER BY saved_at DESC")) {
      const userId = String(binds[0] ?? "");
      const measurement = this.measurements.find((m) => m.user_id === userId);
      if (!measurement) return null;
      return { id: measurement.id };
    }
    if (sql.includes("SELECT * FROM orders WHERE id = ? AND user_id = ?")) {
      const order = this.orders.get(String(binds[0] ?? ""));
      if (!order || order.user_id !== binds[1]) return null;
      return order;
    }
    if (sql.includes("SELECT id, status FROM orders WHERE id = ? AND user_id = ?")) {
      const order = this.orders.get(String(binds[0] ?? ""));
      if (!order || order.user_id !== binds[1]) return null;
      return { id: order.id, status: order.status };
    }
    if (sql.includes("SELECT status FROM orders WHERE id = ?")) {
      const order = this.orders.get(String(binds[0] ?? ""));
      if (!order) return null;
      return { status: order.status };
    }
    if (sql.includes("SELECT * FROM orders WHERE id = ?")) {
      return this.orders.get(String(binds[0] ?? "")) ?? null;
    }
    if (sql.includes("SELECT * FROM measurements WHERE user_id = ?")) {
      const userId = String(binds[0] ?? "");
      return this.measurements.find((m) => m.user_id === userId) ?? null;
    }
    if (sql.includes("SELECT * FROM measurements WHERE id = ?")) {
      const id = String(binds[0] ?? "");
      return this.measurements.find((m) => m.id === id) ?? null;
    }
    if (sql.includes("SELECT * FROM posts WHERE id = ?")) {
      return this.posts.get(String(binds[0] ?? "")) ?? null;
    }
    if (sql.includes("SELECT id FROM users WHERE id = ?")) {
      return { id: binds[0] };
    }
    if (sql.includes("SELECT follower_count FROM users WHERE id = ?")) {
      return { follower_count: 1 };
    }
    return null;
  }

  run(sql: string, binds: unknown[]) {
    if (sql.includes("INSERT INTO designs")) {
      this.designs.set(String(binds[0]), {
        id: binds[0],
        user_id: binds[1],
        name: binds[2],
        garment_type: binds[3],
      });
      return;
    }
    if (sql.includes("UPDATE designs SET")) {
      const id = String(binds[12]);
      const existing = this.designs.get(id);
      if (!existing) return;
      this.designs.set(id, { ...existing, name: binds[0], garment_type: binds[1] });
      return;
    }
    if (sql.includes("INSERT INTO orders")) {
      this.orders.set(String(binds[0]), {
        id: binds[0],
        user_id: binds[1],
        design_id: binds[2],
        status: "placed",
      });
      return;
    }
    if (sql.includes("UPDATE orders SET status = 'cancelled'")) {
      const id = String(binds[0]);
      const order = this.orders.get(id);
      if (!order) return;
      this.orders.set(id, { ...order, status: "cancelled" });
      return;
    }
    if (sql.includes("UPDATE orders SET status = ?")) {
      const id = String(binds[1]);
      const order = this.orders.get(id);
      if (!order) return;
      this.orders.set(id, { ...order, status: binds[0] });
      return;
    }
    if (sql.includes("INSERT INTO measurements")) {
      this.measurements.push({
        id: binds[0],
        user_id: binds[1],
        chest: binds[2],
        waist: binds[3],
      });
      return;
    }
    if (sql.includes("INSERT INTO posts")) {
      this.posts.set(String(binds[0]), {
        id: binds[0],
        author_id: binds[1],
        body: binds[2],
      });
      return;
    }
  }
}

const mockDb = new MockDb();

const env = {
  DB: mockDb as unknown as D1Database,
  R2: { put: async () => undefined } as unknown as R2Bucket,
  AUTH_SERVICE: {
    fetch: async (req: Request) => {
      const authHeader = req.headers.get("Authorization") ?? "";
      const token = authHeader.replace("Bearer ", "");
      if (token === "valid-user" || token === "valid-tailor") {
        const role = token === "valid-tailor" ? "tailor" : "user";
        return new Response(
          JSON.stringify({
            user: {
              id: "user-1",
              role,
              name: "Test User",
              email: "test@example.com",
            },
          }),
          { status: 200, headers: { "Content-Type": "application/json" } },
        );
      }
      return new Response("unauthorized", { status: 401 });
    },
  } as Fetcher,
  BETTER_AUTH_BASE_URL: "https://auth.local",
  OPENAI_API_KEY: "test-key",
  TAP_SECRET_KEY: "test-tap",
  ONESIGNAL_API_KEY: "test-os",
  ONESIGNAL_APP_ID: "test-app",
  CLOUDFLARE_R2_BASE_URL: "https://files.example.com",
  ENVIRONMENT: "test",
};

async function apiRequest(
  method: string,
  path: string,
  options: {
    token?: string;
    body?: unknown;
    formData?: FormData;
    idempotencyKey?: string;
  } = {},
) {
  const headers = new Headers();
  if (options.token) headers.set("Authorization", `Bearer ${options.token}`);
  if (options.body) headers.set("Content-Type", "application/json");
  if (options.idempotencyKey) {
    headers.set("X-Idempotency-Key", options.idempotencyKey);
  }
  const request = new Request(`http://local${path}`, {
    method,
    headers,
    body: options.formData ?? (options.body ? JSON.stringify(options.body) : undefined),
  });
  return app.fetch(request, env, {} as ExecutionContext);
}

function assertErrorContract(payload: unknown, status: number) {
  const body = payload as { error?: { code?: string; message?: string; status?: number } };
  expect(body.error).toBeDefined();
  expect(typeof body.error?.code).toBe("string");
  expect(typeof body.error?.message).toBe("string");
  expect(body.error?.status).toBe(status);
}

describe("API auth + role guard", () => {
  it("returns contract error for unauthenticated protected routes", async () => {
    const response = await apiRequest("GET", "/orders");
    expect(response.status).toBe(401);
    assertErrorContract(await response.json(), 401);
  });

  it("blocks non-tailor role and allows tailor role", async () => {
    mockDb.designs.set("design-1", { id: "design-1", user_id: "user-1" });
    mockDb.measurements.push({ id: "m-1", user_id: "user-1", chest: 100, waist: 80 });
    const create = await apiRequest("POST", "/orders", {
      token: "valid-user",
      idempotencyKey: "order-role-1",
      body: {
        designId: "design-1",
        deliveryAddress: "West Bay",
        deliveryCity: "Doha",
        deliveryPhone: "55512345",
      },
    });
    expect(create.status).toBe(201);
    const created = (await create.json()) as { id: string };

    const forbidden = await apiRequest("PATCH", `/orders/${created.id}/status`, {
      token: "valid-user",
      body: { status: "confirmed" },
    });
    expect(forbidden.status).toBe(403);
    assertErrorContract(await forbidden.json(), 403);

    const allowed = await apiRequest("PATCH", `/orders/${created.id}/status`, {
      token: "valid-tailor",
      body: { status: "confirmed" },
    });
    expect(allowed.status).toBe(200);
  });
});

describe("API smoke tests for CRUD flows", () => {
  beforeEach(() => {
    mockDb.designs.clear();
    mockDb.orders.clear();
    mockDb.measurements.length = 0;
    mockDb.posts.clear();
  });

  it("smokes designs, orders, measurements, posts, and community flows", async () => {
    const designCreate = await apiRequest("POST", "/designs", {
      token: "valid-user",
      body: { name: "Smoke", garmentType: "thobe" },
    });
    expect(designCreate.status).toBe(201);
    const design = (await designCreate.json()) as { id: string };

    const designList = await apiRequest("GET", "/designs", { token: "valid-user" });
    expect(designList.status).toBe(200);

    const designPatch = await apiRequest("PATCH", `/designs/${design.id}`, {
      token: "valid-user",
      body: { name: "Updated Smoke" },
    });
    expect(designPatch.status).toBe(200);

    expect((await apiRequest("POST", "/measurements", {
      token: "valid-user",
      body: { chest: 99, waist: 81, height: 180 },
    })).status).toBe(201);

    const orderCreate = await apiRequest("POST", "/orders", {
      token: "valid-user",
      idempotencyKey: "order-smoke-1",
      body: {
        designId: design.id,
        deliveryAddress: "West Bay",
        deliveryCity: "Doha",
        deliveryPhone: "55512345",
      },
    });
    expect(orderCreate.status).toBe(201);
    const order = (await orderCreate.json()) as { id: string };

    expect((await apiRequest("GET", "/orders", { token: "valid-user" })).status).toBe(200);
    expect((await apiRequest("GET", `/orders/${order.id}`, { token: "valid-user" })).status).toBe(200);
    expect((await apiRequest("DELETE", `/orders/${order.id}`, { token: "valid-user" })).status).toBe(200);

    expect((await apiRequest("GET", "/measurements/me", { token: "valid-user" })).status).toBe(200);

    expect((await apiRequest("POST", "/posts", {
      token: "valid-user",
      body: { body: "Hello community" },
    })).status).toBe(201);
    expect((await apiRequest("GET", "/posts", { token: "valid-user" })).status).toBe(200);

    expect((await apiRequest("POST", "/community/consultations", {
      token: "valid-user",
      body: { garmentType: "thobe", description: "Need help" },
    })).status).toBe(201);
    expect((await apiRequest("POST", "/community/follow/designer-1", { token: "valid-user" })).status).toBe(200);
    expect((await apiRequest("DELETE", "/community/follow/designer-1", { token: "valid-user" })).status).toBe(200);
  });

  it("smokes booking, user token, public presets/fabrics and upload validation", async () => {
    expect((await apiRequest("POST", "/bookings", {
      token: "valid-user",
      body: { date: "2026-05-01", timeSlot: "morning" },
    })).status).toBe(201);

    expect((await apiRequest("POST", "/users/push-token", {
      token: "valid-user",
      body: { oneSignalId: "os-123" },
    })).status).toBe(200);

    expect((await apiRequest("GET", "/fabrics")).status).toBe(200);
    expect((await apiRequest("GET", "/presets")).status).toBe(200);
    expect((await apiRequest("GET", "/mannequins", { token: "valid-user" })).status).toBe(200);

    const uploadBad = await apiRequest("POST", "/upload", {
      token: "valid-user",
      formData: new FormData(),
    });
    expect(uploadBad.status).toBe(400);
    assertErrorContract(await uploadBad.json(), 400);
  });
});

describe("API error contract consistency", () => {
  it("returns consistent error body for 400/401/403/404", async () => {
    const unauth = await apiRequest("GET", "/orders");
    expect(unauth.status).toBe(401);
    assertErrorContract(await unauth.json(), 401);

    const badRequest = await apiRequest("POST", "/orders", {
      token: "valid-user",
      body: {},
    });
    expect(badRequest.status).toBe(400);
    assertErrorContract(await badRequest.json(), 400);

    const forbidden = await apiRequest("PATCH", "/orders/non-existent/status", {
      token: "valid-user",
      body: { status: "in_progress" },
    });
    expect(forbidden.status).toBe(403);
    assertErrorContract(await forbidden.json(), 403);

    const notFound = await apiRequest("GET", "/orders/non-existent", {
      token: "valid-user",
    });
    expect(notFound.status).toBe(404);
    assertErrorContract(await notFound.json(), 404);

    const mannequinDisabled = await apiRequest("POST", "/ai/mannequin", {
      token: "valid-user",
      formData: new FormData(),
    });
    expect(mannequinDisabled.status).toBe(503);
    assertErrorContract(await mannequinDisabled.json(), 503);
  });
});
