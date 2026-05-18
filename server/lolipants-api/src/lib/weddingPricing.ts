import { haversineKm } from "./tailorAssignment";
import { platformDeliveryFeeFor } from "./platformPricingDefaults";
import { loadActiveTailorPlan, resolveDeliveryFee } from "./tailorPricing";

export type WeddingDressCategory = "wedding_dress" | "bridesmaid";
export type WeddingFulfillment = "rent" | "buy";

export type WeddingDressRow = {
  id: string;
  label_en: string;
  label_ar: string;
  category: WeddingDressCategory;
  image_url: string;
  rent_price_per_day: number;
  sale_price: number;
  insurance_deposit: number;
  is_active: number;
  sort_order: number;
};

export type TailorWeddingPriceRow = {
  tailor_id: string;
  category: WeddingDressCategory;
  rent_price_per_day: number;
  sale_price: number;
  insurance_deposit: number;
};

export type ResolvedWeddingPrices = {
  rentPricePerDay: number;
  salePrice: number;
  insuranceDeposit: number;
};

export function resolveWeddingPrices(
  dress: WeddingDressRow,
  tailorOverride: TailorWeddingPriceRow | null,
): ResolvedWeddingPrices {
  if (tailorOverride) {
    return {
      rentPricePerDay: tailorOverride.rent_price_per_day,
      salePrice: tailorOverride.sale_price,
      insuranceDeposit: tailorOverride.insurance_deposit,
    };
  }
  return {
    rentPricePerDay: dress.rent_price_per_day,
    salePrice: dress.sale_price,
    insuranceDeposit: dress.insurance_deposit,
  };
}

export type WeddingQuoteInput = {
  dress: WeddingDressRow;
  fulfillment: WeddingFulfillment;
  rentalDays: number;
  city: string;
  deliveryFee: number;
  prices: ResolvedWeddingPrices;
};

export type WeddingQuoteResult = {
  fulfillment: WeddingFulfillment;
  rentalDays: number | null;
  rentPricePerDay: number;
  rentSubtotal: number;
  insuranceDeposit: number;
  salePrice: number;
  basePrice: number;
  fabricFee: number;
  deliveryFee: number;
  total: number;
  currency: string;
};

export function computeWeddingQuote(input: WeddingQuoteInput): WeddingQuoteResult {
  const currency = "QAR";
  if (input.fulfillment === "rent") {
    const days = Math.max(1, Math.floor(input.rentalDays));
    const rentSubtotal = input.prices.rentPricePerDay * days;
    const insuranceDeposit = input.prices.insuranceDeposit;
    const deliveryFee = input.deliveryFee;
    const total = rentSubtotal + insuranceDeposit + deliveryFee;
    return {
      fulfillment: "rent",
      rentalDays: days,
      rentPricePerDay: input.prices.rentPricePerDay,
      rentSubtotal,
      insuranceDeposit,
      salePrice: 0,
      basePrice: rentSubtotal,
      fabricFee: insuranceDeposit,
      deliveryFee,
      total,
      currency,
    };
  }
  const salePrice = input.prices.salePrice;
  const deliveryFee = input.deliveryFee;
  const total = salePrice + deliveryFee;
  return {
    fulfillment: "buy",
    rentalDays: null,
    rentPricePerDay: input.prices.rentPricePerDay,
    rentSubtotal: 0,
    insuranceDeposit: 0,
    salePrice,
    basePrice: salePrice,
    fabricFee: 0,
    deliveryFee,
    total,
    currency,
  };
}

type TailorProfileRow = {
  user_id: string;
  shop_name: string | null;
  lat: number | null;
  lng: number | null;
  service_radius_km: number | null;
  is_accepting_orders: number | null;
  name: string | null;
};

export type WeddingTailorCandidate = {
  tailorId: string;
  tailorName: string;
  shopName: string | null;
  distanceKm: number;
  prices: ResolvedWeddingPrices;
  deliveryFee: number;
  assignmentMethod: "proximity" | "fallback";
};

export async function pickTailorForWedding(input: {
  db: D1Database;
  dress: WeddingDressRow;
  city: string;
  deliveryLat: number;
  deliveryLng: number;
}): Promise<WeddingTailorCandidate | null> {
  const { results } = await input.db
    .prepare(
      `SELECT tp.user_id, tp.shop_name, tp.lat, tp.lng, tp.service_radius_km,
              tp.is_accepting_orders, u.name
       FROM tailor_profiles tp
       JOIN users u ON u.id = tp.user_id
       WHERE tp.is_accepting_orders = 1
         AND tp.lat IS NOT NULL AND tp.lng IS NOT NULL`,
    )
    .all<TailorProfileRow>();

  const rows = results ?? [];
  if (rows.length === 0) return null;

  const candidates: Array<WeddingTailorCandidate & { distanceKm: number }> = [];

  for (const row of rows) {
    const lat = row.lat!;
    const lng = row.lng!;
    const distanceKm = haversineKm(
      input.deliveryLat,
      input.deliveryLng,
      lat,
      lng,
    );
    const radius = row.service_radius_km ?? 50;
    if (distanceKm > radius) continue;

    const override = await input.db
      .prepare(
        `SELECT tailor_id, category, rent_price_per_day, sale_price, insurance_deposit
         FROM tailor_wedding_prices
         WHERE tailor_id = ? AND category = ?`,
      )
      .bind(row.user_id, input.dress.category)
      .first<TailorWeddingPriceRow>();

    const prices = resolveWeddingPrices(input.dress, override ?? null);

    let deliveryFee = platformDeliveryFeeFor(input.city);
    const plan = await loadActiveTailorPlan(input.db, row.user_id);
    if (plan) {
      deliveryFee = resolveDeliveryFee(plan.deliveryFees, input.city);
    }

    candidates.push({
      tailorId: row.user_id,
      tailorName: row.name ?? "Tailor",
      shopName: row.shop_name,
      distanceKm,
      prices,
      deliveryFee,
      assignmentMethod: "proximity",
    });
  }

  if (candidates.length === 0) {
    const fallback = rows[0];
    const override = await input.db
      .prepare(
        `SELECT tailor_id, category, rent_price_per_day, sale_price, insurance_deposit
         FROM tailor_wedding_prices
         WHERE tailor_id = ? AND category = ?`,
      )
      .bind(fallback.user_id, input.dress.category)
      .first<TailorWeddingPriceRow>();
    const prices = resolveWeddingPrices(input.dress, override ?? null);
    let deliveryFee = platformDeliveryFeeFor(input.city);
    const plan = await loadActiveTailorPlan(input.db, fallback.user_id);
    if (plan) {
      deliveryFee = resolveDeliveryFee(plan.deliveryFees, input.city);
    }
    return {
      tailorId: fallback.user_id,
      tailorName: fallback.name ?? "Tailor",
      shopName: fallback.shop_name,
      distanceKm: haversineKm(
        input.deliveryLat,
        input.deliveryLng,
        fallback.lat!,
        fallback.lng!,
      ),
      prices,
      deliveryFee,
      assignmentMethod: "fallback",
    };
  }

  candidates.sort((a, b) => {
    if (a.distanceKm !== b.distanceKm) return a.distanceKm - b.distanceKm;
    return a.tailorId < b.tailorId ? -1 : 1;
  });
  return candidates[0]!;
}
