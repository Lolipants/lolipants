import { beforeEach, describe, expect, it } from "vitest";
import app from "../index";
import { seedTailorPricingTables, withTailorOrderBody } from "./tailorOrderFixtures";
import {
  parseOrderInsertBinds,
  tailorMockFirst,
  tailorMockSelect,
} from "./tailorMockSql";

async function hmacSha256Hex(secret: string, payload: string): Promise<string> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    encoder.encode(payload),
  );
  return Array.from(new Uint8Array(signature))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

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

  async first<T>() {
    return this.db.first(this.sql, this.binds) as T | null;
  }

  async run() {
    this.db.run(this.sql, this.binds);
    return { success: true };
  }

  async all() {
    const tailorSelect = tailorMockSelect(this.db, this.sql, this.binds);
    if (tailorSelect != null) return { results: tailorSelect };
    return { results: [] };
  }
}

class MockDb {
  designs = new Map<string, Row>();
  orders = new Map<string, Row>();
  measurements: Row[] = [];
  paymentTransactions = new Map<string, Row>();
  orderKeys = new Map<string, Row>();
  users = new Map<string, Row>();
  tailorProfiles = new Map<string, Row>();
  tailorPlans = new Map<string, Row>();
  tailorGarmentPrices: Row[] = [];
  tailorDeliveryFees: Row[] = [];

  prepare(sql: string) {
    return new MockPreparedStatement(this, sql);
  }

  first(sql: string, binds: unknown[]) {
    if (sql.includes("SELECT o.* FROM order_idempotency_keys")) {
      const key = `${binds[0]}:${binds[1]}`;
      const match = this.orderKeys.get(key);
      if (!match) return null;
      return this.orders.get(String(match.order_id)) ?? null;
    }
    if (sql.includes("SELECT id, user_id, fabric_quality FROM designs WHERE id = ?")) {
      const design = this.designs.get(String(binds[0]));
      if (!design) return null;
      return {
        id: design.id,
        user_id: design.user_id,
        fabric_quality: design.fabric_quality ?? "standard",
      };
    }
    if (sql.includes("garment_type, fabric_quality, is_public FROM designs WHERE id = ?")) {
      const design = this.designs.get(String(binds[0]));
      if (!design) return null;
      return {
        id: design.id,
        user_id: design.user_id,
        garment_type: design.garment_type ?? "thobe",
        fabric_quality: design.fabric_quality ?? "standard",
        is_public: design.is_public ?? 0,
      };
    }
    if (sql.includes("SELECT id, user_id, fabric_quality, is_public FROM designs WHERE id = ?")) {
      const design = this.designs.get(String(binds[0]));
      if (!design) return null;
      return {
        id: design.id,
        user_id: design.user_id,
        fabric_quality: design.fabric_quality ?? "standard",
        is_public: design.is_public ?? 0,
      };
    }
    if (sql.includes("SELECT id FROM measurements WHERE user_id = ? ORDER BY saved_at DESC")) {
      const measurement = this.measurements.find((m) => m.user_id === binds[0]);
      if (!measurement) return null;
      return { id: measurement.id };
    }
    if (sql.includes("SELECT id, user_id, total_price FROM orders WHERE id = ?")) {
      const order = this.orders.get(String(binds[0]));
      if (!order) return null;
      return {
        id: order.id,
        user_id: order.user_id,
        total_price: order.total_price,
      };
    }
    if (sql.includes("SELECT * FROM orders WHERE id = ?")) {
      return this.orders.get(String(binds[0])) ?? null;
    }
    if (sql.includes("SELECT order_id FROM payment_transactions WHERE id = ?")) {
      const payment = this.paymentTransactions.get(String(binds[0]));
      if (!payment) return null;
      return { order_id: payment.order_id };
    }
    const tailorHit = tailorMockFirst(this, sql, binds);
    if (tailorHit !== undefined) return tailorHit;
    return null;
  }

  run(sql: string, binds: unknown[]) {
    if (sql.includes("INSERT INTO orders")) {
      this.orders.set(String(binds[0]), parseOrderInsertBinds(binds));
      return;
    }
    if (sql.includes("INSERT INTO order_idempotency_keys")) {
      this.orderKeys.set(`${binds[1]}:${binds[2]}`, {
        user_id: binds[1],
        idempotency_key: binds[2],
        order_id: binds[3],
      });
      return;
    }
    if (sql.includes("INSERT INTO payment_transactions")) {
      this.paymentTransactions.set(String(binds[0]), {
        id: binds[0],
        order_id: binds[1],
        status: "requires_payment",
        amount: binds[2],
      });
      return;
    }
    if (sql.includes("UPDATE payment_transactions SET status = ?")) {
      const current = this.paymentTransactions.get(String(binds[1]));
      if (!current) return;
      this.paymentTransactions.set(String(binds[1]), {
        ...current,
        status: binds[0],
      });
      return;
    }
    if (sql.includes("UPDATE orders SET status = 'confirmed'")) {
      const current = this.orders.get(String(binds[1]));
      if (!current) return;
      this.orders.set(String(binds[1]), {
        ...current,
        status: "confirmed",
        payment_token: binds[0],
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
      const token = (req.headers.get("Authorization") ?? "").replace("Bearer ", "");
      if (token === "valid-user") {
        return new Response(
          JSON.stringify({
            user: {
              id: "user-1",
              role: "user",
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
} as const;

async function apiRequest(
  method: string,
  path: string,
  options: { token?: string; body?: unknown; headers?: Record<string, string> } = {},
) {
  const headers = new Headers(options.headers);
  if (options.token) headers.set("Authorization", `Bearer ${options.token}`);
  if (options.body) headers.set("Content-Type", "application/json");
  const request = new Request(`http://local${path}`, {
    method,
    headers,
    body: options.body ? JSON.stringify(options.body) : undefined,
  });
  return app.fetch(request, env, {} as ExecutionContext);
}

describe("API contract tests", () => {
  beforeEach(() => {
    mockDb.designs.clear();
    mockDb.orders.clear();
    mockDb.measurements.length = 0;
    mockDb.paymentTransactions.clear();
    mockDb.orderKeys.clear();

    seedTailorPricingTables(mockDb);
    mockDb.designs.set("design-1", {
      id: "design-1",
      user_id: "user-1",
      garment_type: "thobe",
      fabric_quality: "premium",
    });
    mockDb.measurements.push({
      id: "measurement-1",
      user_id: "user-1",
      chest: 100,
      waist: 80,
      height: 180,
    });
  });

  it("reuses the same order for duplicate idempotent submits", async () => {
    const first = await apiRequest("POST", "/orders", {
      token: "valid-user",
      headers: { "X-Idempotency-Key": "repeat-order-1" },
      body: withTailorOrderBody(
        {
          designId: "design-1",
          deliveryAddress: "West Bay",
          deliveryCity: "Doha",
          deliveryPhone: "55512345",
        },
        { fabric: "premium" },
      ),
    });
    expect(first.status).toBe(201);
    const created = (await first.json()) as { id: string };

    const second = await apiRequest("POST", "/orders", {
      token: "valid-user",
      headers: { "X-Idempotency-Key": "repeat-order-1" },
      body: withTailorOrderBody(
        {
          designId: "design-1",
          deliveryAddress: "West Bay",
          deliveryCity: "Doha",
          deliveryPhone: "55512345",
        },
        { fabric: "premium" },
      ),
    });
    expect(second.status).toBe(200);
    const repeated = (await second.json()) as { id: string };
    expect(repeated.id).toBe(created.id);
  });

  it("creates payment intent and reconciles paid webhook", async () => {
    const createOrder = await apiRequest("POST", "/orders", {
      token: "valid-user",
      headers: { "X-Idempotency-Key": "pay-order-1" },
      body: withTailorOrderBody(
        {
          designId: "design-1",
          deliveryAddress: "West Bay",
          deliveryCity: "Doha",
          deliveryPhone: "55512345",
        },
        { fabric: "premium" },
      ),
    });
    const order = (await createOrder.json()) as { id: string };

    const intent = await apiRequest("POST", "/payments/intent", {
      token: "valid-user",
      body: { orderId: order.id },
    });
    expect(intent.status).toBe(200);
    const payment = (await intent.json()) as { paymentReference: string };

    const webhookBody = JSON.stringify({
      paymentReference: payment.paymentReference,
      status: "paid",
    });
    const signature = await hmacSha256Hex("test-tap", webhookBody);
    const webhook = await apiRequest("POST", "/payments/webhook/tap", {
      headers: { "x-tap-signature": signature },
      body: JSON.parse(webhookBody),
    });

    expect(webhook.status).toBe(200);
    expect(mockDb.orders.get(order.id)?.status).toBe("confirmed");
    expect(mockDb.paymentTransactions.get(payment.paymentReference)?.status).toBe("paid");
  });

  it("accepts tap charge payload shape in webhook", async () => {
    const createOrder = await apiRequest("POST", "/orders", {
      token: "valid-user",
      headers: { "X-Idempotency-Key": "pay-order-2" },
      body: withTailorOrderBody(
        {
          designId: "design-1",
          deliveryAddress: "West Bay",
          deliveryCity: "Doha",
          deliveryPhone: "55512345",
        },
        { fabric: "premium" },
      ),
    });
    const order = (await createOrder.json()) as { id: string };

    const intent = await apiRequest("POST", "/payments/intent", {
      token: "valid-user",
      body: { orderId: order.id },
    });
    expect(intent.status).toBe(200);
    const payment = (await intent.json()) as { paymentReference: string };

    const webhookBody = JSON.stringify({
      reference: { transaction: payment.paymentReference, order: order.id },
      status: "CAPTURED",
    });
    const signature = await hmacSha256Hex("test-tap", webhookBody);
    const webhook = await apiRequest("POST", "/payments/webhook/tap", {
      headers: { "x-tap-signature": signature },
      body: JSON.parse(webhookBody),
    });

    expect(webhook.status).toBe(200);
    expect(mockDb.orders.get(order.id)?.status).toBe("confirmed");
    expect(mockDb.paymentTransactions.get(payment.paymentReference)?.status).toBe("paid");
  });
});
