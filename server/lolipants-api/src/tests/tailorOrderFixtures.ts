/** Shared tailor-pricing fields for API integration tests. */

export const TEST_DELIVERY_LAT = 25.29;
export const TEST_DELIVERY_LNG = 51.53;
export const TEST_TAILOR_ID = "tailor-1";
export const TEST_PLAN_ID = "plan-1";

export const TEST_ORDER_PRICES = {
  basePrice: 350,
  fabricFee: 60,
  deliveryFee: 20,
  totalPrice: 430,
} as const;

export const PREMIUM_ORDER_PRICES = {
  basePrice: 350,
  fabricFee: 120,
  deliveryFee: 20,
  totalPrice: 490,
} as const;

export type FabricTier = "standard" | "premium";

export function orderPricesForFabric(fabric: FabricTier | null | undefined) {
  return fabric === "premium" ? PREMIUM_ORDER_PRICES : TEST_ORDER_PRICES;
}

export function withTailorOrderBody(
  body: Record<string, unknown>,
  opts?: { fabric?: FabricTier },
): Record<string, unknown> {
  const prices = orderPricesForFabric(opts?.fabric ?? "standard");
  return {
    ...body,
    deliveryLat: TEST_DELIVERY_LAT,
    deliveryLng: TEST_DELIVERY_LNG,
    tailorId: TEST_TAILOR_ID,
    ...prices,
  };
}

export function tailorQuoteQuery(designId: string, city = "Doha"): string {
  return `designId=${encodeURIComponent(designId)}&city=${encodeURIComponent(city)}&deliveryLat=${TEST_DELIVERY_LAT}&deliveryLng=${TEST_DELIVERY_LNG}`;
}

export type TailorMockTables = {
  users?: Map<string, Record<string, unknown>>;
  tailorProfiles?: Map<string, Record<string, unknown>>;
  tailorPlans?: Map<string, Record<string, unknown>>;
  tailorGarmentPrices?: Array<Record<string, unknown>>;
  tailorDeliveryFees?: Array<Record<string, unknown>>;
};

/** Attaches default tailor pricing tables used by proximity assignment. */
export function seedTailorPricingTables(db: TailorMockTables): void {
  db.users ??= new Map();
  db.users.set("user-1", { id: "user-1", role: "user", name: "Test User" });
  db.users.set(TEST_TAILOR_ID, {
    id: TEST_TAILOR_ID,
    role: "tailor",
    name: "Test Tailor",
  });

  db.tailorProfiles ??= new Map();
  db.tailorProfiles.set(TEST_TAILOR_ID, {
    user_id: TEST_TAILOR_ID,
    shop_name: "Test Tailor",
    lat: 25.2854,
    lng: 51.531,
    service_radius_km: 50,
    is_accepting_orders: 1,
    created_at: "2026-01-01",
  });

  db.tailorPlans ??= new Map();
  db.tailorPlans.set(TEST_PLAN_ID, {
    id: TEST_PLAN_ID,
    tailor_id: TEST_TAILOR_ID,
    currency: "QAR",
    is_active: 1,
  });

  db.tailorGarmentPrices ??= [];
  if (db.tailorGarmentPrices.length === 0) {
    db.tailorGarmentPrices.push(
      {
        garment_type: "thobe",
        fabric_quality: "standard",
        base_price: 350,
        fabric_fee: 60,
        plan_id: TEST_PLAN_ID,
      },
      {
        garment_type: "thobe",
        fabric_quality: "premium",
        base_price: 350,
        fabric_fee: 120,
        plan_id: TEST_PLAN_ID,
      },
      {
        garment_type: "*",
        fabric_quality: "*",
        base_price: 350,
        fabric_fee: 60,
        plan_id: TEST_PLAN_ID,
      },
    );
  }

  db.tailorDeliveryFees ??= [];
  if (db.tailorDeliveryFees.length === 0) {
    db.tailorDeliveryFees.push(
      { city_key: "doha", fee: 20, plan_id: TEST_PLAN_ID },
      { city_key: "default", fee: 25, plan_id: TEST_PLAN_ID },
    );
  }
}
