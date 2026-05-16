import {
  PLATFORM_BASE_PRICE,
  platformDeliveryFeeFor,
  platformFabricFeeFor,
  normalizeCityKey,
} from "./platformPricingDefaults";

export type GarmentPriceRow = {
  garment_type: string;
  fabric_quality: string;
  base_price: number;
  fabric_fee: number;
};

export type DeliveryFeeRow = {
  city_key: string;
  fee: number;
};

export type ResolvedTailorPrice = {
  planId: string;
  basePrice: number;
  fabricFee: number;
  deliveryFee: number;
  total: number;
  currency: string;
  garmentType: string;
  fabricQuality: string;
  cityKey: string;
};

export type ActiveTailorPlan = {
  planId: string;
  tailorId: string;
  currency: string;
  garmentPrices: GarmentPriceRow[];
  deliveryFees: DeliveryFeeRow[];
};

function normalizeKey(value: string | null | undefined): string {
  return (value ?? "").trim().toLowerCase();
}

/** Resolves garment/fabric row with wildcard fallbacks. */
export function resolveGarmentPriceRow(
  rows: GarmentPriceRow[],
  garmentType: string,
  fabricQuality: string,
): GarmentPriceRow | null {
  const garment = normalizeKey(garmentType) || "thobe";
  const fabric = normalizeKey(fabricQuality) || "standard";
  const keys = [
    `${garment}|${fabric}`,
    `${garment}|*`,
    `*|${fabric}`,
    `*|*`,
  ];
  const map = new Map<string, GarmentPriceRow>();
  for (const row of rows) {
    const g = normalizeKey(row.garment_type) || "*";
    const f = normalizeKey(row.fabric_quality) || "*";
    map.set(`${g}|${f}`, row);
  }
  for (const key of keys) {
    const hit = map.get(key);
    if (hit) return hit;
  }
  return null;
}

export function resolveDeliveryFee(
  fees: DeliveryFeeRow[],
  city: string,
): number {
  const key = normalizeCityKey(city);
  const map = new Map<string, number>();
  for (const row of fees) {
    map.set(normalizeCityKey(row.city_key), row.fee);
  }
  if (map.has(key)) return map.get(key)!;
  if (map.has("default")) return map.get("default")!;
  return platformDeliveryFeeFor(city);
}

export function computeTailorQuote(input: {
  plan: ActiveTailorPlan;
  garmentType: string;
  fabricQuality: string | null | undefined;
  city: string;
}): ResolvedTailorPrice | null {
  const row = resolveGarmentPriceRow(
    input.plan.garmentPrices,
    input.garmentType,
    input.fabricQuality ?? "standard",
  );
  if (!row) return null;
  const basePrice = row.base_price;
  const fabricFee = row.fabric_fee;
  const deliveryFee = resolveDeliveryFee(input.plan.deliveryFees, input.city);
  const cityKey = normalizeCityKey(input.city);
  return {
    planId: input.plan.planId,
    basePrice,
    fabricFee,
    deliveryFee,
    total: basePrice + fabricFee + deliveryFee,
    currency: input.plan.currency,
    garmentType: normalizeKey(input.garmentType) || "thobe",
    fabricQuality: normalizeKey(input.fabricQuality) || "standard",
    cityKey,
  };
}

/** Platform fallback when no tailor plan matches (should not be used in production checkout). */
export function computePlatformQuote(input: {
  garmentType: string;
  fabricQuality: string | null | undefined;
  city: string;
  currency?: string;
}): ResolvedTailorPrice {
  const fabricQuality = normalizeKey(input.fabricQuality) || "standard";
  const basePrice = PLATFORM_BASE_PRICE;
  const fabricFee = platformFabricFeeFor(fabricQuality);
  const deliveryFee = platformDeliveryFeeFor(input.city);
  return {
    planId: "",
    basePrice,
    fabricFee,
    deliveryFee,
    total: basePrice + fabricFee + deliveryFee,
    currency: input.currency ?? "QAR",
    garmentType: normalizeKey(input.garmentType) || "thobe",
    fabricQuality,
    cityKey: normalizeCityKey(input.city),
  };
}

export async function loadActiveTailorPlan(
  db: D1Database,
  tailorId: string,
): Promise<ActiveTailorPlan | null> {
  const plan = await db
    .prepare(
      `SELECT id, tailor_id, currency FROM tailor_price_plans
       WHERE tailor_id = ? AND is_active = 1
       ORDER BY updated_at DESC LIMIT 1`,
    )
    .bind(tailorId)
    .first<{ id: string; tailor_id: string; currency: string }>();
  if (!plan) return null;

  const garmentResult = await db
    .prepare(
      `SELECT garment_type, fabric_quality, base_price, fabric_fee
       FROM tailor_garment_prices WHERE plan_id = ?`,
    )
    .bind(plan.id)
    .all<GarmentPriceRow>();
  const deliveryResult = await db
    .prepare(`SELECT city_key, fee FROM tailor_delivery_fees WHERE plan_id = ?`)
    .bind(plan.id)
    .all<DeliveryFeeRow>();

  return {
    planId: plan.id,
    tailorId: plan.tailor_id,
    currency: plan.currency ?? "QAR",
    garmentPrices: garmentResult.results ?? [],
    deliveryFees: deliveryResult.results ?? [],
  };
}

export function planCanPriceDesign(
  plan: ActiveTailorPlan,
  garmentType: string,
  fabricQuality: string | null | undefined,
): boolean {
  return (
    resolveGarmentPriceRow(
      plan.garmentPrices,
      garmentType,
      fabricQuality ?? "standard",
    ) != null
  );
}
