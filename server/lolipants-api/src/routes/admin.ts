import { Hono } from "hono";
import { v4 as uuidv4 } from "uuid";
import {
  MANNEQUIN_CMS_DISABLED_MESSAGE,
  MANNEQUIN_CMS_MUTATIONS_DISABLED,
} from "../lib/cmsPolicy";
import { apiError } from "../lib/http";
import { buildR2PublicUrl } from "../lib/r2PublicUrl";
import { hmacSha256Hex, syncRoleWithAuthWorker } from "../lib/roleSync";
import { requireAdmin, requireAuth } from "../middleware/auth";
import type { AppVariables, Env } from "../types";
import { AdminScopes, ALLOWED_ROLES } from "../lib/roles";

export const adminRoutes = new Hono<{ Bindings: Env; Variables: AppVariables }>();

const validOrderStatuses = new Set([
  "placed",
  "confirmed",
  "cutting",
  "stitching",
  "embroidery",
  "quality_check",
  "ready_to_ship",
  "out_for_delivery",
  "delivered",
  "cancelled",
]);

const statusTransitions: Record<string, ReadonlySet<string>> = {
  placed: new Set(["confirmed", "cancelled"]),
  confirmed: new Set(["cutting", "cancelled"]),
  cutting: new Set(["stitching", "cancelled"]),
  stitching: new Set(["embroidery", "quality_check", "cancelled"]),
  embroidery: new Set(["quality_check", "cancelled"]),
  quality_check: new Set(["ready_to_ship", "cancelled"]),
  ready_to_ship: new Set(["out_for_delivery", "cancelled"]),
  out_for_delivery: new Set(["delivered"]),
  delivered: new Set(),
  cancelled: new Set(),
};

// ---------------------------------------------------------------------------
// Legacy HMAC-gated commission endpoint (preserved for automation).
// ---------------------------------------------------------------------------

adminRoutes.patch("/commissions/:id", async (c) => {
  const secret = c.env.ADMIN_HMAC_SECRET?.trim();
  if (!secret) {
    return apiError(c, 404, "NOT_FOUND", "Admin endpoints disabled");
  }
  const raw = await c.req.text();
  const signature = c.req.header("x-admin-signature") ?? "";
  const expected = await hmacSha256Hex(secret, raw);
  if (!signature || signature !== expected) {
    return apiError(c, 401, "INVALID_ADMIN_SIGNATURE", "Invalid signature");
  }

  let body: Record<string, unknown>;
  try {
    body = raw.length > 0 ? (JSON.parse(raw) as Record<string, unknown>) : {};
  } catch {
    return apiError(c, 400, "INVALID_JSON", "Invalid JSON body");
  }
  const id = c.req.param("id");
  const nextStatus = String(body.status ?? "paid").trim().toLowerCase();
  if (!["approved", "paid", "void"].includes(nextStatus)) {
    return apiError(c, 400, "INVALID_STATUS", "Invalid commission status");
  }
  const payoutRef = body.payoutReference
    ? String(body.payoutReference).trim()
    : null;
  const notes = body.notes ? String(body.notes).trim() : null;

  const existing = await c.env.DB.prepare(
    "SELECT id FROM commissions WHERE id = ?",
  )
    .bind(id)
    .first<{ id: string }>();
  if (!existing) return apiError(c, 404, "COMMISSION_NOT_FOUND", "Commission not found");

  await c.env.DB.prepare(
    `UPDATE commissions
     SET status = ?, payout_reference = COALESCE(?, payout_reference),
         notes = COALESCE(?, notes), updated_at = datetime('now')
     WHERE id = ?`,
  )
    .bind(nextStatus, payoutRef, notes, id)
    .run();
  const row = await c.env.DB.prepare("SELECT * FROM commissions WHERE id = ?")
    .bind(id)
    .first<Record<string, unknown>>();
  return c.json(row);
});

// ---------------------------------------------------------------------------
// Session-authenticated admin routes. Every subsequent handler requires an
// authenticated admin; individual routes add a scope check on top.
// ---------------------------------------------------------------------------

adminRoutes.use("*", requireAuth);

// ------- /admin/users (users_mgmt) -----------------------------------------

adminRoutes.get("/users", requireAdmin(AdminScopes.usersMgmt), async (c) => {
  const role = c.req.query("role")?.trim().toLowerCase() ?? "";
  const banned = c.req.query("banned")?.trim();
  const search = c.req.query("q")?.trim() ?? "";
  const bindings: Array<string> = [];
  let where = "WHERE 1=1";
  if (role && ALLOWED_ROLES.has(role)) {
    where += " AND role = ?";
    bindings.push(role);
  }
  if (banned === "true") {
    where += " AND banned_at IS NOT NULL";
  } else if (banned === "false") {
    where += " AND banned_at IS NULL";
  }
  if (search.length > 0) {
    where += " AND (LOWER(name) LIKE ? OR LOWER(email) LIKE ?)";
    const needle = `%${search.toLowerCase()}%`;
    bindings.push(needle, needle);
  }
  const { results } = await c.env.DB.prepare(
    `SELECT id, name, email, role, admin_scopes, banned_at, avatar_url, bio, is_pro_designer, created_at
     FROM users ${where}
     ORDER BY created_at DESC
     LIMIT 200`,
  )
    .bind(...bindings)
    .all();
  return c.json(results);
});

adminRoutes.patch("/users/:id", requireAdmin(AdminScopes.usersMgmt), async (c) => {
  const id = c.req.param("id");
  const body = (await c.req.json().catch(() => ({}))) as Record<string, unknown>;
  const existing = await c.env.DB.prepare(
    "SELECT id, role, admin_scopes, banned_at FROM users WHERE id = ?",
  )
    .bind(id)
    .first<{ id: string; role: string; admin_scopes: string | null; banned_at: string | null }>();
  if (!existing) return apiError(c, 404, "USER_NOT_FOUND", "User not found");

  const patch: Record<string, string | null> = {};
  let nextRole: string | undefined;
  let nextScopes: string[] | undefined;
  let nextBanned: string | null | undefined;

  if (typeof body.role === "string") {
    const role = body.role.trim().toLowerCase();
    if (!ALLOWED_ROLES.has(role)) {
      return apiError(c, 400, "INVALID_ROLE", "Invalid role");
    }
    nextRole = role;
    patch.role = role;
  }
  if (body.adminScopes !== undefined || body.admin_scopes !== undefined) {
    const raw = body.adminScopes ?? body.admin_scopes;
    if (!Array.isArray(raw)) {
      return apiError(c, 400, "INVALID_SCOPES", "adminScopes must be an array");
    }
    nextScopes = raw
      .map((v) => String(v ?? "").trim())
      .filter((v) => v.length > 0);
    patch.admin_scopes = JSON.stringify(nextScopes);
  }
  if (body.banned !== undefined) {
    const banned = Boolean(body.banned);
    patch.banned_at = banned ? new Date().toISOString() : null;
    nextBanned = patch.banned_at;
  }

  if (Object.keys(patch).length === 0) {
    return apiError(c, 400, "NO_FIELDS", "Provide role, adminScopes, or banned");
  }

  const setClauses: string[] = [];
  const bindings: Array<string | null> = [];
  for (const [key, value] of Object.entries(patch)) {
    setClauses.push(`${key} = ?`);
    bindings.push(value);
  }
  setClauses.push("updated_at = datetime('now')");
  bindings.push(id);
  await c.env.DB.prepare(
    `UPDATE users SET ${setClauses.join(", ")} WHERE id = ?`,
  )
    .bind(...bindings)
    .run();

  if (nextRole !== undefined || nextScopes !== undefined) {
    await syncRoleWithAuthWorker(c, id, {
      role: nextRole ?? existing.role,
      adminScopes:
        nextScopes ??
        (() => {
          try {
            const parsed = existing.admin_scopes
              ? (JSON.parse(existing.admin_scopes) as unknown)
              : [];
            return Array.isArray(parsed) ? (parsed as string[]) : [];
          } catch {
            return [];
          }
        })(),
    });
  }

  const updated = await c.env.DB.prepare(
    "SELECT id, name, email, role, admin_scopes, banned_at FROM users WHERE id = ?",
  )
    .bind(id)
    .first<Record<string, unknown>>();
  return c.json({ ...updated, banned_at: nextBanned ?? updated?.banned_at ?? null });
});

// ------- /admin/role-requests (users_mgmt) ---------------------------------

adminRoutes.get("/role-requests", requireAdmin(AdminScopes.usersMgmt), async (c) => {
  const status = c.req.query("status")?.trim().toLowerCase() ?? "";
  let query = `SELECT r.*, u.name AS requester_name, u.email AS requester_email,
                      u.role AS requester_current_role
               FROM role_requests r
               JOIN users u ON u.id = r.user_id`;
  const bindings: string[] = [];
  if (status.length > 0 && ["pending", "approved", "rejected"].includes(status)) {
    query += " WHERE r.status = ?";
    bindings.push(status);
  }
  query += " ORDER BY r.created_at DESC LIMIT 200";
  const { results } = await c.env.DB.prepare(query)
    .bind(...bindings)
    .all();
  return c.json(results);
});

adminRoutes.patch("/role-requests/:id", requireAdmin(AdminScopes.usersMgmt), async (c) => {
  const id = c.req.param("id");
  const adminId = c.get("userId") as string;
  const body = (await c.req.json().catch(() => ({}))) as Record<string, unknown>;
  const nextStatus = String(body.status ?? "").trim().toLowerCase();
  if (!["approved", "rejected"].includes(nextStatus)) {
    return apiError(c, 400, "INVALID_STATUS", "status must be approved or rejected");
  }
  const adminNoteRaw = body.adminNote != null ? String(body.adminNote).trim() : "";
  const adminNote = adminNoteRaw.length > 0 ? adminNoteRaw : null;

  const reqRow = await c.env.DB.prepare("SELECT * FROM role_requests WHERE id = ?")
    .bind(id)
    .first<{
      id: string;
      user_id: string;
      requested_role: string;
      status: string;
    }>();
  if (!reqRow) {
    return apiError(c, 404, "NOT_FOUND", "Role request not found");
  }
  if (reqRow.status !== "pending") {
    return apiError(c, 400, "ALREADY_RESOLVED", "Request is no longer pending");
  }

  const resolvedAt = new Date().toISOString();

  if (nextStatus === "rejected") {
    await c.env.DB.prepare(
      `UPDATE role_requests
       SET status = ?, admin_note = ?, resolved_at = ?, resolved_by = ?
       WHERE id = ?`,
    )
      .bind("rejected", adminNote, resolvedAt, adminId, id)
      .run();
    const row = await c.env.DB.prepare("SELECT * FROM role_requests WHERE id = ?")
      .bind(id)
      .first<Record<string, unknown>>();
    return c.json(row);
  }

  const targetId = reqRow.user_id;
  const newRole = reqRow.requested_role.trim().toLowerCase();
  if (!["tailor", "delivery"].includes(newRole)) {
    return apiError(c, 400, "INVALID_REQUEST", "Invalid requested role on record");
  }

  const userRow = await c.env.DB.prepare(
    "SELECT id, role, admin_scopes FROM users WHERE id = ?",
  )
    .bind(targetId)
    .first<{
      id: string;
      role: string | null;
      admin_scopes: string | null;
    }>();
  if (!userRow) {
    return apiError(c, 404, "USER_NOT_FOUND", "User not found");
  }
  const currentRole = (userRow.role ?? "user").trim().toLowerCase();
  if (currentRole !== "user") {
    return apiError(
      c,
      409,
      "USER_ROLE_CHANGED",
      "User is no longer a customer; reject this request instead",
    );
  }

  let adminScopes: string[] = [];
  try {
    const parsed = userRow.admin_scopes
      ? (JSON.parse(userRow.admin_scopes) as unknown)
      : [];
    adminScopes = Array.isArray(parsed) ? (parsed as string[]) : [];
  } catch {
    adminScopes = [];
  }

  await c.env.DB.prepare(
    `UPDATE users SET role = ?, updated_at = datetime('now') WHERE id = ?`,
  )
    .bind(newRole, targetId)
    .run();

  if (newRole === "tailor") {
    const { seedTailorPricingDefaults } = await import("../lib/tailorPlanSeed");
    await seedTailorPricingDefaults(c.env.DB, targetId, {
      acceptingOrders: false,
    });
  }

  await syncRoleWithAuthWorker(c, targetId, {
    role: newRole,
    adminScopes,
  });

  await c.env.DB.prepare(
    `UPDATE role_requests
     SET status = ?, admin_note = ?, resolved_at = ?, resolved_by = ?
     WHERE id = ?`,
  )
    .bind("approved", adminNote, resolvedAt, adminId, id)
    .run();

  const row = await c.env.DB.prepare(
    `SELECT r.*, u.name AS requester_name, u.email AS requester_email
     FROM role_requests r
     JOIN users u ON u.id = r.user_id
     WHERE r.id = ?`,
  )
    .bind(id)
    .first<Record<string, unknown>>();
  return c.json(row);
});

// ------- /admin/orders (orders_oversight) ----------------------------------

adminRoutes.get("/orders", requireAdmin(AdminScopes.ordersOversight), async (c) => {
  const status = c.req.query("status")?.trim().toLowerCase() ?? "";
  let query = `SELECT o.*, d.name AS design_name
               FROM orders o
               LEFT JOIN designs d ON d.id = o.design_id`;
  const bindings: string[] = [];
  if (status.length > 0) {
    query += " WHERE o.status = ?";
    bindings.push(status);
  }
  query += " ORDER BY o.placed_at DESC LIMIT 200";
  const { results } = await c.env.DB.prepare(query)
    .bind(...bindings)
    .all();
  return c.json(results);
});

adminRoutes.patch("/orders/:id", requireAdmin(AdminScopes.ordersOversight), async (c) => {
  const id = c.req.param("id");
  const body = (await c.req.json().catch(() => ({}))) as Record<string, unknown>;
  const existing = await c.env.DB.prepare("SELECT id, status FROM orders WHERE id = ?")
    .bind(id)
    .first<{ id: string; status: string }>();
  if (!existing) return apiError(c, 404, "ORDER_NOT_FOUND", "Order not found");

  const setClauses: string[] = [];
  const bindings: Array<string | null> = [];
  let nextStatus: string | null = null;
  if (typeof body.status === "string") {
    nextStatus = body.status.trim().toLowerCase();
    if (!validOrderStatuses.has(nextStatus)) {
      return apiError(c, 400, "INVALID_STATUS", "Invalid order status");
    }
    const currentStatus = existing.status.trim().toLowerCase();
    const allowed = statusTransitions[currentStatus] ?? new Set();
    if (!allowed.has(nextStatus)) {
      return apiError(
        c,
        409,
        "INVALID_STATUS_TRANSITION",
        `Cannot transition from ${currentStatus} to ${nextStatus}`,
      );
    }
    setClauses.push("status = ?");
    bindings.push(nextStatus);
  }
  if (body.tailorId !== undefined || body.tailor_id !== undefined) {
    const val = body.tailorId ?? body.tailor_id;
    setClauses.push("tailor_id = ?");
    bindings.push(val === null || val === "" ? null : String(val));
  }
  if (body.courierId !== undefined || body.courier_id !== undefined) {
    const val = body.courierId ?? body.courier_id;
    setClauses.push("courier_id = ?");
    bindings.push(val === null || val === "" ? null : String(val));
  }
  if (setClauses.length === 0) {
    return apiError(c, 400, "NO_FIELDS", "Nothing to update");
  }
  setClauses.push("updated_at = datetime('now')");
  bindings.push(id);
  await c.env.DB.prepare(
    `UPDATE orders SET ${setClauses.join(", ")} WHERE id = ?`,
  )
    .bind(...bindings)
    .run();
  if (nextStatus != null) {
    const adminId = c.get("userId") as string;
    await c.env.DB.prepare(
      "INSERT INTO order_status_history (id, order_id, status, note, updated_by) VALUES (?, ?, ?, ?, ?)",
    )
      .bind(
        uuidv4(),
        id,
        nextStatus,
        body.note ? String(body.note).trim() : "Admin override",
        adminId,
      )
      .run();
  }
  const row = await c.env.DB.prepare("SELECT * FROM orders WHERE id = ?")
    .bind(id)
    .first<Record<string, unknown>>();
  return c.json(row);
});

// ------- /admin/payouts (payouts) ------------------------------------------

adminRoutes.get("/payouts", requireAdmin(AdminScopes.payouts), async (c) => {
  const status = c.req.query("status")?.trim().toLowerCase() ?? "";
  let query = `SELECT com.*, u.name AS designer_name, u.email AS designer_email,
                      o.total_price AS order_total
               FROM commissions com
               LEFT JOIN users u ON u.id = com.designer_id
               LEFT JOIN orders o ON o.id = com.order_id`;
  const bindings: string[] = [];
  if (status.length > 0) {
    query += " WHERE com.status = ?";
    bindings.push(status);
  }
  query += " ORDER BY com.created_at DESC LIMIT 200";
  const { results } = await c.env.DB.prepare(query)
    .bind(...bindings)
    .all();
  return c.json(results);
});

adminRoutes.patch("/payouts/:id", requireAdmin(AdminScopes.payouts), async (c) => {
  const id = c.req.param("id");
  const body = (await c.req.json().catch(() => ({}))) as Record<string, unknown>;
  const nextStatus = String(body.status ?? "paid").trim().toLowerCase();
  if (!["approved", "paid", "void"].includes(nextStatus)) {
    return apiError(c, 400, "INVALID_STATUS", "Invalid payout status");
  }
  const payoutRef = body.payoutReference
    ? String(body.payoutReference).trim()
    : null;
  const notes = body.notes ? String(body.notes).trim() : null;
  const existing = await c.env.DB.prepare(
    "SELECT id FROM commissions WHERE id = ?",
  )
    .bind(id)
    .first<{ id: string }>();
  if (!existing) return apiError(c, 404, "COMMISSION_NOT_FOUND", "Commission not found");
  await c.env.DB.prepare(
    `UPDATE commissions
     SET status = ?, payout_reference = COALESCE(?, payout_reference),
         notes = COALESCE(?, notes), updated_at = datetime('now')
     WHERE id = ?`,
  )
    .bind(nextStatus, payoutRef, notes, id)
    .run();
  const row = await c.env.DB.prepare("SELECT * FROM commissions WHERE id = ?")
    .bind(id)
    .first<Record<string, unknown>>();
  return c.json(row);
});

// ------- /admin/moderation (moderation) ------------------------------------

adminRoutes.patch(
  "/moderation/posts/:id/hide",
  requireAdmin(AdminScopes.moderation),
  async (c) => {
    const id = c.req.param("id");
    const existing = await c.env.DB.prepare("SELECT id FROM posts WHERE id = ?")
      .bind(id)
      .first<{ id: string }>();
    if (!existing) return apiError(c, 404, "POST_NOT_FOUND", "Post not found");
    await c.env.DB.prepare("DELETE FROM posts WHERE id = ?").bind(id).run();
    return c.json({ hidden: true, id });
  },
);

adminRoutes.patch(
  "/moderation/designs/:id/hide",
  requireAdmin(AdminScopes.moderation),
  async (c) => {
    const id = c.req.param("id");
    await c.env.DB.prepare(
      "UPDATE designs SET is_public = 0, updated_at = datetime('now') WHERE id = ?",
    )
      .bind(id)
      .run();
    return c.json({ hidden: true, id });
  },
);

adminRoutes.delete(
  "/moderation/commissions/:id",
  requireAdmin(AdminScopes.moderation),
  async (c) => {
    const id = c.req.param("id");
    const existing = await c.env.DB.prepare(
      "SELECT id FROM commissions WHERE id = ?",
    )
      .bind(id)
      .first<{ id: string }>();
    if (!existing) {
      return apiError(c, 404, "COMMISSION_NOT_FOUND", "Commission not found");
    }
    await c.env.DB.prepare(
      "UPDATE commissions SET status = 'void', notes = 'Voided by admin', updated_at = datetime('now') WHERE id = ?",
    )
      .bind(id)
      .run();
    return c.json({ voided: true, id });
  },
);

// ------- /admin/cms/* (cms) ------------------------------------------------

type CmsTableConfig = {
  table: string;
  columns: readonly string[];
  required: readonly string[];
};

const CMS_TABLES: Record<string, CmsTableConfig> = {
  mannequins: {
    table: "mannequin_options",
    columns: ["label_en", "label_ar", "is_active", "sort_order", "preview_url"],
    required: ["label_en", "label_ar"],
  },
  fabrics: {
    table: "fabric_options",
    columns: [
      "name",
      "name_ar",
      "quality",
      "garment_type",
      "is_available",
      "swatch_url",
    ],
    required: ["name", "name_ar", "quality", "garment_type"],
  },
  presets: {
    table: "presets",
    columns: [
      "type",
      "name",
      "name_ar",
      "garment_type",
      "region",
      "image_url",
      "is_active",
    ],
    required: ["type", "name", "name_ar"],
  },
  "design-catalog": {
    table: "design_catalog_items",
    columns: [
      "section_title",
      "label_en",
      "label_ar",
      "image_url",
      "garment_type",
      "gender_lane",
      "sort_order",
      "is_active",
    ],
    required: ["section_title", "label_en", "label_ar", "image_url"],
  },
  "wedding-dresses": {
    table: "wedding_dresses",
    columns: [
      "label_en",
      "label_ar",
      "category",
      "image_url",
      "rent_price_per_day",
      "sale_price",
      "insurance_deposit",
      "is_active",
      "sort_order",
    ],
    required: ["label_en", "label_ar", "category", "image_url"],
  },
  accessories: {
    table: "accessories",
    columns: [
      "label_en",
      "label_ar",
      "category",
      "image_url",
      "sale_price",
      "description_en",
      "description_ar",
      "allow_addon",
      "is_active",
      "sort_order",
    ],
    required: ["label_en", "label_ar", "category", "image_url"],
  },
};

// "patterns" is shown as a separate menu item in the Flutter CMS screen even
// though it's just presets with a canonical type.
adminRoutes.get("/cms/:resource", requireAdmin(AdminScopes.cms), async (c) => {
  const resource = c.req.param("resource");
  const cfg = CMS_TABLES[resource];
  if (resource === "patterns") {
    const { results } = await c.env.DB.prepare(
      "SELECT * FROM presets WHERE type = 'pattern' ORDER BY created_at DESC LIMIT 200",
    ).all();
    return c.json(results);
  }
  if (!cfg) return apiError(c, 404, "UNKNOWN_RESOURCE", "Unknown CMS resource");
  const orderBy =
    resource === "design-catalog"
      ? "section_title ASC, sort_order ASC, label_en ASC"
      : "created_at DESC";
  const { results } = await c.env.DB.prepare(
    `SELECT * FROM ${cfg.table} ORDER BY ${orderBy} LIMIT 200`,
  ).all();
  return c.json(results);
});

function sanitizeCatalogFilename(name: string): string {
  const trimmed = name.trim();
  const base = trimmed.replace(/[^a-zA-Z0-9._-]+/g, "_").replace(/^_+/, "");
  if (base.length === 0) return `${crypto.randomUUID()}.png`;
  return base.slice(0, 120);
}

adminRoutes.post(
  "/upload/catalog-asset",
  requireAdmin(AdminScopes.cms),
  async (c) => {
    const formData = await c.req.formData();
    const file = formData.get("file") as File | null;
    if (!file) return apiError(c, 400, "FILE_REQUIRED", "No file provided");

    const category = (formData.get("category")?.toString() ?? "designs").trim().toLowerCase();
    if (category === "mannequins" && MANNEQUIN_CMS_MUTATIONS_DISABLED) {
      return apiError(c, 403, "MANNEQUIN_CMS_DISABLED", MANNEQUIN_CMS_DISABLED_MESSAGE);
    }
    if (category !== "designs" && category !== "configurator") {
      return apiError(
        c,
        400,
        "INVALID_CATALOG_CATEGORY",
        "category must be designs or configurator",
      );
    }

    const allowedTypes = ["image/jpeg", "image/png", "image/webp"];
    if (!allowedTypes.includes(file.type)) {
      return apiError(c, 400, "UNSUPPORTED_FILE_TYPE", "Unsupported file type");
    }
    if (file.size > 8 * 1024 * 1024) {
      return apiError(c, 400, "FILE_TOO_LARGE", "File exceeds 8MB limit");
    }

    const ext = file.type.split("/")[1] ?? "png";
    const requestedName = formData.get("filename")?.toString().trim() ?? file.name;
    const safeName = sanitizeCatalogFilename(
      requestedName.includes(".") ? requestedName : `${requestedName}.${ext}`,
    );
    const key = `catalog/${category}/${safeName}`;

    await c.env.R2.put(key, await file.arrayBuffer(), {
      httpMetadata: { contentType: file.type },
    });

    const url = buildR2PublicUrl(c.env, key);
    if (!url) {
      return apiError(
        c,
        503,
        "R2_PUBLIC_URL_NOT_CONFIGURED",
        "File storage is not configured (CLOUDFLARE_R2_BASE_URL).",
      );
    }

    return c.json(
      {
        url,
        key,
        assetPath: `assets/images/${category}/${safeName}`,
        category,
      },
      201,
    );
  },
);

adminRoutes.post("/cms/:resource", requireAdmin(AdminScopes.cms), async (c) => {
  const resource = c.req.param("resource");
  if (resource === "mannequins" && MANNEQUIN_CMS_MUTATIONS_DISABLED) {
    return apiError(c, 403, "MANNEQUIN_CMS_DISABLED", MANNEQUIN_CMS_DISABLED_MESSAGE);
  }
  let cfg = CMS_TABLES[resource];
  if (resource === "patterns") {
    cfg = {
      table: "presets",
      columns: [
        "type",
        "name",
        "name_ar",
        "garment_type",
        "region",
        "image_url",
        "is_active",
      ],
      required: ["name", "name_ar"],
    };
  }
  if (!cfg) return apiError(c, 404, "UNKNOWN_RESOURCE", "Unknown CMS resource");
  const body = (await c.req.json().catch(() => ({}))) as Record<string, unknown>;
  if (resource === "patterns") {
    body.type = "pattern";
  }
  for (const field of cfg.required) {
    if (!body[field] || String(body[field]).trim().length === 0) {
      return apiError(c, 400, "FIELD_REQUIRED", `${field} is required`);
    }
  }
  const id = uuidv4();
  const cols = ["id", ...cfg.columns.filter((col) => col in body)];
  const values = [id, ...cols.slice(1).map((col) => body[col])];
  const placeholders = cols.map(() => "?").join(", ");
  await c.env.DB.prepare(
    `INSERT INTO ${cfg.table} (${cols.join(", ")}) VALUES (${placeholders})`,
  )
    .bind(...(values as Array<string | number | null>))
    .run();
  const row = await c.env.DB.prepare(
    `SELECT * FROM ${cfg.table} WHERE id = ?`,
  )
    .bind(id)
    .first<Record<string, unknown>>();
  return c.json(row, 201);
});

adminRoutes.patch("/cms/:resource/:id", requireAdmin(AdminScopes.cms), async (c) => {
  const resource = c.req.param("resource");
  if (resource === "mannequins" && MANNEQUIN_CMS_MUTATIONS_DISABLED) {
    return apiError(c, 403, "MANNEQUIN_CMS_DISABLED", MANNEQUIN_CMS_DISABLED_MESSAGE);
  }
  let cfg = CMS_TABLES[resource];
  if (resource === "patterns") {
    cfg = {
      table: "presets",
      columns: [
        "name",
        "name_ar",
        "garment_type",
        "region",
        "image_url",
        "is_active",
      ],
      required: [],
    };
  }
  if (!cfg) return apiError(c, 404, "UNKNOWN_RESOURCE", "Unknown CMS resource");
  const id = c.req.param("id");
  const body = (await c.req.json().catch(() => ({}))) as Record<string, unknown>;
  const setClauses: string[] = [];
  const bindings: Array<string | number | null> = [];
  for (const col of cfg.columns) {
    if (body[col] !== undefined) {
      setClauses.push(`${col} = ?`);
      bindings.push(body[col] as string | number | null);
    }
  }
  if (setClauses.length === 0) {
    return apiError(c, 400, "NO_FIELDS", "Nothing to update");
  }
  bindings.push(id);
  await c.env.DB.prepare(
    `UPDATE ${cfg.table} SET ${setClauses.join(", ")} WHERE id = ?`,
  )
    .bind(...bindings)
    .run();
  const row = await c.env.DB.prepare(
    `SELECT * FROM ${cfg.table} WHERE id = ?`,
  )
    .bind(id)
    .first<Record<string, unknown>>();
  return c.json(row);
});

// ------- /admin/configurator/* (cms) ---------------------------------------

type ConfiguratorTable = "configurator_templates" | "configurator_slots" | "configurator_options";

const CONFIGURATOR_RESOURCES: Record<
  string,
  { table: ConfiguratorTable; columns: readonly string[]; required: readonly string[] }
> = {
  configurator_templates: {
    table: "configurator_templates",
    columns: [
      "name_en",
      "name_ar",
      "garment_type",
      "region_tag",
      "sort_order",
      "is_active",
      "required_slot_keys",
    ],
    required: ["name_en", "name_ar"],
  },
  configurator_slots: {
    table: "configurator_slots",
    columns: ["template_id", "slot_key", "title_en", "title_ar", "sort_order", "is_active"],
    required: ["template_id", "slot_key", "title_en", "title_ar"],
  },
  configurator_options: {
    table: "configurator_options",
    columns: [
      "slot_id",
      "option_key",
      "label_en",
      "label_ar",
      "asset_url",
      "metadata_json",
      "sort_order",
      "is_active",
    ],
    required: ["slot_id", "option_key", "label_en", "label_ar"],
  },
};

adminRoutes.get(
  "/cms/configurator/:resource",
  requireAdmin(AdminScopes.cms),
  async (c) => {
    const resource = c.req.param("resource");
    const cfg = CONFIGURATOR_RESOURCES[resource];
    if (!cfg) return apiError(c, 404, "UNKNOWN_RESOURCE", "Unknown configurator resource");

    const templateId = c.req.query("templateId")?.trim() ?? "";
    const slotId = c.req.query("slotId")?.trim() ?? "";

    if (resource === "configurator_slots" && templateId.length > 0) {
      const { results } = await c.env.DB.prepare(
        `SELECT * FROM ${cfg.table} WHERE template_id = ? ORDER BY sort_order ASC LIMIT 500`,
      )
        .bind(templateId)
        .all();
      return c.json(results);
    }
    if (resource === "configurator_options" && slotId.length > 0) {
      const { results } = await c.env.DB.prepare(
        `SELECT * FROM ${cfg.table} WHERE slot_id = ? ORDER BY sort_order ASC LIMIT 500`,
      )
        .bind(slotId)
        .all();
      return c.json(results);
    }

    const { results } = await c.env.DB.prepare(
      `SELECT * FROM ${cfg.table} ORDER BY sort_order ASC, created_at DESC LIMIT 500`,
    ).all();
    return c.json(results);
  },
);

adminRoutes.post(
  "/cms/configurator/:resource",
  requireAdmin(AdminScopes.cms),
  async (c) => {
    const resource = c.req.param("resource");
    const cfg = CONFIGURATOR_RESOURCES[resource];
    if (!cfg) return apiError(c, 404, "UNKNOWN_RESOURCE", "Unknown configurator resource");
    const body = (await c.req.json().catch(() => ({}))) as Record<string, unknown>;
    for (const field of cfg.required) {
      if (!body[field] || String(body[field]).trim().length === 0) {
        return apiError(c, 400, "FIELD_REQUIRED", `${field} is required`);
      }
    }
    const id = uuidv4();
    const cols = ["id", ...cfg.columns.filter((col) => col in body)];
    const values = [id, ...cols.slice(1).map((col) => body[col])];
    const placeholders = cols.map(() => "?").join(", ");
    await c.env.DB.prepare(
      `INSERT INTO ${cfg.table} (${cols.join(", ")}) VALUES (${placeholders})`,
    )
      .bind(...(values as Array<string | number | null>))
      .run();
    const row = await c.env.DB.prepare(`SELECT * FROM ${cfg.table} WHERE id = ?`)
      .bind(id)
      .first<Record<string, unknown>>();
    return c.json(row, 201);
  },
);

adminRoutes.patch(
  "/cms/configurator/:resource/:id",
  requireAdmin(AdminScopes.cms),
  async (c) => {
    const resource = c.req.param("resource");
    const cfg = CONFIGURATOR_RESOURCES[resource];
    if (!cfg) return apiError(c, 404, "UNKNOWN_RESOURCE", "Unknown configurator resource");
    const id = c.req.param("id");
    const body = (await c.req.json().catch(() => ({}))) as Record<string, unknown>;
    const setClauses: string[] = [];
    const bindings: Array<string | number | null> = [];
    for (const col of cfg.columns) {
      if (body[col] !== undefined) {
        setClauses.push(`${col} = ?`);
        bindings.push(body[col] as string | number | null);
      }
    }
    if (resource === "configurator_templates") {
      setClauses.push("updated_at = datetime('now')");
    }
    if (setClauses.length === 0) {
      return apiError(c, 400, "NO_FIELDS", "Nothing to update");
    }
    bindings.push(id);
    const table = cfg.table;
    await c.env.DB.prepare(`UPDATE ${table} SET ${setClauses.join(", ")} WHERE id = ?`)
      .bind(...bindings)
      .run();
    const row = await c.env.DB.prepare(`SELECT * FROM ${table} WHERE id = ?`)
      .bind(id)
      .first<Record<string, unknown>>();
    return c.json(row);
  },
);

adminRoutes.delete(
  "/cms/configurator/:resource/:id",
  requireAdmin(AdminScopes.cms),
  async (c) => {
    const resource = c.req.param("resource");
    const cfg = CONFIGURATOR_RESOURCES[resource];
    if (!cfg) return apiError(c, 404, "UNKNOWN_RESOURCE", "Unknown configurator resource");
    const id = c.req.param("id");
    await c.env.DB.prepare(`DELETE FROM ${cfg.table} WHERE id = ?`).bind(id).run();
    return c.json({ deleted: true, id });
  },
);

adminRoutes.delete("/cms/:resource/:id", requireAdmin(AdminScopes.cms), async (c) => {
  const resource = c.req.param("resource");
  if (resource === "mannequins" && MANNEQUIN_CMS_MUTATIONS_DISABLED) {
    return apiError(c, 403, "MANNEQUIN_CMS_DISABLED", MANNEQUIN_CMS_DISABLED_MESSAGE);
  }
  let cfg = CMS_TABLES[resource];
  if (resource === "patterns") {
    cfg = {
      table: "presets",
      columns: [],
      required: [],
    };
  }
  if (!cfg) return apiError(c, 404, "UNKNOWN_RESOURCE", "Unknown CMS resource");
  const id = c.req.param("id");
  await c.env.DB.prepare(`DELETE FROM ${cfg.table} WHERE id = ?`)
    .bind(id)
    .run();
  return c.json({ deleted: true, id });
});

// ------- /admin/complaints (complaints) ------------------------------------

adminRoutes.get("/complaints", requireAdmin(AdminScopes.complaints), async (c) => {
  const status = c.req.query("status")?.trim().toLowerCase() ?? "";
  let query = `SELECT com.*, u.name AS author_name, u.email AS author_email
               FROM complaints com
               LEFT JOIN users u ON u.id = com.user_id`;
  const bindings: string[] = [];
  if (status.length > 0) {
    query += " WHERE com.status = ?";
    bindings.push(status);
  }
  query += " ORDER BY com.created_at DESC LIMIT 200";
  const { results } = await c.env.DB.prepare(query)
    .bind(...bindings)
    .all();
  return c.json(results);
});

adminRoutes.patch("/complaints/:id", requireAdmin(AdminScopes.complaints), async (c) => {
  const id = c.req.param("id");
  const body = (await c.req.json().catch(() => ({}))) as Record<string, unknown>;
  const status = String(body.status ?? "").trim().toLowerCase();
  if (!["open", "resolved", "rejected"].includes(status)) {
    return apiError(c, 400, "INVALID_STATUS", "Invalid complaint status");
  }
  const resolution = body.resolution ? String(body.resolution).trim() : null;
  const adminId = c.get("userId") as string;
  const resolvedAt = status === "open" ? null : new Date().toISOString();
  await c.env.DB.prepare(
    `UPDATE complaints
     SET status = ?, resolution = COALESCE(?, resolution),
         resolved_by = ?, resolved_at = ?
     WHERE id = ?`,
  )
    .bind(status, resolution, status === "open" ? null : adminId, resolvedAt, id)
    .run();
  const row = await c.env.DB.prepare(
    "SELECT * FROM complaints WHERE id = ?",
  )
    .bind(id)
    .first<Record<string, unknown>>();
  return c.json(row);
});

// ------- /admin/stats (no scope required) ----------------------------------

adminRoutes.get("/stats", requireAdmin(), async (c) => {
  const [usersByRole, ordersByStatus, commissionsByStatus] = await Promise.all([
    c.env.DB.prepare(
      "SELECT role, COUNT(*) AS count FROM users GROUP BY role",
    ).all<{ role: string; count: number }>(),
    c.env.DB.prepare(
      "SELECT status, COUNT(*) AS count FROM orders GROUP BY status",
    ).all<{ status: string; count: number }>(),
    c.env.DB.prepare(
      "SELECT status, COUNT(*) AS count FROM commissions GROUP BY status",
    ).all<{ status: string; count: number }>(),
  ]);
  const openComplaintRow = await c.env.DB.prepare(
    "SELECT COUNT(*) AS count FROM complaints WHERE status = 'open'",
  ).first<{ count: number }>();
  return c.json({
    usersByRole: usersByRole.results,
    ordersByStatus: ordersByStatus.results,
    commissionsByStatus: commissionsByStatus.results,
    openComplaints: openComplaintRow?.count ?? 0,
  });
});

adminRoutes.get("/render-metrics", requireAdmin(), async (c) => {
  const windowHours = Math.min(
    168,
    Math.max(1, Number(c.req.query("windowHours") ?? 24)),
  );
  const lookbackIso = new Date(
    Date.now() - windowHours * 60 * 60 * 1000,
  ).toISOString();
  let rows: Array<{
    status: string | null;
    provider_status: string | null;
    error_message: string | null;
    created_at: string | null;
    completed_at: string | null;
    failed_at: string | null;
    attempt_count: number | null;
  }> = [];
  try {
    const result = await c.env.DB.prepare(
      `SELECT status, provider_status, error_message, created_at, completed_at, failed_at, attempt_count
       FROM design_render_jobs
       WHERE created_at >= ?
       ORDER BY created_at DESC
       LIMIT 2000`,
    )
      .bind(lookbackIso)
      .all<{
        status: string | null;
        provider_status: string | null;
        error_message: string | null;
        created_at: string | null;
        completed_at: string | null;
        failed_at: string | null;
        attempt_count: number | null;
      }>();
    rows = result.results ?? [];
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    if (/no such table/i.test(msg)) {
      return c.json({
        windowHours,
        totalJobs: 0,
        successRate: 0,
        p50LatencyMs: 0,
        p95LatencyMs: 0,
        failuresByCategory: {},
        retries: { jobsWithRetry: 0, avgAttempts: 0 },
      });
    }
    throw e;
  }

  const totalJobs = rows.length;
  const completed = rows.filter((r) => (r.status ?? "") === "completed");
  const failed = rows.filter((r) => (r.status ?? "") === "failed");
  const successRate = totalJobs === 0 ? 0 : completed.length / totalJobs;
  const latenciesMs = completed
    .map((row) => {
      const start = row.created_at ? Date.parse(row.created_at) : NaN;
      const end = row.completed_at ? Date.parse(row.completed_at) : NaN;
      if (!Number.isFinite(start) || !Number.isFinite(end) || end < start) {
        return null;
      }
      return end - start;
    })
    .filter((v): v is number => v != null);

  const failuresByCategory: Record<string, number> = {};
  for (const row of failed) {
    const category = _failureCategory(
      row.error_message ?? "",
      row.provider_status ?? "",
    );
    failuresByCategory[category] = (failuresByCategory[category] ?? 0) + 1;
  }

  const attempts = rows
    .map((r) => r.attempt_count ?? 0)
    .filter((n) => Number.isFinite(n) && n >= 0);
  const jobsWithRetry = attempts.filter((n) => n > 1).length;
  const avgAttempts =
    attempts.length === 0
      ? 0
      : attempts.reduce((sum, n) => sum + n, 0) / attempts.length;

  return c.json({
    windowHours,
    totalJobs,
    successRate,
    p50LatencyMs: _percentile(latenciesMs, 50),
    p95LatencyMs: _percentile(latenciesMs, 95),
    failuresByCategory,
    retries: {
      jobsWithRetry,
      avgAttempts,
    },
  });
});

// ---------------------------------------------------------------------------
// Fashion news CMS (scoped to AdminScopes.news)
// ---------------------------------------------------------------------------

type FashionNewsRow = {
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

function shapeAdminNewsRow(row: FashionNewsRow) {
  return {
    id: row.id,
    titleEn: row.title_en,
    titleAr: row.title_ar,
    summaryEn: row.summary_en,
    summaryAr: row.summary_ar,
    bodyEn: row.body_en,
    bodyAr: row.body_ar,
    coverImageUrl: row.cover_image_url ?? null,
    isPublished: Boolean(row.is_published),
    isFeatured: Boolean(row.is_featured),
    publishedAt: row.published_at,
    authorId: row.author_id,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

function asBool(value: unknown): boolean {
  if (value === true || value === 1 || value === "1") return true;
  if (typeof value === "string") return value.toLowerCase() === "true";
  return false;
}

adminRoutes.get("/news", requireAdmin(AdminScopes.news), async (c) => {
  const { results } = await c.env.DB.prepare(
    `SELECT * FROM fashion_news ORDER BY created_at DESC LIMIT 200`,
  ).all<FashionNewsRow>();
  return c.json((results ?? []).map(shapeAdminNewsRow));
});

adminRoutes.post("/news", requireAdmin(AdminScopes.news), async (c) => {
  const authorId = c.get("userId") as string;
  const body = (await c.req.json().catch(() => ({}))) as Record<string, unknown>;
  const titleEn = String(body.titleEn ?? body.title_en ?? "").trim();
  const titleAr = String(body.titleAr ?? body.title_ar ?? "").trim();
  if (!titleEn || !titleAr) {
    return apiError(c, 400, "VALIDATION", "titleEn and titleAr are required");
  }

  const id = uuidv4();
  const now = new Date().toISOString();
  const isPublished = asBool(body.isPublished ?? body.is_published);
  const isFeatured = asBool(body.isFeatured ?? body.is_featured);
  const publishedAt = isPublished ? now : null;

  if (isFeatured) {
    await c.env.DB.prepare("UPDATE fashion_news SET is_featured = 0").run();
  }

  await c.env.DB.prepare(
    `INSERT INTO fashion_news (
      id, title_en, title_ar, summary_en, summary_ar, body_en, body_ar,
      cover_image_url, is_published, is_featured, published_at, author_id,
      created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
  )
    .bind(
      id,
      titleEn,
      titleAr,
      String(body.summaryEn ?? body.summary_en ?? "").trim(),
      String(body.summaryAr ?? body.summary_ar ?? "").trim(),
      String(body.bodyEn ?? body.body_en ?? "").trim(),
      String(body.bodyAr ?? body.body_ar ?? "").trim(),
      body.coverImageUrl?.toString() ?? body.cover_image_url?.toString() ?? null,
      isPublished ? 1 : 0,
      isFeatured ? 1 : 0,
      publishedAt,
      authorId,
      now,
      now,
    )
    .run();

  const row = await c.env.DB.prepare("SELECT * FROM fashion_news WHERE id = ?")
    .bind(id)
    .first<FashionNewsRow>();
  return c.json(shapeAdminNewsRow(row!), 201);
});

adminRoutes.patch("/news/:id", requireAdmin(AdminScopes.news), async (c) => {
  const id = c.req.param("id");
  const existing = await c.env.DB.prepare("SELECT * FROM fashion_news WHERE id = ?")
    .bind(id)
    .first<FashionNewsRow>();
  if (!existing) {
    return apiError(c, 404, "NOT_FOUND", "News article not found");
  }

  const body = (await c.req.json().catch(() => ({}))) as Record<string, unknown>;
  const now = new Date().toISOString();

  const titleEn =
    body.titleEn !== undefined || body.title_en !== undefined
      ? String(body.titleEn ?? body.title_en ?? "").trim()
      : existing.title_en;
  const titleAr =
    body.titleAr !== undefined || body.title_ar !== undefined
      ? String(body.titleAr ?? body.title_ar ?? "").trim()
      : existing.title_ar;
  if (!titleEn || !titleAr) {
    return apiError(c, 400, "VALIDATION", "titleEn and titleAr are required");
  }

  const isPublished =
    body.isPublished !== undefined || body.is_published !== undefined
      ? asBool(body.isPublished ?? body.is_published)
      : Boolean(existing.is_published);
  const isFeatured =
    body.isFeatured !== undefined || body.is_featured !== undefined
      ? asBool(body.isFeatured ?? body.is_featured)
      : Boolean(existing.is_featured);

  let publishedAt = existing.published_at;
  if (isPublished && !publishedAt) {
    publishedAt = now;
  }
  if (!isPublished) {
    publishedAt = null;
  }

  if (isFeatured) {
    await c.env.DB.prepare("UPDATE fashion_news SET is_featured = 0 WHERE id != ?")
      .bind(id)
      .run();
  }

  await c.env.DB.prepare(
    `UPDATE fashion_news SET
      title_en = ?, title_ar = ?,
      summary_en = ?, summary_ar = ?,
      body_en = ?, body_ar = ?,
      cover_image_url = ?,
      is_published = ?, is_featured = ?,
      published_at = ?,
      updated_at = ?
     WHERE id = ?`,
  )
    .bind(
      titleEn,
      titleAr,
      body.summaryEn !== undefined || body.summary_en !== undefined
        ? String(body.summaryEn ?? body.summary_en ?? "").trim()
        : existing.summary_en,
      body.summaryAr !== undefined || body.summary_ar !== undefined
        ? String(body.summaryAr ?? body.summary_ar ?? "").trim()
        : existing.summary_ar,
      body.bodyEn !== undefined || body.body_en !== undefined
        ? String(body.bodyEn ?? body.body_en ?? "").trim()
        : existing.body_en,
      body.bodyAr !== undefined || body.body_ar !== undefined
        ? String(body.bodyAr ?? body.body_ar ?? "").trim()
        : existing.body_ar,
      body.coverImageUrl !== undefined || body.cover_image_url !== undefined
        ? body.coverImageUrl?.toString() ?? body.cover_image_url?.toString() ?? null
        : existing.cover_image_url,
      isPublished ? 1 : 0,
      isFeatured ? 1 : 0,
      publishedAt,
      now,
      id,
    )
    .run();

  const row = await c.env.DB.prepare("SELECT * FROM fashion_news WHERE id = ?")
    .bind(id)
    .first<FashionNewsRow>();
  return c.json(shapeAdminNewsRow(row!));
});

adminRoutes.delete("/news/:id", requireAdmin(AdminScopes.news), async (c) => {
  const id = c.req.param("id");
  const result = await c.env.DB.prepare("DELETE FROM fashion_news WHERE id = ?")
    .bind(id)
    .run();
  if (!result.meta.changes) {
    return apiError(c, 404, "NOT_FOUND", "News article not found");
  }
  return c.body(null, 204);
});

adminRoutes.post(
  "/upload/news-asset",
  requireAdmin(AdminScopes.news),
  async (c) => {
    const formData = await c.req.formData();
    const file = formData.get("file") as File | null;
    if (!file) return apiError(c, 400, "FILE_REQUIRED", "No file provided");

    const allowedTypes = ["image/jpeg", "image/png", "image/webp"];
    if (!allowedTypes.includes(file.type)) {
      return apiError(c, 400, "UNSUPPORTED_FILE_TYPE", "Unsupported file type");
    }
    if (file.size > 8 * 1024 * 1024) {
      return apiError(c, 400, "FILE_TOO_LARGE", "File exceeds 8MB limit");
    }

    const ext = file.type.split("/")[1] ?? "png";
    const requestedName = formData.get("filename")?.toString().trim() ?? file.name;
    const safeName = sanitizeCatalogFilename(
      requestedName.includes(".") ? requestedName : `${requestedName}.${ext}`,
    );
    const key = `news/covers/${safeName}`;

    await c.env.R2.put(key, await file.arrayBuffer(), {
      httpMetadata: { contentType: file.type },
    });

    const url = buildR2PublicUrl(c.env, key);
    if (!url) {
      return apiError(
        c,
        503,
        "R2_PUBLIC_URL_NOT_CONFIGURED",
        "File storage is not configured (CLOUDFLARE_R2_BASE_URL).",
      );
    }

    return c.json({ url, key }, 201);
  },
);

function _failureCategory(errorMessage: string, providerStatus: string): string {
  const message = errorMessage.toLowerCase();
  if (providerStatus.toLowerCase() === "timeout" || message.includes("abort")) {
    return "timeout";
  }
  if (message.includes("503") || message.includes("provider unavailable")) {
    return "provider_5xx";
  }
  if (message.includes("missing") && message.includes("image")) {
    return "missing_source_image";
  }
  if (message.includes("parse")) {
    return "provider_parse_error";
  }
  return "other";
}

function _percentile(values: number[], p: number): number {
  if (values.length === 0) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  const idx = Math.min(
    sorted.length - 1,
    Math.max(0, Math.ceil((p / 100) * sorted.length) - 1),
  );
  return sorted[idx];
}
