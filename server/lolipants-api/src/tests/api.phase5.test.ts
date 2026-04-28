import { beforeEach, describe, expect, it } from "vitest";
import app from "../index";

type Row = Record<string, unknown>;

// Minimal but expressive D1 stub supporting the queries that Phase 5
// endpoints (quote, queue, claim, advance) exercise. Patterns are matched
// by distinctive SQL fragments; anything unmatched returns null / [] so
// tests fail loudly rather than silently.
class MockDb {
  designs = new Map<string, Row>();
  orders = new Map<string, Row>();
  measurements: Row[] = [];
  payments = new Map<string, Row>();
  orderKeys = new Map<string, Row>(); // `${userId}:${key}` -> { order_id }
  statusHistory: Row[] = [];

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
    if (s.includes("FROM order_idempotency_keys")) {
      const row = this.db.orderKeys.get(`${b[0]}:${b[1]}`);
      if (!row) return null;
      return this.db.orders.get(String(row.order_id)) as T | null;
    }
    if (s.includes("fabric_quality, is_public FROM designs")) {
      const d = this.db.designs.get(String(b[0]));
      return (d
        ? {
            id: d.id,
            user_id: d.user_id,
            fabric_quality: d.fabric_quality ?? null,
            is_public: d.is_public ?? 0,
          }
        : null) as T | null;
    }
    if (s.includes("fabric_quality FROM designs")) {
      const d = this.db.designs.get(String(b[0]));
      return (d ? { id: d.id, user_id: d.user_id, fabric_quality: d.fabric_quality ?? null } : null) as T | null;
    }
    if (s.includes("FROM measurements WHERE user_id")) {
      return (this.db.measurements.find((m) => m.user_id === b[0]) ?? null) as T | null;
    }
    if (s.includes("id, user_id, total_price FROM orders")) {
      const o = this.db.orders.get(String(b[0]));
      return (o ? { id: o.id, user_id: o.user_id, total_price: o.total_price } : null) as T | null;
    }
    if (s.includes("id, tailor_id, status FROM orders")) {
      const o = this.db.orders.get(String(b[0]));
      return (o ? { id: o.id, tailor_id: o.tailor_id ?? null, status: o.status } : null) as T | null;
    }
    if (s.includes("id, user_id FROM orders")) {
      const o = this.db.orders.get(String(b[0]));
      return (o ? { id: o.id, user_id: o.user_id } : null) as T | null;
    }
    if (s.includes("SELECT id, status FROM orders")) {
      const o = this.db.orders.get(String(b[0]));
      return (o ? { id: o.id, status: o.status } : null) as T | null;
    }
    if (s.includes("SELECT status FROM orders")) {
      const o = this.db.orders.get(String(b[0]));
      return (o ? { status: o.status } : null) as T | null;
    }
    if (s.includes("SELECT * FROM orders WHERE id = ?")) {
      return (this.db.orders.get(String(b[0])) ?? null) as T | null;
    }
    if (s.includes("FROM payment_transactions WHERE id = ?")) {
      const p = this.db.payments.get(String(b[0]));
      return (p ?? null) as T | null;
    }
    return null;
  }

  async all() {
    const s = this.sql;
    const b = this.binds;
    if (s.includes("FROM orders WHERE (tailor_id IS NULL OR tailor_id = ?)")) {
      const tailor = String(b[0]);
      // remaining binds are the status IN list (when present)
      const statuses = b.slice(1).map(String);
      const filtered = Array.from(this.db.orders.values()).filter((o) => {
        const tailorOk = o.tailor_id == null || o.tailor_id === tailor;
        const statusOk = statuses.length === 0 || statuses.includes(String(o.status));
        return tailorOk && statusOk;
      });
      return { results: filtered };
    }
    if (s.includes("FROM orders WHERE user_id")) {
      const uid = String(b[0]);
      return {
        results: Array.from(this.db.orders.values()).filter((o) => o.user_id === uid),
      };
    }
    if (s.includes("FROM order_status_history")) {
      return {
        results: this.db.statusHistory.filter((h) => h.order_id === b[0]),
      };
    }
    return { results: [] };
  }

  async run() {
    const s = this.sql;
    const b = this.binds;
    if (s.includes("INSERT INTO orders")) {
      this.db.orders.set(String(b[0]), {
        id: b[0],
        user_id: b[1],
        design_id: b[2],
        designer_id: b[3] ?? null,
        status: "placed",
        delivery_address: b[4],
        delivery_city: b[5],
        delivery_phone: b[6],
        delivery_notes: b[7] ?? null,
        base_price: b[8],
        fabric_fee: b[9],
        delivery_fee: b[10],
        total_price: b[11],
        payment_token: b[12] ?? null,
        tailor_id: null,
      });
      return { success: true };
    }
    if (s.includes("INSERT INTO order_idempotency_keys")) {
      this.db.orderKeys.set(`${b[1]}:${b[2]}`, { order_id: b[3] });
      return { success: true };
    }
    if (s.includes("INSERT INTO order_status_history")) {
      this.db.statusHistory.push({ order_id: b[1], status: b[2], note: b[3] ?? null });
      return { success: true };
    }
    if (s.includes("INSERT INTO payment_transactions")) {
      this.db.payments.set(String(b[0]), {
        id: b[0],
        order_id: b[1],
        status: "requires_payment",
        amount: b[2],
      });
      return { success: true };
    }
    if (s.includes("UPDATE payment_transactions SET status")) {
      const row = this.db.payments.get(String(b[1]));
      if (row) this.db.payments.set(String(b[1]), { ...row, status: b[0] });
      return { success: true };
    }
    if (s.includes("UPDATE orders SET tailor_id")) {
      const row = this.db.orders.get(String(b[1]));
      if (row && (row.tailor_id == null || row.tailor_id === b[2])) {
        this.db.orders.set(String(b[1]), { ...row, tailor_id: b[0] });
      }
      return { success: true };
    }
    if (s.includes("UPDATE orders SET status = 'confirmed'")) {
      const row = this.db.orders.get(String(b[1]));
      if (row && row.status === "placed") {
        this.db.orders.set(String(b[1]), {
          ...row,
          status: "confirmed",
          payment_token: b[0],
        });
      }
      return { success: true };
    }
    if (s.includes("UPDATE orders SET status = ?")) {
      const row = this.db.orders.get(String(b[1]));
      if (row) this.db.orders.set(String(b[1]), { ...row, status: b[0] });
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
      const token = (req.headers.get("Authorization") ?? "").replace(
        "Bearer ",
        "",
      );
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
      if (token === "tailor-token" || token === "tailor-other") {
        return new Response(
          JSON.stringify({
            user: {
              id: token === "tailor-token" ? "tailor-1" : "tailor-2",
              role: "tailor",
              name: "Tailor",
              email: "t@example.com",
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
  TAP_SECRET_KEY: "test-tap",
  ONESIGNAL_API_KEY: "k",
  ONESIGNAL_APP_ID: "k",
  CLOUDFLARE_R2_BASE_URL: "https://files.example.com",
  ENVIRONMENT: "test",
} as const;

async function req(
  method: string,
  path: string,
  options: {
    token?: string;
    body?: unknown;
    headers?: Record<string, string>;
  } = {},
) {
  const headers = new Headers(options.headers);
  if (options.token) headers.set("Authorization", `Bearer ${options.token}`);
  if (options.body !== undefined) headers.set("Content-Type", "application/json");
  const request = new Request(`http://local${path}`, {
    method,
    headers,
    body: options.body !== undefined ? JSON.stringify(options.body) : undefined,
  });
  return app.fetch(request, env, {} as ExecutionContext);
}

async function placeOrder(
  token: string,
  opts: { idempotencyKey?: string; city?: string } = {},
) {
  return req("POST", "/orders", {
    token,
    headers: {
      "X-Idempotency-Key": opts.idempotencyKey ?? `k_${crypto.randomUUID()}`,
    },
    body: {
      designId: "design-1",
      deliveryAddress: "West Bay",
      deliveryCity: opts.city ?? "Doha",
      deliveryPhone: "55512345",
    },
  });
}

describe("Phase 5 contract tests", () => {
  beforeEach(() => {
    mockDb.designs.clear();
    mockDb.orders.clear();
    mockDb.measurements.length = 0;
    mockDb.payments.clear();
    mockDb.orderKeys.clear();
    mockDb.statusHistory.length = 0;

    mockDb.designs.set("design-1", {
      id: "design-1",
      user_id: "user-1",
      fabric_quality: "premium",
    });
    mockDb.measurements.push({
      id: "m-1",
      user_id: "user-1",
      chest: 100,
      waist: 80,
      height: 180,
    });
  });

  describe("GET /orders/quote", () => {
    it("returns the server-authoritative breakdown for Doha premium", async () => {
      const res = await req("GET", "/orders/quote?designId=design-1&city=Doha", {
        token: "customer-token",
      });
      expect(res.status).toBe(200);
      const body = (await res.json()) as Record<string, number>;
      expect(body.basePrice).toBe(350);
      expect(body.fabricFee).toBe(120);
      expect(body.deliveryFee).toBe(20);
      expect(body.total).toBe(490);
    });

    it("uses the non-Doha fee for other cities", async () => {
      const res = await req("GET", "/orders/quote?designId=design-1&city=Al-Wakrah", {
        token: "customer-token",
      });
      const body = (await res.json()) as Record<string, number>;
      expect(body.deliveryFee).toBe(25);
    });

    it("403s a quote for a design that is not owned by the caller", async () => {
      mockDb.designs.set("foreign-design", {
        id: "foreign-design",
        user_id: "someone-else",
        fabric_quality: null,
      });
      const res = await req("GET", "/orders/quote?designId=foreign-design&city=Doha", {
        token: "customer-token",
      });
      expect(res.status).toBe(403);
    });
  });

  describe("GET /orders/queue + POST /orders/:id/claim", () => {
    it("blocks customer-role tokens from the queue", async () => {
      const res = await req("GET", "/orders/queue", { token: "customer-token" });
      expect(res.status).toBe(403);
    });

    it("returns unassigned orders filtered by status and claims them atomically", async () => {
      const place = await placeOrder("customer-token");
      expect(place.status).toBe(201);

      const queue = await req(
        "GET",
        "/orders/queue?status=placed,confirmed",
        { token: "tailor-token" },
      );
      expect(queue.status).toBe(200);
      const rows = (await queue.json()) as Array<{ id: string }>;
      expect(rows).toHaveLength(1);

      const claim = await req("POST", `/orders/${rows[0].id}/claim`, {
        token: "tailor-token",
      });
      expect(claim.status).toBe(200);
      expect(mockDb.orders.get(rows[0].id)?.tailor_id).toBe("tailor-1");

      const conflict = await req("POST", `/orders/${rows[0].id}/claim`, {
        token: "tailor-other",
      });
      expect(conflict.status).toBe(409);
    });
  });

  describe("PATCH /orders/:id/status", () => {
    it("allows the happy-path cutting transition", async () => {
      const place = await placeOrder("customer-token");
      const created = (await place.json()) as { id: string };

      // Move to confirmed then cutting.
      const confirm = await req("PATCH", `/orders/${created.id}/status`, {
        token: "tailor-token",
        body: { status: "confirmed" },
      });
      expect(confirm.status).toBe(200);

      const cut = await req("PATCH", `/orders/${created.id}/status`, {
        token: "tailor-token",
        body: { status: "cutting" },
      });
      expect(cut.status).toBe(200);
    });

    it("rejects an invalid status transition with 409", async () => {
      const place = await placeOrder("customer-token");
      const created = (await place.json()) as { id: string };

      const res = await req("PATCH", `/orders/${created.id}/status`, {
        token: "tailor-token",
        body: { status: "delivered" },
      });
      expect(res.status).toBe(409);
    });
  });

  describe("POST /payments/intent idempotency + simulate", () => {
    it("reuses the same payment row for the same order across retries", async () => {
      const place = await placeOrder("customer-token");
      const created = (await place.json()) as { id: string };

      const first = await req("POST", "/payments/intent", {
        token: "customer-token",
        body: { orderId: created.id },
      });
      const intent = (await first.json()) as { paymentReference: string };

      const second = await req("POST", "/payments/intent", {
        token: "customer-token",
        body: { orderId: created.id },
      });
      expect(second.status).toBe(200);
      // The server overrides amount but reuses the same payment_transactions
      // row via ON CONFLICT; sandbox simulate must confirm exactly one order.
      const sandbox = await req("POST", "/payments/simulate", {
        token: "customer-token",
        body: { paymentReference: intent.paymentReference, outcome: "paid" },
      });
      expect(sandbox.status).toBe(200);
      expect(mockDb.orders.get(created.id)?.status).toBe("confirmed");
    });

    it("simulate with outcome=failed marks transaction failed without touching order", async () => {
      const place = await placeOrder("customer-token");
      const created = (await place.json()) as { id: string };

      const intent = (await (
        await req("POST", "/payments/intent", {
          token: "customer-token",
          body: { orderId: created.id },
        })
      ).json()) as { paymentReference: string };

      const sandbox = await req("POST", "/payments/simulate", {
        token: "customer-token",
        body: { paymentReference: intent.paymentReference, outcome: "failed" },
      });
      expect(sandbox.status).toBe(200);
      expect(mockDb.payments.get(intent.paymentReference)?.status).toBe("failed");
      expect(mockDb.orders.get(created.id)?.status).toBe("placed");
    });
  });
});
