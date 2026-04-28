import { beforeEach, describe, expect, it } from "vitest";
import app from "../index";

type Row = Record<string, unknown>;

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

// Phase 6 MockDb: models only the queries the community/showcase/designers
// /admin endpoints exercise, plus the orders write path that inserts a
// commission when a non-owned public design is ordered.
class MockDb {
  users = new Map<string, Row>();
  designs = new Map<string, Row>();
  orders = new Map<string, Row>();
  orderKeys = new Map<string, Row>();
  measurements: Row[] = [];
  posts = new Map<string, Row>();
  postReactions: Row[] = [];
  postComments: Row[] = [];
  follows: Row[] = [];
  commissions = new Map<string, Row>();
  consultations = new Map<string, Row>();

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

    // Posts
    if (s.includes("FROM posts p") && s.includes("WHERE p.id = ?")) {
      const post = this.db.posts.get(String(b[1]));
      if (!post) return null;
      return shapePostRow(this.db, post, String(b[0])) as T;
    }
    if (s.includes("SELECT id FROM posts WHERE id = ?")) {
      const p = this.db.posts.get(String(b[0]));
      return (p ? { id: p.id } : null) as T | null;
    }
    if (s.includes("SELECT reaction_count FROM posts WHERE id = ?")) {
      const p = this.db.posts.get(String(b[0]));
      return (p ? { reaction_count: p.reaction_count ?? 0 } : null) as T | null;
    }
    if (s.includes("SELECT id, reaction_type FROM post_reactions")) {
      const found = this.db.postReactions.find(
        (r) => r.post_id === b[0] && r.user_id === b[1],
      );
      return (found
        ? { id: found.id, reaction_type: found.reaction_type }
        : null) as T | null;
    }
    if (
      s.includes("FROM posts p") &&
      s.includes("WHERE p.id = ?") === false &&
      s.includes("LIMIT ?")
    ) {
      // feed: handled in all() for results
      return null;
    }

    // Comments created row
    if (s.includes("FROM post_comments c") && s.includes("WHERE c.id = ?")) {
      const comment = this.db.postComments.find((x) => x.id === b[0]);
      if (!comment) return null;
      const author = this.db.users.get(String(comment.author_id));
      return {
        id: comment.id,
        post_id: comment.post_id,
        author_id: comment.author_id,
        body: comment.body,
        created_at: comment.created_at,
        author_name: author?.name ?? null,
        author_avatar_url: author?.avatar_url ?? null,
        author_is_pro_designer: author?.is_pro_designer ?? null,
      } as T;
    }

    // Designers / users
    if (
      s.includes("SELECT id, name, email, avatar_url, bio, speciality, follower_count, is_pro_designer")
    ) {
      const u = this.db.users.get(String(b[0]));
      return (u ?? null) as T | null;
    }
    if (s.includes("SELECT 1 AS x FROM follows WHERE follower_id = ? AND following_id = ?")) {
      const hit = this.db.follows.find(
        (f) => f.follower_id === b[0] && f.following_id === b[1],
      );
      return (hit ? { x: 1 } : null) as T | null;
    }
    if (s.includes("public_designs") && s.includes("orders_earned")) {
      const designerId = String(b[0]);
      const publicDesigns = [...this.db.designs.values()].filter(
        (d) => d.user_id === designerId && (d.is_public ?? 0) === 1,
      ).length;
      const ordersEarned = [...this.db.orders.values()].filter((o) => {
        const d = this.db.designs.get(String(o.design_id));
        return d?.user_id === designerId;
      }).length;
      return { public_designs: publicDesigns, orders_earned: ordersEarned } as T;
    }
    if (s.includes("SELECT id FROM users WHERE id = ?")) {
      const u = this.db.users.get(String(b[0]));
      return (u ? { id: u.id } : null) as T | null;
    }
    if (s.includes("SELECT follower_count FROM users WHERE id = ?")) {
      const u = this.db.users.get(String(b[0]));
      return (u ? { follower_count: u.follower_count ?? 0 } : null) as T | null;
    }

    // Commissions
    if (s.includes("SELECT id FROM commissions WHERE id = ?")) {
      const c = this.db.commissions.get(String(b[0]));
      return (c ? { id: c.id } : null) as T | null;
    }
    if (s.includes("SELECT * FROM commissions WHERE id = ?")) {
      return (this.db.commissions.get(String(b[0])) ?? null) as T | null;
    }

    // Orders / measurements / designs (shared with orders.ts post path)
    if (s.includes("SELECT o.* FROM order_idempotency_keys")) {
      const key = `${b[0]}:${b[1]}`;
      const row = this.db.orderKeys.get(key);
      if (!row) return null;
      return (this.db.orders.get(String(row.order_id)) ?? null) as T | null;
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
    if (s.includes("SELECT id FROM measurements WHERE user_id")) {
      const m = this.db.measurements.find((x) => x.user_id === b[0]);
      return (m ? { id: m.id } : null) as T | null;
    }
    if (s.includes("SELECT * FROM orders WHERE id = ?")) {
      return (this.db.orders.get(String(b[0])) ?? null) as T | null;
    }
    if (s.includes("SELECT id, status FROM orders WHERE id = ? AND user_id = ?")) {
      const o = this.db.orders.get(String(b[0]));
      if (!o || o.user_id !== b[1]) return null;
      return { id: o.id, status: o.status } as T;
    }
    if (s.includes("SELECT status FROM orders WHERE id = ?")) {
      const o = this.db.orders.get(String(b[0]));
      return (o ? { status: o.status } : null) as T | null;
    }

    // Consultations
    if (s.includes("FROM consultations WHERE id = ?") && s.includes("SELECT id, user_id, designer_id")) {
      const c = this.db.consultations.get(String(b[0]));
      return (c
        ? { id: c.id, user_id: c.user_id, designer_id: c.designer_id ?? null }
        : null) as T | null;
    }
    if (s.includes("SELECT * FROM consultations WHERE id = ?")) {
      return (this.db.consultations.get(String(b[0])) ?? null) as T | null;
    }
    return null;
  }

  async all() {
    const s = this.sql;
    const b = this.binds;

    // Feed listing
    if (s.includes("FROM posts p") && s.includes("LIMIT ?")) {
      const viewerId = String(b[0]);
      // cursor + tag filters are treated loosely.
      const all = [...this.db.posts.values()].sort((x, y) =>
        String(y.posted_at).localeCompare(String(x.posted_at)),
      );
      const results = all.map((p) => shapePostRow(this.db, p, viewerId));
      return { results };
    }

    // Comments list
    if (s.includes("FROM post_comments c") && s.includes("WHERE c.post_id = ?")) {
      const results = this.db.postComments
        .filter((c) => c.post_id === b[0])
        .sort((x, y) => String(x.created_at).localeCompare(String(y.created_at)))
        .map((c) => {
          const author = this.db.users.get(String(c.author_id));
          return {
            id: c.id,
            post_id: c.post_id,
            author_id: c.author_id,
            body: c.body,
            created_at: c.created_at,
            author_name: author?.name ?? null,
            author_avatar_url: author?.avatar_url ?? null,
            author_is_pro_designer: author?.is_pro_designer ?? null,
          };
        });
      return { results };
    }

    // Designers /pro
    if (
      s.includes("FROM users") &&
      s.includes("WHERE is_pro_designer = 1") &&
      s.includes("ORDER BY follower_count")
    ) {
      const results = [...this.db.users.values()]
        .filter((u) => (u.is_pro_designer ?? 0) === 1)
        .sort(
          (x, y) => Number(y.follower_count ?? 0) - Number(x.follower_count ?? 0),
        );
      return { results };
    }
    if (s.includes("SELECT following_id FROM follows WHERE follower_id = ?")) {
      const followerId = String(b[0]);
      const rest = b.slice(1).map(String);
      const results = this.db.follows
        .filter((f) => f.follower_id === followerId && rest.includes(String(f.following_id)))
        .map((f) => ({ following_id: f.following_id }));
      return { results };
    }

    // Designer earnings aggregate
    if (s.includes("FROM commissions") && s.includes("GROUP BY status")) {
      const designerId = String(b[0]);
      const grouped = new Map<string, { count: number; total: number }>();
      for (const c of this.db.commissions.values()) {
        if (c.designer_id !== designerId) continue;
        const key = String(c.status);
        const cur = grouped.get(key) ?? { count: 0, total: 0 };
        cur.count += 1;
        cur.total += Number(c.amount ?? 0);
        grouped.set(key, cur);
      }
      const results = [...grouped.entries()].map(([status, v]) => ({
        status,
        count: v.count,
        total: v.total,
      }));
      return { results };
    }
    // Designer commissions list (joined)
    if (s.includes("FROM commissions c") && s.includes("JOIN orders")) {
      const designerId = String(b[0]);
      const statusFilter = b[1] ? String(b[1]) : null;
      const results = [...this.db.commissions.values()]
        .filter((c) => c.designer_id === designerId)
        .filter((c) => !statusFilter || c.status === statusFilter)
        .map((c) => ({
          ...c,
          total_price: this.db.orders.get(String(c.order_id))?.total_price ?? 0,
          order_status: this.db.orders.get(String(c.order_id))?.status ?? null,
          design_name: (() => {
            const o = this.db.orders.get(String(c.order_id));
            const d = o ? this.db.designs.get(String(o.design_id)) : null;
            return d?.name ?? null;
          })(),
        }));
      return { results };
    }

    // Designer public designs
    if (s.includes("FROM designs") && s.includes("AND is_public = 1")) {
      const userId = String(b[0]);
      const results = [...this.db.designs.values()].filter(
        (d) => d.user_id === userId && (d.is_public ?? 0) === 1,
      );
      return { results };
    }

    // Showcase list
    if (s.includes("FROM designs d") && s.includes("is_public = 1")) {
      const results = [...this.db.designs.values()]
        .filter((d) => (d.is_public ?? 0) === 1)
        .map((d) => {
          const u = this.db.users.get(String(d.user_id));
          return {
            id: d.id,
            name: d.name,
            garment_type: d.garment_type,
            primary_colour: d.primary_colour ?? "#000",
            accent_colour: d.accent_colour ?? null,
            fabric_quality: d.fabric_quality ?? null,
            print_image_url: d.print_image_url ?? null,
            order_count: d.order_count ?? 0,
            created_at: d.created_at ?? "2026-01-01",
            designer_id: d.user_id,
            designer_name: u?.name ?? null,
            designer_avatar_url: u?.avatar_url ?? null,
            designer_is_pro: u?.is_pro_designer ?? 0,
            recent_orders: 0,
            recent_reactions: 0,
          };
        });
      return { results };
    }

    // Consultations list
    if (s.includes("FROM consultations")) {
      const results = [...this.db.consultations.values()].filter(
        (c) => c.user_id === b[0] || c.designer_id === b[0],
      );
      return { results };
    }

    return { results: [] };
  }

  async run() {
    const s = this.sql;
    const b = this.binds;

    // Posts write path
    if (s.includes("INSERT INTO posts")) {
      this.db.posts.set(String(b[0]), {
        id: b[0],
        author_id: b[1],
        body: b[2],
        image_urls: b[3] ?? "[]",
        tags: b[4] ?? "[]",
        reaction_count: 0,
        comment_count: 0,
        posted_at: new Date().toISOString(),
      });
      return { success: true, meta: { changes: 1 } };
    }
    if (s.includes("INSERT INTO post_reactions")) {
      this.db.postReactions.push({
        id: b[0],
        post_id: b[1],
        user_id: b[2],
        reaction_type: b[3],
      });
      return { success: true, meta: { changes: 1 } };
    }
    if (s.includes("DELETE FROM post_reactions WHERE id = ?")) {
      this.db.postReactions = this.db.postReactions.filter((r) => r.id !== b[0]);
      return { success: true, meta: { changes: 1 } };
    }
    if (s.includes("UPDATE post_reactions SET reaction_type = ?")) {
      const r = this.db.postReactions.find((x) => x.id === b[1]);
      if (r) r.reaction_type = b[0];
      return { success: true, meta: { changes: 1 } };
    }
    if (s.includes("UPDATE posts SET reaction_count")) {
      const post = this.db.posts.get(String(b[1]));
      if (post) {
        post.reaction_count = this.db.postReactions.filter(
          (r) => r.post_id === b[0],
        ).length;
      }
      return { success: true, meta: { changes: 1 } };
    }
    if (s.includes("INSERT INTO post_comments")) {
      this.db.postComments.push({
        id: b[0],
        post_id: b[1],
        author_id: b[2],
        body: b[3],
        created_at: new Date().toISOString(),
      });
      return { success: true, meta: { changes: 1 } };
    }
    if (s.includes("UPDATE posts SET comment_count")) {
      const post = this.db.posts.get(String(b[1]));
      if (post) {
        post.comment_count = this.db.postComments.filter(
          (c) => c.post_id === b[0],
        ).length;
      }
      return { success: true, meta: { changes: 1 } };
    }

    // Follows
    if (s.includes("INSERT OR IGNORE INTO follows")) {
      const existing = this.db.follows.find(
        (f) => f.follower_id === b[0] && f.following_id === b[1],
      );
      if (existing) return { success: true, meta: { changes: 0 } };
      this.db.follows.push({ follower_id: b[0], following_id: b[1] });
      return { success: true, meta: { changes: 1 } };
    }
    if (s.includes("DELETE FROM follows")) {
      const before = this.db.follows.length;
      this.db.follows = this.db.follows.filter(
        (f) => !(f.follower_id === b[0] && f.following_id === b[1]),
      );
      return {
        success: true,
        meta: { changes: before - this.db.follows.length },
      };
    }
    if (s.includes("UPDATE users SET follower_count")) {
      const u = this.db.users.get(String(b[1]));
      if (u) {
        u.follower_count = this.db.follows.filter(
          (f) => f.following_id === b[0],
        ).length;
      }
      return { success: true, meta: { changes: 1 } };
    }

    // Orders write path
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
      });
      return { success: true, meta: { changes: 1 } };
    }
    if (s.includes("INSERT INTO order_idempotency_keys")) {
      this.db.orderKeys.set(`${b[1]}:${b[2]}`, { order_id: b[3] });
      return { success: true, meta: { changes: 1 } };
    }
    if (s.includes("INSERT INTO order_status_history")) {
      return { success: true, meta: { changes: 1 } };
    }
    if (s.includes("INSERT OR IGNORE INTO commissions")) {
      const id = String(b[0]);
      if (!this.db.commissions.has(id)) {
        this.db.commissions.set(id, {
          id,
          order_id: b[1],
          designer_id: b[2],
          buyer_id: b[3],
          amount: b[4],
          percentage: b[5],
          currency: "QAR",
          status: "pending",
          created_at: new Date().toISOString(),
        });
      }
      return { success: true, meta: { changes: 1 } };
    }
    if (s.includes("UPDATE commissions SET status = 'approved'")) {
      for (const c of this.db.commissions.values()) {
        if (c.order_id === b[0] && c.status === "pending") {
          c.status = "approved";
        }
      }
      return { success: true, meta: { changes: 1 } };
    }
    if (s.includes("UPDATE commissions SET status = 'void'")) {
      for (const c of this.db.commissions.values()) {
        if (
          c.order_id === b[0] &&
          (c.status === "pending" || c.status === "approved")
        ) {
          c.status = "void";
        }
      }
      return { success: true, meta: { changes: 1 } };
    }
    if (s.includes("UPDATE commissions") && s.includes("SET status = ?")) {
      const c = this.db.commissions.get(String(b[3]));
      if (c) {
        c.status = b[0];
        if (b[1]) c.payout_reference = b[1];
        if (b[2]) c.notes = b[2];
      }
      return { success: true, meta: { changes: 1 } };
    }

    // Designs
    if (s.includes("UPDATE designs SET order_count")) {
      const d = this.db.designs.get(String(b[1]));
      if (d) {
        d.order_count =
          [...this.db.orders.values()].filter((o) => o.design_id === b[0]).length;
      }
      return { success: true, meta: { changes: 1 } };
    }

    // Orders status updates
    if (s.includes("UPDATE orders SET status = ?")) {
      const o = this.db.orders.get(String(b[1]));
      if (o) o.status = b[0];
      return { success: true, meta: { changes: 1 } };
    }
    if (s.includes("UPDATE orders SET status = 'cancelled'")) {
      const o = this.db.orders.get(String(b[0]));
      if (o) o.status = "cancelled";
      return { success: true, meta: { changes: 1 } };
    }

    // Consultations
    if (s.includes("INSERT INTO consultations")) {
      this.db.consultations.set(String(b[0]), {
        id: b[0],
        user_id: b[1],
        garment_type: b[2],
        description: b[3],
        budget_min: b[4],
        budget_max: b[5],
        status: "pending",
        created_at: new Date().toISOString(),
      });
      return { success: true, meta: { changes: 1 } };
    }
    if (s.includes("UPDATE consultations SET")) {
      // binds: set-values... + id last
      const id = String(b[b.length - 1]);
      const row = this.db.consultations.get(id);
      if (row) {
        // naive set-value apply
        const pairs = s.replace("UPDATE consultations SET", "").split("WHERE")[0].split(",");
        pairs.forEach((pair, idx) => {
          const col = pair.split("=")[0].trim();
          if (col) row[col] = b[idx];
        });
      }
      return { success: true, meta: { changes: 1 } };
    }
    return { success: true, meta: { changes: 0 } };
  }
}

function shapePostRow(db: MockDb, post: Row, viewerId: string) {
  const author = db.users.get(String(post.author_id));
  const myReaction = db.postReactions.find(
    (r) => r.post_id === post.id && r.user_id === viewerId,
  );
  return {
    ...post,
    author_name: author?.name ?? null,
    author_avatar_url: author?.avatar_url ?? null,
    author_is_pro_designer: author?.is_pro_designer ?? null,
    my_reaction: myReaction?.reaction_type ?? null,
  };
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
      if (token === "buyer-token") {
        return new Response(
          JSON.stringify({
            user: {
              id: "buyer-1",
              role: "user",
              name: "Buyer",
              email: "b@example.com",
            },
          }),
          { status: 200, headers: { "Content-Type": "application/json" } },
        );
      }
      if (token === "designer-token") {
        return new Response(
          JSON.stringify({
            user: {
              id: "designer-1",
              role: "user",
              name: "Pro Designer",
              email: "d@example.com",
            },
          }),
          { status: 200, headers: { "Content-Type": "application/json" } },
        );
      }
      if (token === "tailor-token") {
        return new Response(
          JSON.stringify({
            user: {
              id: "tailor-1",
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
  ADMIN_HMAC_SECRET: "phase6-admin-secret",
} as const;

async function req(
  method: string,
  path: string,
  options: {
    token?: string;
    body?: unknown;
    headers?: Record<string, string>;
    rawBody?: string;
  } = {},
) {
  const headers = new Headers(options.headers);
  if (options.token) headers.set("Authorization", `Bearer ${options.token}`);
  if (options.body !== undefined || options.rawBody !== undefined) {
    headers.set("Content-Type", "application/json");
  }
  const body =
    options.rawBody !== undefined
      ? options.rawBody
      : options.body !== undefined
        ? JSON.stringify(options.body)
        : undefined;
  const request = new Request(`http://local${path}`, {
    method,
    headers,
    body,
  });
  return app.fetch(request, env, {} as ExecutionContext);
}

function seed() {
  mockDb.users.clear();
  mockDb.designs.clear();
  mockDb.orders.clear();
  mockDb.orderKeys.clear();
  mockDb.measurements.length = 0;
  mockDb.posts.clear();
  mockDb.postReactions.length = 0;
  mockDb.postComments.length = 0;
  mockDb.follows.length = 0;
  mockDb.commissions.clear();
  mockDb.consultations.clear();

  mockDb.users.set("buyer-1", {
    id: "buyer-1",
    name: "Buyer",
    email: "b@example.com",
    avatar_url: null,
    bio: null,
    speciality: null,
    follower_count: 0,
    is_pro_designer: 0,
  });
  mockDb.users.set("designer-1", {
    id: "designer-1",
    name: "Pro Designer",
    email: "d@example.com",
    avatar_url: null,
    bio: "Qatari craft specialist",
    speciality: "thobe",
    follower_count: 2,
    is_pro_designer: 1,
  });
  mockDb.measurements.push({
    id: "m-buyer",
    user_id: "buyer-1",
    chest: 100,
    waist: 80,
  });

  mockDb.designs.set("design-pub", {
    id: "design-pub",
    user_id: "designer-1",
    name: "Midnight Thobe",
    garment_type: "thobe",
    primary_colour: "#0A1A2F",
    accent_colour: "#C9A14A",
    fabric_quality: "premium",
    print_image_url: null,
    order_count: 0,
    is_public: 1,
    created_at: "2026-04-01",
  });
  mockDb.designs.set("design-private", {
    id: "design-private",
    user_id: "designer-1",
    name: "Draft",
    garment_type: "thobe",
    primary_colour: "#111",
    fabric_quality: "standard",
    order_count: 0,
    is_public: 0,
    created_at: "2026-03-01",
  });
}

describe("Phase 6 contract tests", () => {
  beforeEach(seed);

  describe("POSTS feed + reactions + comments", () => {
    it("creates a post and lists it in the feed with author info", async () => {
      const create = await req("POST", "/posts", {
        token: "designer-token",
        body: { body: "My new look", imageUrls: [], tags: ["thobe"] },
      });
      expect(create.status).toBe(201);

      const feed = await req("GET", "/posts", { token: "buyer-token" });
      expect(feed.status).toBe(200);
      const page = (await feed.json()) as {
        posts: Array<{ authorName: string; isVerifiedDesigner: boolean; tags: string[] }>;
        nextCursor: string | null;
      };
      expect(page.posts.length).toBe(1);
      expect(page.posts[0].authorName).toBe("Pro Designer");
      expect(page.posts[0].isVerifiedDesigner).toBe(true);
      expect(page.posts[0].tags).toContain("thobe");
    });

    it("rejects reactions with invalid type", async () => {
      const create = await req("POST", "/posts", {
        token: "designer-token",
        body: { body: "hello" },
      });
      const post = (await create.json()) as { id: string };
      const res = await req("POST", `/posts/${post.id}/reactions`, {
        token: "buyer-token",
        body: { type: "hug" },
      });
      expect(res.status).toBe(400);
    });

    it("toggles a reaction on/off and updates reaction count atomically", async () => {
      const create = await req("POST", "/posts", {
        token: "designer-token",
        body: { body: "hello" },
      });
      const post = (await create.json()) as { id: string };

      const on = await req("POST", `/posts/${post.id}/reactions`, {
        token: "buyer-token",
        body: { type: "love" },
      });
      expect(on.status).toBe(200);
      let body = (await on.json()) as {
        currentUserReaction: string | null;
        reactionCount: number;
      };
      expect(body.currentUserReaction).toBe("love");
      expect(body.reactionCount).toBe(1);

      const off = await req("POST", `/posts/${post.id}/reactions`, {
        token: "buyer-token",
        body: { type: "love" },
      });
      body = (await off.json()) as {
        currentUserReaction: string | null;
        reactionCount: number;
      };
      expect(body.currentUserReaction).toBeNull();
      expect(body.reactionCount).toBe(0);
    });

    it("creates a comment and lists it", async () => {
      const post = (await (
        await req("POST", "/posts", {
          token: "designer-token",
          body: { body: "topic" },
        })
      ).json()) as { id: string };

      const create = await req("POST", `/posts/${post.id}/comments`, {
        token: "buyer-token",
        body: { body: "Nice work" },
      });
      expect(create.status).toBe(201);

      const list = await req("GET", `/posts/${post.id}/comments`, {
        token: "buyer-token",
      });
      const rows = (await list.json()) as Array<{ body: string }>;
      expect(rows.length).toBe(1);
      expect(rows[0].body).toBe("Nice work");
    });

    it("returns 404 when reacting on a non-existent post", async () => {
      const res = await req("POST", "/posts/nope/reactions", {
        token: "buyer-token",
        body: { type: "love" },
      });
      expect(res.status).toBe(404);
    });
  });

  describe("FOLLOWS atomic counter", () => {
    it("increments follower_count on follow and zeros it on unfollow", async () => {
      mockDb.users.get("designer-1")!.follower_count = 0;
      const follow = await req("POST", "/community/follow/designer-1", {
        token: "buyer-token",
      });
      expect(follow.status).toBe(200);
      let payload = (await follow.json()) as {
        followed: boolean;
        followerCount: number;
      };
      expect(payload.followed).toBe(true);
      expect(payload.followerCount).toBe(1);

      const unfollow = await req("DELETE", "/community/follow/designer-1", {
        token: "buyer-token",
      });
      expect(unfollow.status).toBe(200);
      payload = (await unfollow.json()) as {
        followed: boolean;
        followerCount: number;
      };
      expect(payload.followed).toBe(false);
      expect(payload.followerCount).toBe(0);
    });

    it("rejects following yourself", async () => {
      const res = await req("POST", "/community/follow/buyer-1", {
        token: "buyer-token",
      });
      expect(res.status).toBe(400);
    });
  });

  describe("DESIGNERS profile + earnings", () => {
    it("returns a designer profile with follow state and stats", async () => {
      await req("POST", "/community/follow/designer-1", { token: "buyer-token" });
      const res = await req("GET", "/designers/designer-1", {
        token: "buyer-token",
      });
      expect(res.status).toBe(200);
      const body = (await res.json()) as Record<string, unknown>;
      expect(body.id).toBe("designer-1");
      expect(body.isFollowing).toBe(true);
      expect(body.isProDesigner).toBe(true);
      expect((body.stats as { publicDesigns: number }).publicDesigns).toBe(1);
    });

    it("lists pro designers sorted by followers", async () => {
      const res = await req("GET", "/designers/pro", { token: "buyer-token" });
      expect(res.status).toBe(200);
      const rows = (await res.json()) as Array<{ id: string }>;
      expect(rows.map((r) => r.id)).toContain("designer-1");
    });

    it("returns an earnings summary bucketed by status", async () => {
      mockDb.commissions.set("c1", {
        id: "c1",
        order_id: "o1",
        designer_id: "designer-1",
        amount: 49,
        status: "pending",
      });
      mockDb.commissions.set("c2", {
        id: "c2",
        order_id: "o2",
        designer_id: "designer-1",
        amount: 40,
        status: "paid",
      });
      const res = await req("GET", "/designers/me/earnings", {
        token: "designer-token",
      });
      const body = (await res.json()) as {
        byStatus: Record<string, { count: number; total: number }>;
        lifetimeTotal: number;
        payoutPending: number;
        paidOut: number;
      };
      expect(body.byStatus.pending.total).toBe(49);
      expect(body.byStatus.paid.total).toBe(40);
      expect(body.lifetimeTotal).toBe(89);
      expect(body.paidOut).toBe(40);
    });
  });

  describe("SHOWCASE grid", () => {
    it("only lists public designs with designer info", async () => {
      const res = await req("GET", "/showcase", { token: "buyer-token" });
      expect(res.status).toBe(200);
      const body = (await res.json()) as {
        items: Array<{ designId: string; designer: { id: string; isProDesigner: boolean } }>;
      };
      expect(body.items.length).toBe(1);
      expect(body.items[0].designId).toBe("design-pub");
      expect(body.items[0].designer.isProDesigner).toBe(true);
    });
  });

  describe("COMMISSIONS hook into orders + admin payout", () => {
    async function placePublicOrder(key: string, designerId = "designer-1") {
      return req("POST", "/orders", {
        token: "buyer-token",
        headers: { "X-Idempotency-Key": key },
        body: {
          designId: "design-pub",
          designerId,
          deliveryAddress: "West Bay",
          deliveryCity: "Doha",
          deliveryPhone: "55512345",
        },
      });
    }

    it("creates a pending commission @ 10% when a public design is ordered", async () => {
      const res = await placePublicOrder("phase6-order-1");
      expect(res.status).toBe(201);
      const commissions = [...mockDb.commissions.values()];
      expect(commissions.length).toBe(1);
      expect(commissions[0].designer_id).toBe("designer-1");
      expect(commissions[0].status).toBe("pending");
      // total_price = 350 + 120 + 20 = 490, 10% = 49
      expect(commissions[0].amount).toBe(49);
    });

    it("rejects orders where designerId does not match the design author", async () => {
      const res = await placePublicOrder("phase6-order-mismatch", "someone-else");
      expect(res.status).toBe(400);
    });

    it("flips pending -> approved when the tailor marks the order delivered", async () => {
      const order = (await (await placePublicOrder("phase6-order-2")).json()) as { id: string };
      // Walk order through the happy path so we reach delivered.
      const steps = [
        "confirmed",
        "cutting",
        "stitching",
        "embroidery",
        "quality_check",
        "ready_to_ship",
        "out_for_delivery",
        "delivered",
      ] as const;
      for (const status of steps) {
        const patch = await req("PATCH", `/orders/${order.id}/status`, {
          token: "tailor-token",
          body: { status },
        });
        expect(patch.status).toBe(200);
      }
      const commission = [...mockDb.commissions.values()][0];
      expect(commission.status).toBe("approved");
    });

    it("voids the commission when the buyer cancels the order", async () => {
      const order = (await (await placePublicOrder("phase6-order-3")).json()) as { id: string };
      const cancel = await req("DELETE", `/orders/${order.id}`, {
        token: "buyer-token",
      });
      expect(cancel.status).toBe(200);
      const commission = [...mockDb.commissions.values()][0];
      expect(commission.status).toBe("void");
    });

    it("creates no commission when the buyer orders their own design", async () => {
      // Flip ownership so buyer-1 owns design-pub for this test.
      mockDb.designs.get("design-pub")!.user_id = "buyer-1";
      const res = await placePublicOrder("phase6-order-self", "");
      expect(res.status).toBe(201);
      expect(mockDb.commissions.size).toBe(0);
    });

    it("rejects admin payout with missing / wrong HMAC signature", async () => {
      mockDb.commissions.set("c-pay", {
        id: "c-pay",
        order_id: "o",
        designer_id: "designer-1",
        amount: 100,
        status: "approved",
      });
      const res = await req("PATCH", "/admin/commissions/c-pay", {
        rawBody: JSON.stringify({ status: "paid" }),
        headers: { "x-admin-signature": "bogus" },
      });
      expect(res.status).toBe(401);
    });

    it("marks a commission as paid with a valid HMAC signature", async () => {
      mockDb.commissions.set("c-pay", {
        id: "c-pay",
        order_id: "o",
        designer_id: "designer-1",
        amount: 100,
        status: "approved",
      });
      const payload = JSON.stringify({
        status: "paid",
        payoutReference: "BANK-REF-123",
      });
      const sig = await hmacSha256Hex("phase6-admin-secret", payload);
      const res = await req("PATCH", "/admin/commissions/c-pay", {
        rawBody: payload,
        headers: { "x-admin-signature": sig },
      });
      expect(res.status).toBe(200);
      expect(mockDb.commissions.get("c-pay")?.status).toBe("paid");
      expect(mockDb.commissions.get("c-pay")?.payout_reference).toBe("BANK-REF-123");
    });

    it("returns 404 for admin payout when ADMIN_HMAC_SECRET is blank", async () => {
      const prevEnv = { ...env, ADMIN_HMAC_SECRET: "" };
      const payload = "{}";
      const request = new Request(`http://local/admin/commissions/whatever`, {
        method: "PATCH",
        headers: new Headers({
          "content-type": "application/json",
          "x-admin-signature": "anything",
        }),
        body: payload,
      });
      const res = await app.fetch(
        request,
        prevEnv as unknown as typeof env,
        {} as ExecutionContext,
      );
      expect(res.status).toBe(404);
    });
  });
});
