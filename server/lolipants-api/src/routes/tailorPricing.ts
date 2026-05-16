import { Hono } from "hono";
import { v4 as uuidv4 } from "uuid";
import { apiError } from "../lib/http";
import {
  PLATFORM_DELIVERY_FEES,
  TAILOR_FABRIC_QUALITIES,
  TAILOR_GARMENT_TYPES,
  normalizeCityKey,
} from "../lib/platformPricingDefaults";
import {
  computeTailorQuote,
  loadActiveTailorPlan,
  resolveDeliveryFee,
} from "../lib/tailorPricing";
import { seedTailorPricingDefaults } from "../lib/tailorPlanSeed";
import { requireAuth, requireRole } from "../middleware/auth";
import type { AppVariables, Env } from "../types";

export const tailorPricingRoutes = new Hono<{
  Bindings: Env;
  Variables: AppVariables;
}>();

tailorPricingRoutes.use("*", requireAuth);
tailorPricingRoutes.use("*", requireRole("tailor"));

async function getOrCreateActivePlanId(
  db: D1Database,
  tailorId: string,
): Promise<string> {
  const existing = await db
    .prepare(
      `SELECT id FROM tailor_price_plans WHERE tailor_id = ? AND is_active = 1 LIMIT 1`,
    )
    .bind(tailorId)
    .first<{ id: string }>();
  if (existing) return existing.id;
  const seeded = await seedTailorPricingDefaults(db, tailorId);
  return seeded.planId;
}

tailorPricingRoutes.get("/", async (c) => {
  const tailorId = c.get("userId") as string;
  const profile = await c.env.DB.prepare(
    `SELECT user_id, shop_name, address, city, lat, lng, service_radius_km,
            is_accepting_orders, created_at, updated_at
     FROM tailor_profiles WHERE user_id = ?`,
  )
    .bind(tailorId)
    .first<Record<string, unknown>>();

  let planId = await getOrCreateActivePlanId(c.env.DB, tailorId);
  const plan = await c.env.DB.prepare(
    `SELECT id, tailor_id, name, currency, is_active, created_at, updated_at
     FROM tailor_price_plans WHERE id = ?`,
  )
    .bind(planId)
    .first<Record<string, unknown>>();

  const garmentPrices = await c.env.DB.prepare(
    `SELECT garment_type, fabric_quality, base_price, fabric_fee
     FROM tailor_garment_prices WHERE plan_id = ? ORDER BY garment_type, fabric_quality`,
  )
    .bind(planId)
    .all();
  const deliveryFees = await c.env.DB.prepare(
    `SELECT city_key, fee FROM tailor_delivery_fees WHERE plan_id = ? ORDER BY city_key`,
  )
    .bind(planId)
    .all();

  return c.json({
    profile: profile ?? null,
    plan,
    garmentPrices: garmentPrices.results ?? [],
    deliveryFees: deliveryFees.results ?? [],
    garmentTypes: TAILOR_GARMENT_TYPES,
    fabricQualities: TAILOR_FABRIC_QUALITIES,
    defaultDeliveryFees: PLATFORM_DELIVERY_FEES,
  });
});

tailorPricingRoutes.put("/profile", async (c) => {
  const tailorId = c.get("userId") as string;
  const body = (await c.req.json()) as Record<string, unknown>;
  const lat = body.lat != null ? Number(body.lat) : null;
  const lng = body.lng != null ? Number(body.lng) : null;
  if (lat != null && (Number.isNaN(lat) || lat < -90 || lat > 90)) {
    return apiError(c, 400, "INVALID_LAT", "lat must be between -90 and 90");
  }
  if (lng != null && (Number.isNaN(lng) || lng < -180 || lng > 180)) {
    return apiError(c, 400, "INVALID_LNG", "lng must be between -180 and 180");
  }
  const radius = body.serviceRadiusKm != null
    ? Number(body.serviceRadiusKm)
    : 50;
  const accepting = Boolean(body.isAcceptingOrders);

  const existing = await c.env.DB.prepare(
    "SELECT user_id FROM tailor_profiles WHERE user_id = ?",
  )
    .bind(tailorId)
    .first();
  if (!existing) {
    await seedTailorPricingDefaults(c.env.DB, tailorId, {
      shopName: body.shopName?.toString(),
      lat: lat ?? undefined,
      lng: lng ?? undefined,
      city: body.city?.toString(),
      acceptingOrders: false,
    });
  }

  if (accepting) {
    const profile = await c.env.DB.prepare(
      "SELECT lat, lng FROM tailor_profiles WHERE user_id = ?",
    )
      .bind(tailorId)
      .first<{ lat: number | null; lng: number | null }>();
    const plan = await loadActiveTailorPlan(c.env.DB, tailorId);
    const effectiveLat = lat ?? profile?.lat;
    const effectiveLng = lng ?? profile?.lng;
    if (effectiveLat == null || effectiveLng == null) {
      return apiError(
        c,
        400,
        "WORKSHOP_LOCATION_REQUIRED",
        "Set workshop latitude and longitude before accepting orders",
      );
    }
    if (!plan || plan.garmentPrices.length === 0) {
      return apiError(
        c,
        400,
        "PRICE_PLAN_REQUIRED",
        "Configure at least one garment price before accepting orders",
      );
    }
  }

  await c.env.DB.prepare(
    `UPDATE tailor_profiles SET
       shop_name = COALESCE(?, shop_name),
       address = COALESCE(?, address),
       city = COALESCE(?, city),
       lat = COALESCE(?, lat),
       lng = COALESCE(?, lng),
       service_radius_km = ?,
       is_accepting_orders = ?,
       updated_at = datetime('now')
     WHERE user_id = ?`,
  )
    .bind(
      body.shopName ?? null,
      body.address ?? null,
      body.city ?? null,
      lat,
      lng,
      Number.isFinite(radius) ? radius : 50,
      accepting ? 1 : 0,
      tailorId,
    )
    .run();

  const updated = await c.env.DB.prepare(
    "SELECT * FROM tailor_profiles WHERE user_id = ?",
  )
    .bind(tailorId)
    .first();
  return c.json(updated);
});

tailorPricingRoutes.put("/plan", async (c) => {
  const tailorId = c.get("userId") as string;
  const body = (await c.req.json()) as Record<string, unknown>;
  const planId = await getOrCreateActivePlanId(c.env.DB, tailorId);
  await c.env.DB.prepare(
    `UPDATE tailor_price_plans SET
       name = COALESCE(?, name),
       currency = COALESCE(?, currency),
       updated_at = datetime('now')
     WHERE id = ? AND tailor_id = ?`,
  )
    .bind(body.name ?? null, body.currency ?? null, planId, tailorId)
    .run();
  const plan = await c.env.DB.prepare(
    "SELECT * FROM tailor_price_plans WHERE id = ?",
  )
    .bind(planId)
    .first();
  return c.json(plan);
});

tailorPricingRoutes.put("/garment-prices", async (c) => {
  const tailorId = c.get("userId") as string;
  const body = (await c.req.json()) as Record<string, unknown>;
  const rows = Array.isArray(body.prices) ? body.prices : [];
  const planId = await getOrCreateActivePlanId(c.env.DB, tailorId);

  await c.env.DB.prepare(
    "DELETE FROM tailor_garment_prices WHERE plan_id = ?",
  )
    .bind(planId)
    .run();

  for (const raw of rows) {
    if (!raw || typeof raw !== "object") continue;
    const row = raw as Record<string, unknown>;
    const garmentType = String(row.garmentType ?? row.garment_type ?? "").trim();
    const fabricQuality = String(
      row.fabricQuality ?? row.fabric_quality ?? "",
    ).trim();
    const basePrice = Number(row.basePrice ?? row.base_price);
    const fabricFee = Number(row.fabricFee ?? row.fabric_fee);
    if (!garmentType || !fabricQuality) continue;
    if (!Number.isFinite(basePrice) || !Number.isFinite(fabricFee)) continue;
    await c.env.DB.prepare(
      `INSERT INTO tailor_garment_prices
       (id, plan_id, garment_type, fabric_quality, base_price, fabric_fee)
       VALUES (?, ?, ?, ?, ?, ?)`,
    )
      .bind(uuidv4(), planId, garmentType, fabricQuality, basePrice, fabricFee)
      .run();
  }

  const garmentPrices = await c.env.DB.prepare(
    `SELECT garment_type, fabric_quality, base_price, fabric_fee
     FROM tailor_garment_prices WHERE plan_id = ?`,
  )
    .bind(planId)
    .all();
  return c.json({ planId, garmentPrices: garmentPrices.results ?? [] });
});

tailorPricingRoutes.put("/delivery-fees", async (c) => {
  const tailorId = c.get("userId") as string;
  const body = (await c.req.json()) as Record<string, unknown>;
  const rows = Array.isArray(body.fees) ? body.fees : [];
  const planId = await getOrCreateActivePlanId(c.env.DB, tailorId);

  await c.env.DB.prepare("DELETE FROM tailor_delivery_fees WHERE plan_id = ?")
    .bind(planId)
    .run();

  for (const raw of rows) {
    if (!raw || typeof raw !== "object") continue;
    const row = raw as Record<string, unknown>;
    const cityKey = normalizeCityKey(
      String(row.cityKey ?? row.city_key ?? ""),
    );
    const fee = Number(row.fee);
    if (!cityKey || !Number.isFinite(fee)) continue;
    await c.env.DB.prepare(
      `INSERT INTO tailor_delivery_fees (id, plan_id, city_key, fee)
       VALUES (?, ?, ?, ?)`,
    )
      .bind(uuidv4(), planId, cityKey, fee)
      .run();
  }

  const deliveryFees = await c.env.DB.prepare(
    "SELECT city_key, fee FROM tailor_delivery_fees WHERE plan_id = ?",
  )
    .bind(planId)
    .all();
  return c.json({ planId, deliveryFees: deliveryFees.results ?? [] });
});

tailorPricingRoutes.post("/preview", async (c) => {
  const tailorId = c.get("userId") as string;
  const body = (await c.req.json()) as Record<string, unknown>;
  const garmentType = String(body.garmentType ?? "thobe").trim();
  const fabricQuality = String(body.fabricQuality ?? "standard").trim();
  const city = String(body.city ?? "Doha").trim();
  const plan = await loadActiveTailorPlan(c.env.DB, tailorId);
  if (!plan) {
    return apiError(c, 404, "PLAN_NOT_FOUND", "No active price plan");
  }
  const quote = computeTailorQuote({
    plan,
    garmentType,
    fabricQuality,
    city,
  });
  if (!quote) {
    return apiError(
      c,
      400,
      "PRICE_NOT_CONFIGURED",
      "No price row for this garment and fabric combination",
    );
  }
  return c.json({
    garmentType,
    fabricQuality,
    city,
    basePrice: quote.basePrice,
    fabricFee: quote.fabricFee,
    deliveryFee: quote.deliveryFee,
    total: quote.total,
    currency: quote.currency,
  });
});

tailorPricingRoutes.post("/reset-defaults", async (c) => {
  const tailorId = c.get("userId") as string;
  const planId = await getOrCreateActivePlanId(c.env.DB, tailorId);
  await c.env.DB.prepare("DELETE FROM tailor_garment_prices WHERE plan_id = ?")
    .bind(planId)
    .run();
  await c.env.DB.prepare("DELETE FROM tailor_delivery_fees WHERE plan_id = ?")
    .bind(planId)
    .run();
  const { TAILOR_GARMENT_TYPES, TAILOR_FABRIC_QUALITIES, PLATFORM_BASE_PRICE, platformFabricFeeFor, PLATFORM_DELIVERY_FEES } = await import("../lib/platformPricingDefaults");
  const { v4: uuidv4 } = await import("uuid");
  for (const garmentType of TAILOR_GARMENT_TYPES) {
    for (const fabricQuality of TAILOR_FABRIC_QUALITIES) {
      await c.env.DB.prepare(
        `INSERT INTO tailor_garment_prices
         (id, plan_id, garment_type, fabric_quality, base_price, fabric_fee)
         VALUES (?, ?, ?, ?, ?, ?)`,
      )
        .bind(uuidv4(), planId, garmentType, fabricQuality, PLATFORM_BASE_PRICE, platformFabricFeeFor(fabricQuality))
        .run();
    }
  }
  for (const [cityKey, fee] of Object.entries(PLATFORM_DELIVERY_FEES)) {
    await c.env.DB.prepare(
      `INSERT INTO tailor_delivery_fees (id, plan_id, city_key, fee) VALUES (?, ?, ?, ?)`,
    )
      .bind(uuidv4(), planId, cityKey, fee)
      .run();
  }
  return c.json({ ok: true });
});
