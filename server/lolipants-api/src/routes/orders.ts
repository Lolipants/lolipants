import { Hono, type Context } from "hono";
import { v4 as uuidv4 } from "uuid";
import { apiError } from "../lib/http";
import { orderStatusTemplates, sendToUser, quoteNegotiationTemplates } from "../lib/onesignal";
import { designerCommissionPct } from "../lib/commissionConfig";
import { pickCourierForDelivery } from "../lib/courierAssignment";
import { pickTailorForDelivery, estimateGarmentPriceRange, compareTailorsForDelivery, quoteForTailorId } from "../lib/tailorAssignment";
import {
  computeAccessoryPurchaseQuote,
  insertOrderAccessoryLines,
  loadAccessoriesByIds,
  loadOrderAccessoryLines,
  parseAccessoryIds,
  pickTailorForAccessory,
  sumAccessorySalePrice,
  type AccessoryRow,
} from "../lib/accessoryPricing";
import {
  computeWeddingQuote,
  pickTailorForWedding,
  type WeddingDressRow,
  type WeddingFulfillment,
} from "../lib/weddingPricing";
import { requireAuth, requireRole } from "../middleware/auth";
import type { AppVariables, Env } from "../types";
import { quoteNegotiationRoutes } from "./quoteNegotiations";

export const orderRoutes = new Hono<{ Bindings: Env; Variables: AppVariables }>();
orderRoutes.use("*", requireAuth);

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
  ready_to_ship: new Set(["cancelled"]),
  out_for_delivery: new Set(),
  delivered: new Set(),
  cancelled: new Set(),
};

function parseCoord(
  raw: string | undefined,
  field: string,
): { ok: true; value: number } | { ok: false; message: string } {
  if (raw == null || raw.trim() === "") {
    return { ok: false, message: `${field} is required` };
  }
  const value = Number(raw);
  if (!Number.isFinite(value)) {
    return { ok: false, message: `${field} must be a number` };
  }
  return { ok: true, value };
}

function pricesMatch(
  a: { base: number; fabric: number; delivery: number; total: number },
  b: { base: number; fabric: number; delivery: number; total: number },
): boolean {
  const eps = 0.01;
  return (
    Math.abs(a.base - b.base) < eps &&
    Math.abs(a.fabric - b.fabric) < eps &&
    Math.abs(a.delivery - b.delivery) < eps &&
    Math.abs(a.total - b.total) < eps
  );
}

function pricesMatchWithAccessories(
  a: {
    base: number;
    fabric: number;
    delivery: number;
    accessory: number;
    total: number;
  },
  b: {
    base: number;
    fabric: number;
    delivery: number;
    accessory: number;
    total: number;
  },
): boolean {
  const eps = 0.01;
  return (
    Math.abs(a.base - b.base) < eps &&
    Math.abs(a.fabric - b.fabric) < eps &&
    Math.abs(a.delivery - b.delivery) < eps &&
    Math.abs(a.accessory - b.accessory) < eps &&
    Math.abs(a.total - b.total) < eps
  );
}

async function attachOrderAccessoriesToPayload(
  db: D1Database,
  order: Record<string, unknown>,
): Promise<Record<string, unknown>> {
  const orderId = String(order.id ?? "");
  if (!orderId) return order;
  const accessories = await loadOrderAccessoryLines(db, orderId);
  return { ...order, orderAccessories: accessories };
}

async function loadTailorOrderPayload(
  db: D1Database,
  tailorId: string,
  orderId: string,
): Promise<Record<string, unknown> | null> {
  const order = await db
    .prepare(
      `SELECT o.*, d.print_image_url AS design_print_image_url,
              d.sketch_image_url AS design_sketch_image_url,
              d.name AS design_name,
              courier.name AS courier_name
       FROM orders o
       LEFT JOIN designs d ON d.id = o.design_id
       LEFT JOIN users courier ON courier.id = o.courier_id
       WHERE o.id = ? AND o.tailor_id = ?`,
    )
    .bind(orderId, tailorId)
    .first<Record<string, unknown>>();
  if (!order) return null;

  const history = await db
    .prepare(
      "SELECT * FROM order_status_history WHERE order_id = ? ORDER BY timestamp ASC",
    )
    .bind(orderId)
    .all();
  const payment = await db
    .prepare(
      "SELECT id, status, amount, currency, updated_at FROM payment_transactions WHERE order_id = ? ORDER BY updated_at DESC LIMIT 1",
    )
    .bind(orderId)
    .first<Record<string, unknown>>();
  return attachOrderAccessoriesToPayload(db, {
    ...order,
    statusHistory: history.results,
    payment,
  });
}

const CUSTOMER_ORDER_COLUMNS = `
  o.*,
  d.name AS design_name,
  d.garment_type AS design_garment_type,
  d.print_image_url AS design_print_image_url,
  d.sketch_image_url AS design_sketch_image_url,
  tailor.name AS tailor_name,
  tp.shop_name AS tailor_shop_name,
  courier.name AS courier_name
`;

const CUSTOMER_ORDER_JOINS = `
  FROM orders o
  LEFT JOIN designs d ON d.id = o.design_id
  LEFT JOIN users tailor ON tailor.id = o.tailor_id
  LEFT JOIN tailor_profiles tp ON tp.user_id = o.tailor_id
  LEFT JOIN users courier ON courier.id = o.courier_id
`;

async function loadCustomerOrderPayload(
  db: D1Database,
  userId: string,
  orderId: string,
): Promise<Record<string, unknown> | null> {
  const order = await db
    .prepare(
      `SELECT ${CUSTOMER_ORDER_COLUMNS}
       ${CUSTOMER_ORDER_JOINS}
       WHERE o.id = ? AND o.user_id = ?`,
    )
    .bind(orderId, userId)
    .first<Record<string, unknown>>();
  if (!order) return null;

  const history = await db
    .prepare(
      "SELECT * FROM order_status_history WHERE order_id = ? ORDER BY timestamp ASC",
    )
    .bind(orderId)
    .all();
  const payment = await db
    .prepare(
      "SELECT id, status, amount, currency, updated_at FROM payment_transactions WHERE order_id = ? ORDER BY updated_at DESC LIMIT 1",
    )
    .bind(orderId)
    .first<Record<string, unknown>>();
  return attachOrderAccessoriesToPayload(db, {
    ...order,
    statusHistory: history.results,
    payment,
  });
}

async function assignTailorAndQuote(
  db: D1Database,
  input: {
    design: {
      garment_type: string;
      fabric_quality: string | null;
    };
    city: string;
    deliveryLat: number;
    deliveryLng: number;
  },
) {
  const picked = await pickTailorForDelivery({
    db,
    deliveryLat: input.deliveryLat,
    deliveryLng: input.deliveryLng,
    city: input.city,
    design: input.design,
  });
  if (!picked) return null;
  const assigned = picked.candidate;
  return {
    tailorId: assigned.tailorId,
    tailorName: assigned.tailorName,
    shopName: assigned.shopName,
    distanceKm: Math.round(assigned.distanceKm * 10) / 10,
    pricePlanId: assigned.quote.planId,
    assignmentMethod: picked.assignmentMethod,
    basePrice: assigned.quote.basePrice,
    fabricFee: assigned.quote.fabricFee,
    deliveryFee: assigned.quote.deliveryFee,
    total: assigned.quote.total,
    currency: assigned.quote.currency,
    fabricQuality: assigned.quote.fabricQuality,
    garmentType: assigned.quote.garmentType,
  };
}

orderRoutes.get("/", async (c) => {
  const userId = c.get("userId") as string;
  const { results } = await c.env.DB.prepare(
    `SELECT ${CUSTOMER_ORDER_COLUMNS}
     ${CUSTOMER_ORDER_JOINS}
     WHERE o.user_id = ?
     ORDER BY o.placed_at DESC
     LIMIT 200`,
  )
    .bind(userId)
    .all();
  return c.json(results);
});

orderRoutes.get("/quote", async (c) => {
  const userId = c.get("userId") as string;
  const designId = (c.req.query("designId") ?? "").trim();
  const city = (c.req.query("city") ?? "Doha").trim();
  const latParsed = parseCoord(c.req.query("deliveryLat"), "deliveryLat");
  const lngParsed = parseCoord(c.req.query("deliveryLng"), "deliveryLng");
  if (!latParsed.ok) {
    return apiError(c, 400, "DELIVERY_LAT_REQUIRED", latParsed.message);
  }
  if (!lngParsed.ok) {
    return apiError(c, 400, "DELIVERY_LNG_REQUIRED", lngParsed.message);
  }
  if (latParsed.value < -90 || latParsed.value > 90) {
    return apiError(c, 400, "INVALID_LAT", "deliveryLat out of range");
  }
  if (lngParsed.value < -180 || lngParsed.value > 180) {
    return apiError(c, 400, "INVALID_LNG", "deliveryLng out of range");
  }
  if (!designId) {
    return apiError(c, 400, "DESIGN_ID_REQUIRED", "designId is required");
  }
  const design = await c.env.DB.prepare(
    "SELECT id, user_id, garment_type, fabric_quality FROM designs WHERE id = ?",
  )
    .bind(designId)
    .first<{
      id: string;
      user_id: string;
      garment_type: string;
      fabric_quality: string | null;
    }>();
  if (!design) return apiError(c, 404, "DESIGN_NOT_FOUND", "Design not found");
  if (design.user_id !== userId) {
    return apiError(
      c,
      403,
      "QUOTE_OWN_DESIGN_ONLY",
      "You can only quote your own design",
    );
  }

  const accessoryIds = parseAccessoryIds(c.req.query("accessoryIds"));
  let accessoryFee = 0;
  if (accessoryIds.length > 0) {
    const accessories = await loadAccessoriesByIds(c.env.DB, accessoryIds, {
      requireAddon: true,
    });
    if (!accessories) {
      return apiError(c, 400, "ACCESSORY_INVALID", "One or more accessories are invalid");
    }
    accessoryFee = sumAccessorySalePrice(accessories);
  }

  const quote = await assignTailorAndQuote(c.env.DB, {
    design: {
      garment_type: design.garment_type,
      fabric_quality: design.fabric_quality,
    },
    city,
    deliveryLat: latParsed.value,
    deliveryLng: lngParsed.value,
  });
  if (!quote) {
    return apiError(
      c,
      404,
      "NO_TAILOR_AVAILABLE",
      "No tailor is available for this garment",
    );
  }

  return c.json({
    designId,
    city,
    deliveryLat: latParsed.value,
    deliveryLng: lngParsed.value,
    tailorId: quote.tailorId,
    tailorName: quote.tailorName,
    shopName: quote.shopName,
    distanceKm: quote.distanceKm,
    pricePlanId: quote.pricePlanId,
    assignmentMethod: quote.assignmentMethod,
    basePrice: quote.basePrice,
    fabricFee: quote.fabricFee,
    deliveryFee: quote.deliveryFee,
    accessoryFee,
    total: quote.total + accessoryFee,
    currency: quote.currency,
    fabricQuality: quote.fabricQuality,
    garmentType: quote.garmentType,
    accessoryIds,
  });
});

orderRoutes.get("/estimate", async (c) => {
  const garmentType = (c.req.query("garmentType") ?? "abaya").trim();
  const fabricQuality = (c.req.query("fabricQuality") ?? "standard").trim();
  if (!garmentType) {
    return apiError(c, 400, "GARMENT_TYPE_REQUIRED", "garmentType is required");
  }

  const estimate = await estimateGarmentPriceRange(c.env.DB, {
    garmentType,
    fabricQuality,
  });
  if (!estimate) {
    return apiError(
      c,
      404,
      "NO_TAILOR_PRICING",
      "No tailor pricing available for this garment",
    );
  }

  return c.json(estimate);
});

orderRoutes.get("/quotes/compare", async (c) => {
  const userId = c.get("userId") as string;
  const designId = (c.req.query("designId") ?? "").trim();
  const city = (c.req.query("city") ?? "Doha").trim();
  const limitRaw = Number(c.req.query("limit") ?? "5");
  const limit = Number.isFinite(limitRaw) ? Math.floor(limitRaw) : 5;
  const latParsed = parseCoord(c.req.query("deliveryLat"), "deliveryLat");
  const lngParsed = parseCoord(c.req.query("deliveryLng"), "deliveryLng");
  if (!latParsed.ok) {
    return apiError(c, 400, "DELIVERY_LAT_REQUIRED", latParsed.message);
  }
  if (!lngParsed.ok) {
    return apiError(c, 400, "DELIVERY_LNG_REQUIRED", lngParsed.message);
  }
  if (!designId) {
    return apiError(c, 400, "DESIGN_ID_REQUIRED", "designId is required");
  }

  const design = await c.env.DB.prepare(
    "SELECT id, user_id, garment_type, fabric_quality FROM designs WHERE id = ?",
  )
    .bind(designId)
    .first<{
      id: string;
      user_id: string;
      garment_type: string;
      fabric_quality: string | null;
    }>();
  if (!design) return apiError(c, 404, "DESIGN_NOT_FOUND", "Design not found");
  if (design.user_id !== userId) {
    return apiError(
      c,
      403,
      "QUOTE_OWN_DESIGN_ONLY",
      "You can only quote your own design",
    );
  }

  const accessoryIds = parseAccessoryIds(c.req.query("accessoryIds"));
  let accessoryFee = 0;
  if (accessoryIds.length > 0) {
    const accessories = await loadAccessoriesByIds(c.env.DB, accessoryIds, {
      requireAddon: true,
    });
    if (!accessories) {
      return apiError(c, 400, "ACCESSORY_INVALID", "One or more accessories are invalid");
    }
    accessoryFee = sumAccessorySalePrice(accessories);
  }

  const quotes = await compareTailorsForDelivery({
    db: c.env.DB,
    deliveryLat: latParsed.value,
    deliveryLng: lngParsed.value,
    city,
    design: {
      garment_type: design.garment_type,
      fabric_quality: design.fabric_quality,
    },
    limit,
  });

  if (quotes.length === 0) {
    return apiError(
      c,
      404,
      "NO_TAILOR_AVAILABLE",
      "No tailor is available for this garment",
    );
  }

  const quotesWithAccessories = quotes.map((q) => ({
    ...q,
    accessoryFee,
    total: q.total + accessoryFee,
  }));

  return c.json({
    designId,
    city,
    deliveryLat: latParsed.value,
    deliveryLng: lngParsed.value,
    accessoryIds,
    accessoryFee,
    quotes: quotesWithAccessories,
  });
});

orderRoutes.route("/quote-negotiations", quoteNegotiationRoutes);

orderRoutes.get("/wedding-quote", async (c) => {
  const dressId = (c.req.query("dressId") ?? "").trim();
  const fulfillmentRaw = (c.req.query("fulfillment") ?? "rent").trim().toLowerCase();
  const fulfillment: WeddingFulfillment =
    fulfillmentRaw === "buy" ? "buy" : "rent";
  const rentalDays = Math.max(
    1,
    Math.floor(Number(c.req.query("rentalDays") ?? "3")),
  );
  const city = (c.req.query("city") ?? "Doha").trim();
  const latParsed = parseCoord(c.req.query("deliveryLat"), "deliveryLat");
  const lngParsed = parseCoord(c.req.query("deliveryLng"), "deliveryLng");
  if (!dressId) {
    return apiError(c, 400, "DRESS_ID_REQUIRED", "dressId is required");
  }
  if (!latParsed.ok) {
    return apiError(c, 400, "DELIVERY_LAT_REQUIRED", latParsed.message);
  }
  if (!lngParsed.ok) {
    return apiError(c, 400, "DELIVERY_LNG_REQUIRED", lngParsed.message);
  }

  const dress = await c.env.DB.prepare(
    `SELECT id, label_en, label_ar, category, image_url,
            rent_price_per_day, sale_price, insurance_deposit, is_active, sort_order
     FROM wedding_dresses WHERE id = ? AND is_active = 1`,
  )
    .bind(dressId)
    .first<WeddingDressRow>();
  if (!dress) {
    return apiError(c, 404, "DRESS_NOT_FOUND", "Wedding dress not found");
  }

  const picked = await pickTailorForWedding({
    db: c.env.DB,
    dress,
    city,
    deliveryLat: latParsed.value,
    deliveryLng: lngParsed.value,
  });
  if (!picked) {
    return apiError(
      c,
      404,
      "NO_TAILOR_AVAILABLE",
      "No tailor is available for wedding dresses",
    );
  }

  const quote = computeWeddingQuote({
    dress,
    fulfillment,
    rentalDays,
    city,
    deliveryFee: picked.deliveryFee,
    prices: picked.prices,
  });

  return c.json({
    dressId,
    dressLabel: dress.label_en,
    dressCategory: dress.category,
    dressImageUrl: dress.image_url,
    fulfillment: quote.fulfillment,
    fulfillmentType:
      fulfillment === "rent" ? "wedding_rent" : "wedding_purchase",
    rentalDays: quote.rentalDays,
    rentPricePerDay: quote.rentPricePerDay,
    rentSubtotal: quote.rentSubtotal,
    insuranceDeposit: quote.insuranceDeposit,
    salePrice: quote.salePrice,
    city,
    deliveryLat: latParsed.value,
    deliveryLng: lngParsed.value,
    tailorId: picked.tailorId,
    tailorName: picked.tailorName,
    shopName: picked.shopName,
    distanceKm: Math.round(picked.distanceKm * 10) / 10,
    assignmentMethod: picked.assignmentMethod,
    basePrice: quote.basePrice,
    fabricFee: quote.fabricFee,
    deliveryFee: quote.deliveryFee,
    total: quote.total,
    currency: quote.currency,
  });
});

orderRoutes.get("/accessory-quote", async (c) => {
  const accessoryId = (c.req.query("accessoryId") ?? "").trim();
  const city = (c.req.query("city") ?? "Doha").trim();
  const latParsed = parseCoord(c.req.query("deliveryLat"), "deliveryLat");
  const lngParsed = parseCoord(c.req.query("deliveryLng"), "deliveryLng");
  if (!accessoryId) {
    return apiError(c, 400, "ACCESSORY_ID_REQUIRED", "accessoryId is required");
  }
  if (!latParsed.ok) {
    return apiError(c, 400, "DELIVERY_LAT_REQUIRED", latParsed.message);
  }
  if (!lngParsed.ok) {
    return apiError(c, 400, "DELIVERY_LNG_REQUIRED", lngParsed.message);
  }

  const accessories = await loadAccessoriesByIds(c.env.DB, [accessoryId]);
  if (!accessories || accessories.length !== 1) {
    return apiError(c, 404, "ACCESSORY_NOT_FOUND", "Accessory not found");
  }
  const accessory = accessories[0]!;

  const picked = await pickTailorForAccessory({
    db: c.env.DB,
    city,
    deliveryLat: latParsed.value,
    deliveryLng: lngParsed.value,
  });
  if (!picked) {
    return apiError(
      c,
      404,
      "NO_TAILOR_AVAILABLE",
      "No tailor is available for accessories",
    );
  }

  const quote = computeAccessoryPurchaseQuote({
    accessories: [accessory],
    deliveryFee: picked.deliveryFee,
  });

  return c.json({
    accessoryId: accessory.id,
    accessoryLabel: accessory.label_en,
    accessoryLabelAr: accessory.label_ar,
    accessoryCategory: accessory.category,
    accessoryImageUrl: accessory.image_url,
    salePrice: accessory.sale_price,
    fulfillmentType: "accessory_purchase",
    city,
    deliveryLat: latParsed.value,
    deliveryLng: lngParsed.value,
    tailorId: picked.tailorId,
    tailorName: picked.tailorName,
    shopName: picked.shopName,
    distanceKm: Math.round(picked.distanceKm * 10) / 10,
    assignmentMethod: picked.assignmentMethod,
    basePrice: quote.basePrice,
    fabricFee: quote.fabricFee,
    deliveryFee: quote.deliveryFee,
    accessoryFee: quote.accessoryFee,
    total: quote.total,
    currency: quote.currency,
  });
});

orderRoutes.get("/queue", requireRole("tailor"), async (c) => {
  const tailorId = c.get("userId") as string;
  const statusFilter = (c.req.query("status") ?? "").trim().toLowerCase();
  const statuses = statusFilter
    ? statusFilter
        .split(",")
        .map((s) => s.trim())
        .filter((s) => validOrderStatuses.has(s))
    : [];
  let query = "SELECT * FROM orders WHERE tailor_id = ?";
  const bindings: Array<string> = [tailorId];
  if (statuses.length > 0) {
    const placeholders = statuses.map(() => "?").join(", ");
    query += ` AND status IN (${placeholders})`;
    bindings.push(...statuses);
  }
  query += " ORDER BY placed_at DESC LIMIT 200";
  const { results } = await c.env.DB.prepare(query)
    .bind(...bindings)
    .all();
  return c.json(results);
});

orderRoutes.post("/:id/claim", requireRole("tailor"), async (c) => {
  const tailorId = c.get("userId") as string;
  const id = c.req.param("id");
  const current = await c.env.DB.prepare(
    "SELECT id, tailor_id, status FROM orders WHERE id = ?",
  )
    .bind(id)
    .first<{ id: string; tailor_id: string | null; status: string }>();
  if (!current) {
    return apiError(c, 404, "ORDER_NOT_FOUND", "Order not found");
  }
  if (!current.tailor_id) {
    return apiError(
      c,
      409,
      "TAILOR_NOT_ASSIGNED",
      "This order has no assigned tailor yet",
    );
  }
  if (current.tailor_id !== tailorId) {
    return apiError(
      c,
      409,
      "ORDER_ALREADY_CLAIMED",
      "Order is assigned to another tailor",
    );
  }
  return c.json({ claimed: true, orderId: id, tailorId, accepted: true });
});

orderRoutes.get("/tailor/:id", requireRole("tailor"), async (c) => {
  const tailorId = c.get("userId") as string;
  const id = c.req.param("id");
  const order = await loadTailorOrderPayload(c.env.DB, tailorId, id);
  if (!order) return apiError(c, 404, "ORDER_NOT_FOUND", "Order not found");
  return c.json(order);
});

orderRoutes.get("/:id", async (c) => {
  const userId = c.get("userId") as string;
  const id = c.req.param("id");
  const order = await loadCustomerOrderPayload(c.env.DB, userId, id);
  if (!order) return apiError(c, 404, "ORDER_NOT_FOUND", "Order not found");
  return c.json(order);
});

async function placeAccessoryOrder(
  c: Context<{ Bindings: Env; Variables: AppVariables }>,
  input: {
    userId: string;
    idempotencyKey: string;
    body: Record<string, unknown>;
    accessoryId: string;
  },
) {
  const { userId, idempotencyKey, body, accessoryId } = input;
  if (!accessoryId) {
    return apiError(c, 400, "ACCESSORY_ID_REQUIRED", "accessoryId is required");
  }

  const deliveryAddress = String(body.deliveryAddress ?? "").trim();
  const deliveryCity = String(body.deliveryCity ?? "").trim();
  const deliveryPhone = String(body.deliveryPhone ?? "").trim();
  if (!deliveryAddress || !deliveryCity || !deliveryPhone) {
    return apiError(
      c,
      400,
      "DELIVERY_FIELDS_REQUIRED",
      "deliveryAddress, deliveryCity, and deliveryPhone are required",
    );
  }

  const latRaw = body.deliveryLat ?? body.delivery_lat;
  const lngRaw = body.deliveryLng ?? body.delivery_lng;
  const lat =
    typeof latRaw === "number" ? latRaw : Number(String(latRaw ?? "").trim());
  const lng =
    typeof lngRaw === "number" ? lngRaw : Number(String(lngRaw ?? "").trim());
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
    return apiError(
      c,
      400,
      "DELIVERY_COORDS_REQUIRED",
      "deliveryLat and deliveryLng are required",
    );
  }

  const requestedTailorId = String(body.tailorId ?? body.tailor_id ?? "").trim();
  if (!requestedTailorId) {
    return apiError(c, 400, "TAILOR_ID_REQUIRED", "tailorId is required");
  }

  const accessories = await c.env.DB.prepare(
    `SELECT id, label_en, label_ar, category, image_url, sale_price,
            description_en, description_ar, allow_addon, is_active, sort_order
     FROM accessories WHERE id = ? AND is_active = 1`,
  )
    .bind(accessoryId)
    .first<AccessoryRow>();
  if (!accessories) {
    return apiError(c, 404, "ACCESSORY_NOT_FOUND", "Accessory not found");
  }

  const picked = await pickTailorForAccessory({
    db: c.env.DB,
    city: deliveryCity,
    deliveryLat: lat,
    deliveryLng: lng,
  });
  if (!picked) {
    return apiError(
      c,
      404,
      "NO_TAILOR_AVAILABLE",
      "No tailor is available for accessories",
    );
  }
  if (picked.tailorId !== requestedTailorId) {
    return apiError(
      c,
      409,
      "QUOTE_STALE",
      "Assigned tailor changed. Refresh your quote before paying.",
    );
  }

  const quote = computeAccessoryPurchaseQuote({
    accessories: [accessories],
    deliveryFee: picked.deliveryFee,
  });

  const clientBase = Number(body.basePrice ?? body.base_price);
  const clientFabric = Number(body.fabricFee ?? body.fabric_fee);
  const clientDelivery = Number(body.deliveryFee ?? body.delivery_fee);
  const clientAccessoryRaw = Number(body.accessoryFee ?? body.accessory_fee);
  const clientAccessoryFee = Number.isFinite(clientAccessoryRaw)
    ? clientAccessoryRaw
    : 0;
  const clientTotal = Number(body.totalPrice ?? body.total_price);
  if (
    Number.isFinite(clientTotal) &&
    !pricesMatchWithAccessories(
      {
        base: clientBase,
        fabric: clientFabric,
        delivery: clientDelivery,
        accessory: clientAccessoryFee,
        total: clientTotal,
      },
      {
        base: quote.basePrice,
        fabric: quote.fabricFee,
        delivery: quote.deliveryFee,
        accessory: quote.accessoryFee,
        total: quote.total,
      },
    )
  ) {
    return apiError(
      c,
      409,
      "QUOTE_MISMATCH",
      "Price no longer matches the server quote. Refresh and try again.",
    );
  }

  const fulfillmentType = "accessory_purchase";
  const designId = uuidv4();
  await c.env.DB.prepare(
    `INSERT INTO designs (id, user_id, name, garment_type, fabric_quality,
      primary_colour, print_image_url, text_layers, render_metadata, is_public)
      VALUES (?, ?, ?, 'accessory', 'standard', '#FFFFFF', ?, '[]', ?, 0)`,
  )
    .bind(
      designId,
      userId,
      accessories.label_en,
      accessories.image_url,
      JSON.stringify({
        accessoryId: accessories.id,
        accessoryCategory: accessories.category,
        fulfillmentType,
      }),
    )
    .run();

  const orderId = uuidv4();
  try {
    await c.env.DB.prepare(
      `INSERT INTO orders (id, user_id, design_id, tailor_id, status,
        delivery_address, delivery_city, delivery_phone, delivery_notes,
        delivery_lat, delivery_lng, assignment_method,
        base_price, fabric_fee, delivery_fee, accessory_fee, total_price, payment_token,
        fulfillment_type)
        VALUES (?, ?, ?, ?, 'placed', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
                ?)`,
    )
      .bind(
        orderId,
        userId,
        designId,
        picked.tailorId,
        deliveryAddress,
        deliveryCity,
        deliveryPhone,
        body.deliveryNotes ?? null,
        lat,
        lng,
        picked.assignmentMethod,
        quote.basePrice,
        quote.fabricFee,
        quote.deliveryFee,
        quote.accessoryFee,
        quote.total,
        body.paymentToken ?? null,
        fulfillmentType,
      )
      .run();

    await insertOrderAccessoryLines(c.env.DB, orderId, [accessories]);

    await c.env.DB.prepare(
      "INSERT INTO order_status_history (id, order_id, status) VALUES (?, ?, 'placed')",
    )
      .bind(uuidv4(), orderId)
      .run();
    await c.env.DB.prepare(
      "INSERT INTO order_idempotency_keys (id, user_id, idempotency_key, order_id) VALUES (?, ?, ?, ?)",
    )
      .bind(uuidv4(), userId, idempotencyKey, orderId)
      .run();
  } catch (err) {
    console.error("[accessory-order]", err);
    return apiError(c, 500, "ORDER_FAILED", "Could not place accessory order");
  }

  const created = await loadCustomerOrderPayload(c.env.DB, userId, orderId);
  return c.json(created ?? { id: orderId }, 201);
}

async function placeWeddingOrder(
  c: Context<{ Bindings: Env; Variables: AppVariables }>,
  input: {
    userId: string;
    idempotencyKey: string;
    body: Record<string, unknown>;
    weddingDressId: string;
    fulfillmentTypeRaw: string;
  },
) {
  const { userId, idempotencyKey, body, weddingDressId, fulfillmentTypeRaw } =
    input;
  if (!weddingDressId) {
    return apiError(c, 400, "DRESS_ID_REQUIRED", "weddingDressId is required");
  }

  const fulfillmentRaw = String(body.fulfillment ?? "").trim().toLowerCase();
  let fulfillment: WeddingFulfillment = "rent";
  let fulfillmentType = "wedding_rent";
  if (
    fulfillmentTypeRaw === "wedding_purchase" ||
    fulfillmentRaw === "buy"
  ) {
    fulfillment = "buy";
    fulfillmentType = "wedding_purchase";
  } else if (
    fulfillmentTypeRaw === "wedding_rent" ||
    fulfillmentRaw === "rent" ||
    fulfillmentTypeRaw === ""
  ) {
    fulfillment = "rent";
    fulfillmentType = "wedding_rent";
  } else {
    return apiError(c, 400, "INVALID_FULFILLMENT", "Invalid fulfillment type");
  }

  const rentalDays = Math.max(
    1,
    Math.floor(Number(body.rentalDays ?? body.rental_days ?? 3)),
  );

  const deliveryAddress = String(body.deliveryAddress ?? "").trim();
  const deliveryCity = String(body.deliveryCity ?? "").trim();
  const deliveryPhone = String(body.deliveryPhone ?? "").trim();
  if (!deliveryAddress || !deliveryCity || !deliveryPhone) {
    return apiError(
      c,
      400,
      "DELIVERY_FIELDS_REQUIRED",
      "deliveryAddress, deliveryCity, and deliveryPhone are required",
    );
  }

  const latRaw = body.deliveryLat ?? body.delivery_lat;
  const lngRaw = body.deliveryLng ?? body.delivery_lng;
  const lat =
    typeof latRaw === "number" ? latRaw : Number(String(latRaw ?? "").trim());
  const lng =
    typeof lngRaw === "number" ? lngRaw : Number(String(lngRaw ?? "").trim());
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
    return apiError(
      c,
      400,
      "DELIVERY_COORDS_REQUIRED",
      "deliveryLat and deliveryLng are required",
    );
  }

  const requestedTailorId = String(body.tailorId ?? body.tailor_id ?? "").trim();
  if (!requestedTailorId) {
    return apiError(c, 400, "TAILOR_ID_REQUIRED", "tailorId is required");
  }

  const sizing = await c.env.DB.prepare(
    "SELECT id FROM measurements WHERE user_id = ? ORDER BY saved_at DESC LIMIT 1",
  )
    .bind(userId)
    .first<{ id: string }>();
  if (!sizing) {
    return apiError(
      c,
      400,
      "MEASUREMENTS_REQUIRED",
      "Please save measurements before ordering",
    );
  }

  const dress = await c.env.DB.prepare(
    `SELECT id, label_en, label_ar, category, image_url,
            rent_price_per_day, sale_price, insurance_deposit, is_active, sort_order
     FROM wedding_dresses WHERE id = ? AND is_active = 1`,
  )
    .bind(weddingDressId)
    .first<WeddingDressRow>();
  if (!dress) {
    return apiError(c, 404, "DRESS_NOT_FOUND", "Wedding dress not found");
  }

  const picked = await pickTailorForWedding({
    db: c.env.DB,
    dress,
    city: deliveryCity,
    deliveryLat: lat,
    deliveryLng: lng,
  });
  if (!picked) {
    return apiError(
      c,
      404,
      "NO_TAILOR_AVAILABLE",
      "No tailor is available for wedding dresses",
    );
  }
  if (picked.tailorId !== requestedTailorId) {
    return apiError(
      c,
      409,
      "QUOTE_STALE",
      "Assigned tailor changed. Refresh your quote before paying.",
    );
  }

  const quote = computeWeddingQuote({
    dress,
    fulfillment,
    rentalDays,
    city: deliveryCity,
    deliveryFee: picked.deliveryFee,
    prices: picked.prices,
  });

  const clientBase = Number(body.basePrice ?? body.base_price);
  const clientFabric = Number(body.fabricFee ?? body.fabric_fee);
  const clientDelivery = Number(body.deliveryFee ?? body.delivery_fee);
  const clientTotal = Number(body.totalPrice ?? body.total_price);
  if (
    Number.isFinite(clientTotal) &&
    !pricesMatch(
      {
        base: clientBase,
        fabric: clientFabric,
        delivery: clientDelivery,
        total: clientTotal,
      },
      {
        base: quote.basePrice,
        fabric: quote.fabricFee,
        delivery: quote.deliveryFee,
        total: quote.total,
      },
    )
  ) {
    return apiError(
      c,
      409,
      "QUOTE_MISMATCH",
      "Price no longer matches the server quote. Refresh and try again.",
    );
  }

  const designId = uuidv4();
  await c.env.DB.prepare(
    `INSERT INTO designs (id, user_id, name, garment_type, fabric_quality,
      primary_colour, print_image_url, text_layers, render_metadata, is_public)
      VALUES (?, ?, ?, 'dress', 'standard', '#FFFFFF', ?, '[]', ?, 0)`,
  )
    .bind(
      designId,
      userId,
      dress.label_en,
      dress.image_url,
      JSON.stringify({
        weddingDressId: dress.id,
        weddingCategory: dress.category,
        fulfillmentType,
      }),
    )
    .run();

  const orderId = uuidv4();
  try {
    await c.env.DB.prepare(
      `INSERT INTO orders (id, user_id, design_id, tailor_id, status,
        delivery_address, delivery_city, delivery_phone, delivery_notes,
        delivery_lat, delivery_lng, assignment_method,
        base_price, fabric_fee, delivery_fee, total_price, payment_token,
        fulfillment_type, wedding_dress_id, rental_days, insurance_deposit, rent_subtotal)
        VALUES (?, ?, ?, ?, 'placed', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
                ?, ?, ?, ?, ?)`,
    )
      .bind(
        orderId,
        userId,
        designId,
        picked.tailorId,
        deliveryAddress,
        deliveryCity,
        deliveryPhone,
        body.deliveryNotes ?? null,
        lat,
        lng,
        picked.assignmentMethod,
        quote.basePrice,
        quote.fabricFee,
        quote.deliveryFee,
        quote.total,
        body.paymentToken ?? null,
        fulfillmentType,
        weddingDressId,
        quote.rentalDays,
        quote.insuranceDeposit > 0 ? quote.insuranceDeposit : null,
        quote.rentSubtotal > 0 ? quote.rentSubtotal : null,
      )
      .run();

    await c.env.DB.prepare(
      "INSERT INTO order_status_history (id, order_id, status) VALUES (?, ?, 'placed')",
    )
      .bind(uuidv4(), orderId)
      .run();
    await c.env.DB.prepare(
      "INSERT INTO order_idempotency_keys (id, user_id, idempotency_key, order_id) VALUES (?, ?, ?, ?)",
    )
      .bind(uuidv4(), userId, idempotencyKey, orderId)
      .run();
  } catch (err) {
    console.error("[wedding-order]", err);
    return apiError(c, 500, "ORDER_FAILED", "Could not place wedding order");
  }

  const created = await loadCustomerOrderPayload(c.env.DB, userId, orderId);
  return c.json(created ?? { id: orderId }, 201);
}

orderRoutes.post("/", async (c) => {
  const userId = c.get("userId") as string;
  const idempotencyKey = c.req.header("x-idempotency-key")?.trim() ?? "";
  if (!idempotencyKey) {
    return apiError(
      c,
      400,
      "IDEMPOTENCY_KEY_REQUIRED",
      "X-Idempotency-Key header is required",
    );
  }
  const existing = await c.env.DB.prepare(
    `SELECT o.* FROM order_idempotency_keys k
     JOIN orders o ON o.id = k.order_id
     WHERE k.user_id = ? AND k.idempotency_key = ? LIMIT 1`,
  )
    .bind(userId, idempotencyKey)
    .first<Record<string, unknown>>();
  if (existing) return c.json(existing, 200);

  const body = (await c.req.json()) as Record<string, unknown>;
  const accessoryId = String(body.accessoryId ?? body.accessory_id ?? "").trim();
  const weddingDressId = String(body.weddingDressId ?? body.wedding_dress_id ?? "").trim();
  const fulfillmentTypeRaw = String(
    body.fulfillmentType ?? body.fulfillment_type ?? "",
  ).trim();
  const isAccessoryOrder =
    accessoryId.length > 0 || fulfillmentTypeRaw === "accessory_purchase";
  const isWeddingOrder =
    weddingDressId.length > 0 ||
    fulfillmentTypeRaw === "wedding_rent" ||
    fulfillmentTypeRaw === "wedding_purchase";

  if (isAccessoryOrder) {
    return placeAccessoryOrder(c, {
      userId,
      idempotencyKey,
      body,
      accessoryId,
    });
  }

  if (isWeddingOrder) {
    return placeWeddingOrder(c, {
      userId,
      idempotencyKey,
      body,
      weddingDressId,
      fulfillmentTypeRaw,
    });
  }

  const designId = String(body.designId ?? "").trim();
  if (!designId) {
    return apiError(c, 400, "DESIGN_ID_REQUIRED", "designId is required");
  }

  const design = await c.env.DB.prepare(
    "SELECT id, user_id, garment_type, fabric_quality, is_public FROM designs WHERE id = ?",
  )
    .bind(designId)
    .first<{
      id: string;
      user_id: string;
      garment_type: string;
      fabric_quality: string | null;
      is_public: number | null;
    }>();
  if (!design) return apiError(c, 404, "DESIGN_NOT_FOUND", "Design not found");
  const requestedDesignerId = body.designerId ? String(body.designerId).trim() : "";
  const isOwnDesign = design.user_id === userId;
  const isPublicDesign = Boolean(design.is_public);
  if (!isOwnDesign && !isPublicDesign) {
    return apiError(
      c,
      403,
      "ORDER_OWN_DESIGN_ONLY",
      "You can only order your own designs or public showcase designs",
    );
  }
  if (requestedDesignerId && requestedDesignerId !== design.user_id) {
    return apiError(
      c,
      400,
      "DESIGNER_MISMATCH",
      "designerId does not match the design author",
    );
  }
  const designerId = !isOwnDesign ? design.user_id : null;

  const deliveryAddress = String(body.deliveryAddress ?? "").trim();
  const deliveryCity = String(body.deliveryCity ?? "").trim();
  const deliveryPhone = String(body.deliveryPhone ?? "").trim();
  if (!deliveryAddress || !deliveryCity || !deliveryPhone) {
    return apiError(
      c,
      400,
      "DELIVERY_FIELDS_REQUIRED",
      "deliveryAddress, deliveryCity, and deliveryPhone are required",
    );
  }

  const latRaw = body.deliveryLat ?? body.delivery_lat;
  const lngRaw = body.deliveryLng ?? body.delivery_lng;
  const lat =
    typeof latRaw === "number" ? latRaw : Number(String(latRaw ?? "").trim());
  const lng =
    typeof lngRaw === "number" ? lngRaw : Number(String(lngRaw ?? "").trim());
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
    return apiError(
      c,
      400,
      "DELIVERY_COORDS_REQUIRED",
      "deliveryLat and deliveryLng are required",
    );
  }

  const requestedTailorId = String(body.tailorId ?? body.tailor_id ?? "").trim();
  if (!requestedTailorId) {
    return apiError(c, 400, "TAILOR_ID_REQUIRED", "tailorId is required");
  }

  const quoteLockToken = String(body.quoteLockToken ?? body.quote_lock_token ?? "").trim();
  let lockedNegotiation: {
    locked_base_price: number;
    locked_fabric_fee: number;
    locked_delivery_fee: number;
    locked_total: number;
    price_plan_id: string;
    tailor_id: string;
    currency: string;
  } | null = null;

  if (quoteLockToken) {
    const neg = await c.env.DB.prepare(
      `SELECT * FROM quote_negotiations
       WHERE quote_lock_token = ? AND user_id = ? AND design_id = ? AND status = 'accepted'`,
    )
      .bind(quoteLockToken, userId, designId)
      .first<{
        locked_base_price: number | null;
        locked_fabric_fee: number | null;
        locked_delivery_fee: number | null;
        locked_total: number | null;
        price_plan_id: string;
        tailor_id: string;
        currency: string;
        quote_lock_expires_at: string | null;
      }>();
    if (!neg || neg.locked_total == null) {
      return apiError(c, 409, "QUOTE_LOCK_INVALID", "Negotiated quote lock is invalid or expired");
    }
    if (neg.quote_lock_expires_at) {
      const expires = Date.parse(neg.quote_lock_expires_at);
      if (Number.isFinite(expires) && Date.now() > expires) {
        return apiError(c, 409, "QUOTE_LOCK_EXPIRED", "Negotiated quote lock has expired");
      }
    }
    if (neg.tailor_id !== requestedTailorId) {
      return apiError(c, 409, "TAILOR_MISMATCH", "Tailor does not match the locked negotiation");
    }
    lockedNegotiation = {
      locked_base_price: neg.locked_base_price ?? 0,
      locked_fabric_fee: neg.locked_fabric_fee ?? 0,
      locked_delivery_fee: neg.locked_delivery_fee ?? 0,
      locked_total: neg.locked_total,
      price_plan_id: neg.price_plan_id,
      tailor_id: neg.tailor_id,
      currency: neg.currency,
    };
  }

  const sizing = await c.env.DB.prepare(
    "SELECT id FROM measurements WHERE user_id = ? ORDER BY saved_at DESC LIMIT 1",
  )
    .bind(userId)
    .first<{ id: string }>();
  if (!sizing) {
    return apiError(
      c,
      400,
      "MEASUREMENTS_REQUIRED",
      "Please save measurements before ordering",
    );
  }

  let quote: Awaited<ReturnType<typeof quoteForTailorId>>;
  if (lockedNegotiation) {
    quote = {
      tailorId: lockedNegotiation.tailor_id,
      tailorName: "",
      shopName: null,
      distanceKm: 0,
      pricePlanId: lockedNegotiation.price_plan_id,
      assignmentMethod: "proximity",
      basePrice: lockedNegotiation.locked_base_price,
      fabricFee: lockedNegotiation.locked_fabric_fee,
      deliveryFee: lockedNegotiation.locked_delivery_fee,
      total: lockedNegotiation.locked_total,
      currency: lockedNegotiation.currency,
      fabricQuality: design.fabric_quality ?? "standard",
      garmentType: design.garment_type,
    };
    const tailorMeta = await c.env.DB.prepare(
      `SELECT u.name AS tailor_name, tp.shop_name
       FROM users u LEFT JOIN tailor_profiles tp ON tp.user_id = u.id WHERE u.id = ?`,
    )
      .bind(requestedTailorId)
      .first<{ tailor_name: string | null; shop_name: string | null }>();
    if (tailorMeta) {
      quote.tailorName = tailorMeta.tailor_name ?? "";
      quote.shopName = tailorMeta.shop_name;
    }
  } else {
    quote = await quoteForTailorId({
      db: c.env.DB,
      tailorId: requestedTailorId,
      design: {
        garment_type: design.garment_type,
        fabric_quality: design.fabric_quality,
      },
      city: deliveryCity,
      deliveryLat: lat,
      deliveryLng: lng,
    });
    if (!quote) {
      return apiError(
        c,
        404,
        "NO_TAILOR_AVAILABLE",
        "Selected tailor cannot price this design at your delivery location",
      );
    }
  }

  const accessoryIds = parseAccessoryIds(
    body.accessoryIds ?? body.accessory_ids,
  );
  let orderAccessories: AccessoryRow[] = [];
  let accessoryFee = 0;
  if (accessoryIds.length > 0) {
    const loaded = await loadAccessoriesByIds(c.env.DB, accessoryIds, {
      requireAddon: true,
    });
    if (!loaded) {
      return apiError(
        c,
        400,
        "ACCESSORY_INVALID",
        "One or more accessories are invalid or not available as add-ons",
      );
    }
    orderAccessories = loaded;
    accessoryFee = sumAccessorySalePrice(loaded);
  }

  const clientBase = Number(body.basePrice ?? body.base_price);
  const clientFabric = Number(body.fabricFee ?? body.fabric_fee);
  const clientDelivery = Number(body.deliveryFee ?? body.delivery_fee);
  const clientAccessoryRaw = Number(body.accessoryFee ?? body.accessory_fee);
  const clientAccessoryFee = Number.isFinite(clientAccessoryRaw)
    ? clientAccessoryRaw
    : 0;
  const clientTotal = Number(body.totalPrice ?? body.total_price);
  const serverTotal = quote.total + accessoryFee;
  if (
    Number.isFinite(clientTotal) &&
    !pricesMatchWithAccessories(
      {
        base: clientBase,
        fabric: clientFabric,
        delivery: clientDelivery,
        accessory: clientAccessoryFee,
        total: clientTotal,
      },
      {
        base: quote.basePrice,
        fabric: quote.fabricFee,
        delivery: quote.deliveryFee,
        accessory: accessoryFee,
        total: serverTotal,
      },
    )
  ) {
    return apiError(
      c,
      409,
      "QUOTE_MISMATCH",
      "Price no longer matches the server quote. Refresh and try again.",
    );
  }

  const basePrice = quote.basePrice;
  const fabricFee = quote.fabricFee;
  const deliveryFee = quote.deliveryFee;
  const totalPrice = serverTotal;
  const id = uuidv4();

  try {
    await c.env.DB.prepare(
      `INSERT INTO orders (id, user_id, design_id, designer_id, tailor_id, status,
        delivery_address, delivery_city, delivery_phone, delivery_notes,
        delivery_lat, delivery_lng, price_plan_id, assignment_method,
        base_price, fabric_fee, delivery_fee, accessory_fee, total_price, payment_token)
        VALUES (?, ?, ?, ?, ?, 'placed', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    )
      .bind(
        id,
        userId,
        designId,
        designerId,
        quote.tailorId,
        deliveryAddress,
        deliveryCity,
        deliveryPhone,
        body.deliveryNotes ?? null,
        lat,
        lng,
        quote.pricePlanId,
        quote.assignmentMethod,
        basePrice,
        fabricFee,
        deliveryFee,
        accessoryFee,
        totalPrice,
        body.paymentToken ?? null,
      )
      .run();

    if (orderAccessories.length > 0) {
      await insertOrderAccessoryLines(c.env.DB, id, orderAccessories);
    }

    await c.env.DB.prepare(
      "INSERT INTO order_status_history (id, order_id, status) VALUES (?, ?, 'placed')",
    )
      .bind(uuidv4(), id)
      .run();
    await c.env.DB.prepare(
      "INSERT INTO order_idempotency_keys (id, user_id, idempotency_key, order_id) VALUES (?, ?, ?, ?)",
    )
      .bind(uuidv4(), userId, idempotencyKey, id)
      .run();

    if (designerId && designerId !== userId) {
      const commissionPct = designerCommissionPct(c.env);
      const commissionAmount = Math.round(totalPrice * (commissionPct / 100));
      await c.env.DB.prepare(
        `INSERT OR IGNORE INTO commissions
           (id, order_id, designer_id, buyer_id, amount, percentage, currency, status)
         VALUES (?, ?, ?, ?, ?, ?, 'QAR', 'pending')`,
      )
        .bind(
          uuidv4(),
          id,
          designerId,
          userId,
          commissionAmount,
          commissionPct,
        )
        .run();
    }

    await c.env.DB.prepare(
      "UPDATE designs SET order_count = (SELECT COUNT(*) FROM orders WHERE design_id = ?) WHERE id = ?",
    )
      .bind(designId, designId)
      .run();
  } catch (error) {
    console.error("failed to create order", error);
    return apiError(c, 500, "ORDER_CREATE_FAILED", "Could not create order");
  }

  const created = await loadCustomerOrderPayload(c.env.DB, userId, id);
  return c.json(created ?? { id }, 201);
});

orderRoutes.delete("/:id", async (c) => {
  const userId = c.get("userId") as string;
  const id = c.req.param("id");

  const order = await c.env.DB.prepare(
    "SELECT id, status FROM orders WHERE id = ? AND user_id = ?",
  )
    .bind(id, userId)
    .first<{ id: string; status: string }>();
  if (!order) return apiError(c, 404, "ORDER_NOT_FOUND", "Order not found");
  if (order.status === "delivered" || order.status === "cancelled") {
    return apiError(
      c,
      400,
      "ORDER_CANCELLATION_INVALID",
      "Order can no longer be cancelled",
    );
  }

  await c.env.DB.prepare(
    "UPDATE orders SET status = 'cancelled', updated_at = datetime('now') WHERE id = ? AND user_id = ?",
  )
    .bind(id, userId)
    .run();
  await c.env.DB.prepare(
    "INSERT INTO order_status_history (id, order_id, status, note, updated_by) VALUES (?, ?, 'cancelled', ?, ?)",
  )
    .bind(uuidv4(), id, "Cancelled by customer", userId)
    .run();
  await c.env.DB.prepare(
    "UPDATE commissions SET status = 'void', updated_at = datetime('now') WHERE order_id = ? AND status IN ('pending','approved')",
  )
    .bind(id)
    .run();

  return c.json({ cancelled: true });
});

orderRoutes.patch("/:id/status", requireRole("tailor"), async (c) => {
  const id = c.req.param("id");
  const userId = c.get("userId") as string;
  const body = (await c.req.json()) as Record<string, unknown>;
  const status = String(body.status ?? "").trim().toLowerCase();
  if (!status) return apiError(c, 400, "STATUS_REQUIRED", "status is required");
  if (!validOrderStatuses.has(status)) {
    return apiError(c, 400, "INVALID_STATUS", "Invalid order status");
  }
  const current = await c.env.DB.prepare(
    "SELECT status, tailor_id, courier_id FROM orders WHERE id = ?",
  )
    .bind(id)
    .first<{ status: string; tailor_id: string | null; courier_id: string | null }>();
  if (!current) {
    return apiError(c, 404, "ORDER_NOT_FOUND", "Order not found");
  }
  const role = (c.get("userRole") as string | undefined)?.toLowerCase();
  if (role === "tailor" && current.tailor_id && current.tailor_id !== userId) {
    return apiError(c, 403, "FORBIDDEN", "Not your assigned order");
  }
  const allowed = statusTransitions[current.status.toLowerCase()] ?? new Set();
  if (!allowed.has(status)) {
    return apiError(
      c,
      409,
      "INVALID_STATUS_TRANSITION",
      `Cannot transition from ${current.status} to ${status}`,
    );
  }

  let handoffNote: string | null = body.note ? String(body.note) : null;
  if (status === "ready_to_ship") {
    let courierId = current.courier_id;
    let courierName: string | null = null;
    if (courierId) {
      const existing = await c.env.DB.prepare(
        "SELECT name FROM users WHERE id = ?",
      )
        .bind(courierId)
        .first<{ name: string | null }>();
      courierName = existing?.name?.trim() || "Delivery partner";
    } else {
      const picked = await pickCourierForDelivery(c.env.DB);
      if (!picked) {
        return apiError(
          c,
          503,
          "NO_COURIER_AVAILABLE",
          "No delivery partner is available to accept this handoff",
        );
      }
      courierId = picked.courierId;
      courierName = picked.courierName;
    }
    handoffNote =
      handoffNote ?? `Handed off to ${courierName} for delivery`;
    await c.env.DB.prepare(
      `UPDATE orders
       SET status = ?, courier_id = ?, updated_at = datetime('now')
       WHERE id = ?`,
    )
      .bind(status, courierId, id)
      .run();
  } else {
    await c.env.DB.prepare(
      "UPDATE orders SET status = ?, updated_at = datetime('now') WHERE id = ?",
    )
      .bind(status, id)
      .run();
  }

  await c.env.DB.prepare(
    "INSERT INTO order_status_history (id, order_id, status, note, updated_by) VALUES (?, ?, ?, ?, ?)",
  )
    .bind(uuidv4(), id, status, handoffNote, userId)
    .run();

  if (status === "delivered") {
    await c.env.DB.prepare(
      "UPDATE commissions SET status = 'approved', updated_at = datetime('now') WHERE order_id = ? AND status = 'pending'",
    )
      .bind(id)
      .run();
  } else if (status === "cancelled") {
    await c.env.DB.prepare(
      "UPDATE commissions SET status = 'void', updated_at = datetime('now') WHERE order_id = ? AND status IN ('pending','approved')",
    )
      .bind(id)
      .run();
  }

  const template = orderStatusTemplates[status];
  if (template) {
    const owner = await c.env.DB.prepare(
      "SELECT user_id FROM orders WHERE id = ?",
    )
      .bind(id)
      .first<{ user_id: string }>();
    if (owner) {
      await sendToUser({
        env: c.env,
        userIds: [owner.user_id],
        headings: template.headings,
        contents: template.contents,
        route: `/orders/detail/${id}`,
      });
    }
  }

  const order = await loadTailorOrderPayload(c.env.DB, userId, id);
  if (!order) {
    return c.json({ updated: true, status });
  }
  return c.json({ ...order, updated: true });
});
