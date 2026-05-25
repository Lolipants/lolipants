import { Hono, type Context } from "hono";
import { v4 as uuidv4 } from "uuid";
import { apiError } from "../lib/http";
import {
  freezeNegotiatedLineItems,
  negotiationExpiryIso,
  negotiationFloor,
  NEGOTIATION_FLOOR_RATIO,
  quoteLockExpiryIso,
  serializeNegotiation,
  type NegotiationRow,
} from "../lib/quoteNegotiation";
import { quoteForTailorId } from "../lib/tailorAssignment";
import { quoteNegotiationTemplates, sendToUser } from "../lib/onesignal";
import { requireAuth, requireRole } from "../middleware/auth";
import type { AppVariables, Env } from "../types";

export const quoteNegotiationRoutes = new Hono<{
  Bindings: Env;
  Variables: AppVariables;
}>();

quoteNegotiationRoutes.use("*", requireAuth);

const OPEN_STATUSES = new Set(["open", "tailor_review", "countered"]);

async function loadMessages(db: D1Database, negotiationId: string) {
  const { results } = await db
    .prepare(
      "SELECT * FROM quote_negotiation_messages WHERE negotiation_id = ? ORDER BY created_at ASC",
    )
    .bind(negotiationId)
    .all();
  return results.map((m) => {
    const row = m as Record<string, unknown>;
    return {
      id: row.id,
      negotiationId: row.negotiation_id,
      senderId: row.sender_id,
      senderRole: row.sender_role,
      body: row.body,
      createdAt: row.created_at,
    };
  });
}

async function appendMessage(
  db: D1Database,
  input: {
    negotiationId: string;
    senderId: string;
    senderRole: "customer" | "tailor" | "system";
    body: string;
  },
) {
  await db
    .prepare(
      `INSERT INTO quote_negotiation_messages
        (id, negotiation_id, sender_id, sender_role, body)
       VALUES (?, ?, ?, ?, ?)`,
    )
    .bind(uuidv4(), input.negotiationId, input.senderId, input.senderRole, input.body)
    .run();
}

async function loadNegotiation(
  db: D1Database,
  id: string,
): Promise<NegotiationRow | null> {
  return db
    .prepare("SELECT * FROM quote_negotiations WHERE id = ?")
    .bind(id)
    .first<NegotiationRow>();
}

async function detailPayload(db: D1Database, row: NegotiationRow) {
  const messages = await loadMessages(db, row.id);
  const design = await db
    .prepare("SELECT id, name, garment_type, render_metadata FROM designs WHERE id = ?")
    .bind(row.design_id)
    .first<Record<string, unknown>>();
  const tailor = await db
    .prepare(
      `SELECT u.name AS tailor_name, tp.shop_name
       FROM users u
       LEFT JOIN tailor_profiles tp ON tp.user_id = u.id
       WHERE u.id = ?`,
    )
    .bind(row.tailor_id)
    .first<{ tailor_name: string | null; shop_name: string | null }>();
  return {
    negotiation: serializeNegotiation(row),
    messages,
    design,
    tailorName: tailor?.tailor_name ?? null,
    shopName: tailor?.shop_name ?? null,
  };
}

function assertOfferFloor(listTotal: number, offeredTotal: number) {
  const floor = negotiationFloor(listTotal);
  if (offeredTotal < floor) {
    return `Offer must be at least ${floor} QAR (${Math.round(NEGOTIATION_FLOOR_RATIO * 100)}% of list price)`;
  }
  return null;
}

quoteNegotiationRoutes.post("/", async (c) => {
  const userId = c.get("userId") as string;
  const body = (await c.req.json()) as Record<string, unknown>;
  const designId = String(body.designId ?? "").trim();
  const tailorId = String(body.tailorId ?? "").trim();
  const offeredTotal = Number(body.offeredTotal ?? body.offered_total);
  const customerNote = body.customerNote?.toString().trim() || body.customer_note?.toString().trim() || null;
  const deliveryAddress = String(body.deliveryAddress ?? body.delivery_address ?? "").trim();
  const deliveryCity = String(body.deliveryCity ?? body.delivery_city ?? "").trim();
  const deliveryPhone = String(body.deliveryPhone ?? body.delivery_phone ?? "").trim();
  const lat = Number(body.deliveryLat ?? body.delivery_lat);
  const lng = Number(body.deliveryLng ?? body.delivery_lng);

  if (!designId || !tailorId) {
    return apiError(c, 400, "FIELDS_REQUIRED", "designId and tailorId are required");
  }
  if (!Number.isFinite(offeredTotal) || offeredTotal <= 0) {
    return apiError(c, 400, "INVALID_OFFER", "offeredTotal must be a positive number");
  }
  if (!deliveryAddress || !deliveryCity || !deliveryPhone || !Number.isFinite(lat) || !Number.isFinite(lng)) {
    return apiError(c, 400, "DELIVERY_REQUIRED", "Delivery address, city, phone, and coordinates are required");
  }

  const design = await c.env.DB.prepare(
    "SELECT id, user_id, garment_type, fabric_quality FROM designs WHERE id = ?",
  )
    .bind(designId)
    .first<{ id: string; user_id: string; garment_type: string; fabric_quality: string | null }>();
  if (!design) return apiError(c, 404, "DESIGN_NOT_FOUND", "Design not found");
  if (design.user_id !== userId) {
    return apiError(c, 403, "DESIGN_NOT_OWNED", "You can only negotiate for your own designs");
  }

  const existingOpen = await c.env.DB.prepare(
    `SELECT id FROM quote_negotiations
     WHERE user_id = ? AND tailor_id = ? AND design_id = ?
       AND status IN ('open', 'tailor_review', 'countered') LIMIT 1`,
  )
    .bind(userId, tailorId, designId)
    .first<{ id: string }>();
  if (existingOpen) {
    return apiError(
      c,
      409,
      "NEGOTIATION_EXISTS",
      "An open negotiation already exists for this tailor",
    );
  }

  const quote = await quoteForTailorId({
    db: c.env.DB,
    tailorId,
    design: { garment_type: design.garment_type, fabric_quality: design.fabric_quality },
    city: deliveryCity,
    deliveryLat: lat,
    deliveryLng: lng,
  });
  if (!quote) {
    return apiError(c, 404, "NO_TAILOR_QUOTE", "Tailor cannot price this design at your location");
  }

  const floorMsg = assertOfferFloor(quote.total, Math.round(offeredTotal));
  if (floorMsg) return apiError(c, 400, "OFFER_TOO_LOW", floorMsg);

  const id = uuidv4();
  await c.env.DB.prepare(
    `INSERT INTO quote_negotiations (
      id, user_id, tailor_id, design_id,
      delivery_city, delivery_lat, delivery_lng, delivery_address, delivery_phone,
      list_base_price, list_fabric_fee, list_delivery_fee, list_total,
      price_plan_id, currency, offered_total, offered_by, customer_note,
      status, expires_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'customer', ?, 'tailor_review', ?)`,
  )
    .bind(
      id,
      userId,
      tailorId,
      designId,
      deliveryCity,
      lat,
      lng,
      deliveryAddress,
      deliveryPhone,
      quote.basePrice,
      quote.fabricFee,
      quote.deliveryFee,
      quote.total,
      quote.pricePlanId,
      quote.currency,
      Math.round(offeredTotal),
      customerNote,
      negotiationExpiryIso(),
    )
    .run();

  const noteLine = customerNote ? `: "${customerNote}"` : "";
  await appendMessage(c.env.DB, {
    negotiationId: id,
    senderId: userId,
    senderRole: "customer",
    body: `Offered ${Math.round(offeredTotal)} ${quote.currency}${noteLine}`,
  });

  const tpl = quoteNegotiationTemplates.quote_negotiation_received;
  void sendToUser({
    env: c.env,
    userIds: [tailorId],
    headings: tpl.headings,
    contents: tpl.contents,
    route: `/tailor/price-requests/${id}`,
  });

  const row = await loadNegotiation(c.env.DB, id);
  if (!row) return apiError(c, 500, "NEGOTIATION_CREATE_FAILED", "Could not load negotiation");
  return c.json(await detailPayload(c.env.DB, row), 201);
});

quoteNegotiationRoutes.get("/", async (c) => {
  const userId = c.get("userId") as string;
  const status = c.req.query("status")?.trim();
  let sql =
    "SELECT * FROM quote_negotiations WHERE user_id = ?";
  const binds: unknown[] = [userId];
  if (status) {
    sql += " AND status = ?";
    binds.push(status);
  } else {
    sql += " AND status IN ('open', 'tailor_review', 'countered', 'accepted')";
  }
  sql += " ORDER BY updated_at DESC LIMIT 50";
  const { results } = await c.env.DB.prepare(sql)
    .bind(...binds)
    .all();
  return c.json({
    negotiations: (results as NegotiationRow[]).map(serializeNegotiation),
  });
});

quoteNegotiationRoutes.get("/tailor", requireRole("tailor"), async (c) => {
  const tailorId = c.get("userId") as string;
  const status = c.req.query("status")?.trim();
  let sql = "SELECT * FROM quote_negotiations WHERE tailor_id = ?";
  const binds: unknown[] = [tailorId];
  if (status) {
    sql += " AND status = ?";
    binds.push(status);
  } else {
    sql += " AND status IN ('tailor_review', 'countered')";
  }
  sql += " ORDER BY updated_at DESC LIMIT 50";
  const { results } = await c.env.DB.prepare(sql)
    .bind(...binds)
    .all();
  return c.json({
    negotiations: (results as NegotiationRow[]).map(serializeNegotiation),
  });
});

quoteNegotiationRoutes.get("/:id", async (c) => {
  const userId = c.get("userId") as string;
  const role = c.get("userRole") as string;
  const id = c.req.param("id");
  const row = await loadNegotiation(c.env.DB, id);
  if (!row) return apiError(c, 404, "NOT_FOUND", "Negotiation not found");
  if (row.user_id !== userId && row.tailor_id !== userId && role !== "admin") {
    return apiError(c, 403, "FORBIDDEN", "Not allowed to view this negotiation");
  }
  return c.json(await detailPayload(c.env.DB, row));
});

quoteNegotiationRoutes.post("/:id/messages", async (c) => {
  const userId = c.get("userId") as string;
  const id = c.req.param("id");
  const body = (await c.req.json()) as Record<string, unknown>;
  const text = String(body.body ?? body.message ?? "").trim();
  if (!text) return apiError(c, 400, "BODY_REQUIRED", "Message body is required");

  const row = await loadNegotiation(c.env.DB, id);
  if (!row) return apiError(c, 404, "NOT_FOUND", "Negotiation not found");
  if (!OPEN_STATUSES.has(row.status) && row.status !== "accepted") {
    return apiError(c, 400, "NEGOTIATION_CLOSED", "Negotiation is no longer open for messages");
  }

  let role: "customer" | "tailor";
  if (row.user_id === userId) role = "customer";
  else if (row.tailor_id === userId) role = "tailor";
  else return apiError(c, 403, "FORBIDDEN", "Not a participant");

  await appendMessage(c.env.DB, {
    negotiationId: id,
    senderId: userId,
    senderRole: role,
    body: text,
  });
  await c.env.DB.prepare(
    "UPDATE quote_negotiations SET updated_at = datetime('now') WHERE id = ?",
  )
    .bind(id)
    .run();

  const notifyUserId = role === "customer" ? row.tailor_id : row.user_id;
  const preview = text.length > 120 ? `${text.slice(0, 117)}...` : text;
  const tpl = quoteNegotiationTemplates.quote_negotiation_message;
  void sendToUser({
    env: c.env,
    userIds: [notifyUserId],
    headings: tpl.headings,
    contents: {
      en: preview,
      ar: preview,
    },
    route:
      role === "customer"
        ? `/tailor/price-requests/${id}`
        : `/order/quote-negotiation/${id}`,
  });

  const messages = await loadMessages(c.env.DB, id);
  return c.json({ messages });
});

quoteNegotiationRoutes.post("/:id/counter", requireRole("tailor"), async (c) => {
  const tailorId = c.get("userId") as string;
  const id = c.req.param("id");
  const body = (await c.req.json()) as Record<string, unknown>;
  const counterTotal = Number(body.offeredTotal ?? body.offered_total);
  const note = body.note?.toString().trim() || null;

  const row = await loadNegotiation(c.env.DB, id);
  if (!row) return apiError(c, 404, "NOT_FOUND", "Negotiation not found");
  if (row.tailor_id !== tailorId) return apiError(c, 403, "FORBIDDEN", "Not your negotiation");
  if (row.status !== "tailor_review") {
    return apiError(c, 400, "INVALID_STATE", "Cannot counter in current state");
  }
  if (row.tailor_counter_used) {
    return apiError(c, 400, "COUNTER_LIMIT", "Only one counter offer is allowed");
  }
  if (!Number.isFinite(counterTotal) || counterTotal <= 0) {
    return apiError(c, 400, "INVALID_OFFER", "offeredTotal must be positive");
  }
  const floorMsg = assertOfferFloor(row.list_total, Math.round(counterTotal));
  if (floorMsg) return apiError(c, 400, "OFFER_TOO_LOW", floorMsg);

  await c.env.DB.prepare(
    `UPDATE quote_negotiations SET
      offered_total = ?, offered_by = 'tailor', status = 'countered',
      tailor_counter_used = 1, updated_at = datetime('now')
     WHERE id = ?`,
  )
    .bind(Math.round(counterTotal), id)
    .run();

  const msg = note
    ? `Counter offer: ${Math.round(counterTotal)} ${row.currency}. ${note}`
    : `Counter offer: ${Math.round(counterTotal)} ${row.currency}`;
  await appendMessage(c.env.DB, {
    negotiationId: id,
    senderId: tailorId,
    senderRole: "tailor",
    body: msg,
  });

  const tpl = quoteNegotiationTemplates.quote_negotiation_counter;
  void sendToUser({
    env: c.env,
    userIds: [row.user_id],
    headings: tpl.headings,
    contents: tpl.contents,
    route: `/order/quote-negotiation/${id}`,
  });

  const updated = await loadNegotiation(c.env.DB, id);
  if (!updated) return apiError(c, 500, "INTERNAL", "Could not reload negotiation");
  return c.json(await detailPayload(c.env.DB, updated));
});

async function finalizeAcceptance(
  c: Context<{ Bindings: Env; Variables: AppVariables }>,
  row: NegotiationRow,
  acceptedBy: "customer" | "tailor",
) {
  const frozen = freezeNegotiatedLineItems({
    listBase: row.list_base_price,
    listFabric: row.list_fabric_fee,
    listDelivery: row.list_delivery_fee,
    agreedTotal: row.offered_total,
  });
  const lockToken = uuidv4();
  const lockExpires = quoteLockExpiryIso();
  await c.env.DB.prepare(
    `UPDATE quote_negotiations SET
      status = 'accepted', accepted_at = datetime('now'),
      locked_base_price = ?, locked_fabric_fee = ?, locked_delivery_fee = ?, locked_total = ?,
      quote_lock_token = ?, quote_lock_expires_at = ?, updated_at = datetime('now')
     WHERE id = ?`,
  )
    .bind(
      frozen.base,
      frozen.fabric,
      frozen.delivery,
      frozen.total,
      lockToken,
      lockExpires,
      row.id,
    )
    .run();

  await appendMessage(c.env.DB, {
    negotiationId: row.id,
    senderId: acceptedBy === "customer" ? row.user_id : row.tailor_id,
    senderRole: acceptedBy,
    body: `Accepted agreed price ${row.offered_total} ${row.currency}`,
  });

  const notifyUserId = acceptedBy === "customer" ? row.tailor_id : row.user_id;
  const tpl = quoteNegotiationTemplates.quote_negotiation_accepted;
  void sendToUser({
    env: c.env,
    userIds: [notifyUserId],
    headings: tpl.headings,
    contents: tpl.contents,
    route: acceptedBy === "customer"
      ? `/tailor/price-requests/${row.id}`
      : `/order/quote-negotiation/${row.id}`,
  });
}

quoteNegotiationRoutes.post("/:id/accept", async (c) => {
  const userId = c.get("userId") as string;
  const id = c.req.param("id");
  const row = await loadNegotiation(c.env.DB, id);
  if (!row) return apiError(c, 404, "NOT_FOUND", "Negotiation not found");

  const isCustomer = row.user_id === userId;
  const isTailor = row.tailor_id === userId;
  if (!isCustomer && !isTailor) return apiError(c, 403, "FORBIDDEN", "Not a participant");

  if (isTailor) {
    if (row.status !== "tailor_review" || row.offered_by !== "customer") {
      return apiError(c, 400, "INVALID_STATE", "Tailor can only accept a customer offer");
    }
  } else {
    if (row.status !== "countered" || row.offered_by !== "tailor") {
      return apiError(c, 400, "INVALID_STATE", "Customer can only accept a tailor counter");
    }
  }

  await finalizeAcceptance(c, row, isCustomer ? "customer" : "tailor");
  const updated = await loadNegotiation(c.env.DB, id);
  if (!updated) return apiError(c, 500, "INTERNAL", "Could not reload negotiation");
  return c.json(await detailPayload(c.env.DB, updated));
});

quoteNegotiationRoutes.post("/:id/decline", async (c) => {
  const userId = c.get("userId") as string;
  const id = c.req.param("id");
  const row = await loadNegotiation(c.env.DB, id);
  if (!row) return apiError(c, 404, "NOT_FOUND", "Negotiation not found");
  if (row.user_id !== userId && row.tailor_id !== userId) {
    return apiError(c, 403, "FORBIDDEN", "Not a participant");
  }
  if (!OPEN_STATUSES.has(row.status)) {
    return apiError(c, 400, "NEGOTIATION_CLOSED", "Negotiation already closed");
  }
  await c.env.DB.prepare(
    "UPDATE quote_negotiations SET status = 'declined', updated_at = datetime('now') WHERE id = ?",
  )
    .bind(id)
    .run();
  const role = row.user_id === userId ? "customer" : "tailor";
  await appendMessage(c.env.DB, {
    negotiationId: id,
    senderId: userId,
    senderRole: role,
    body: "Declined the offer",
  });

  const notifyUserId = role === "customer" ? row.tailor_id : row.user_id;
  const tpl = quoteNegotiationTemplates.quote_negotiation_declined;
  void sendToUser({
    env: c.env,
    userIds: [notifyUserId],
    headings: tpl.headings,
    contents: tpl.contents,
    route:
      role === "customer"
        ? `/tailor/price-requests/${id}`
        : `/order/quote-negotiation/${id}`,
  });

  const updated = await loadNegotiation(c.env.DB, id);
  if (!updated) return apiError(c, 500, "INTERNAL", "Could not reload negotiation");
  return c.json(await detailPayload(c.env.DB, updated));
});

quoteNegotiationRoutes.post("/:id/cancel", async (c) => {
  const userId = c.get("userId") as string;
  const id = c.req.param("id");
  const row = await loadNegotiation(c.env.DB, id);
  if (!row) return apiError(c, 404, "NOT_FOUND", "Negotiation not found");
  if (row.user_id !== userId) return apiError(c, 403, "FORBIDDEN", "Only the customer can cancel");
  if (!OPEN_STATUSES.has(row.status)) {
    return apiError(c, 400, "NEGOTIATION_CLOSED", "Negotiation already closed");
  }
  await c.env.DB.prepare(
    "UPDATE quote_negotiations SET status = 'cancelled', updated_at = datetime('now') WHERE id = ?",
  )
    .bind(id)
    .run();
  await appendMessage(c.env.DB, {
    negotiationId: id,
    senderId: userId,
    senderRole: "customer",
    body: "Cancelled the negotiation",
  });
  const updated = await loadNegotiation(c.env.DB, id);
  if (!updated) return apiError(c, 500, "INTERNAL", "Could not reload negotiation");
  return c.json(await detailPayload(c.env.DB, updated));
});
