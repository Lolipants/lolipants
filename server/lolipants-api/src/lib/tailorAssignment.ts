import {
  computeTailorQuote,
  loadActiveTailorPlan,
  planCanPriceDesign,
  type ActiveTailorPlan,
  type ResolvedTailorPrice,
} from "./tailorPricing";

export type TailorCandidate = {
  tailorId: string;
  tailorName: string;
  shopName: string | null;
  lat: number;
  lng: number;
  distanceKm: number;
  plan: ActiveTailorPlan;
  quote: ResolvedTailorPrice;
};

export type DesignForAssignment = {
  garment_type: string;
  fabric_quality: string | null;
};

/** Haversine distance in kilometres. */
export function haversineKm(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number,
): number {
  const toRad = (d: number) => (d * Math.PI) / 180;
  const r = 6371;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return r * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

type TailorProfileRow = {
  user_id: string;
  shop_name: string | null;
  lat: number | null;
  lng: number | null;
  service_radius_km: number | null;
  is_accepting_orders: number | null;
  created_at: string | null;
  name: string | null;
};

export async function pickNearestTailor(input: {
  db: D1Database;
  deliveryLat: number;
  deliveryLng: number;
  city: string;
  design: DesignForAssignment;
}): Promise<TailorCandidate | null> {
  const { results } = await input.db
    .prepare(
      `SELECT tp.user_id, tp.shop_name, tp.lat, tp.lng, tp.service_radius_km,
              tp.is_accepting_orders, tp.created_at, u.name
       FROM tailor_profiles tp
       JOIN users u ON u.id = tp.user_id
       WHERE tp.is_accepting_orders = 1
         AND tp.lat IS NOT NULL
         AND tp.lng IS NOT NULL
         AND u.role = 'tailor'`,
    )
    .all<TailorProfileRow>();

  const rows = results ?? [];
  const candidates: TailorCandidate[] = [];

  for (const row of rows) {
    if (row.lat == null || row.lng == null) continue;
    const radius = row.service_radius_km ?? 50;
    const distanceKm = haversineKm(
      input.deliveryLat,
      input.deliveryLng,
      row.lat,
      row.lng,
    );
    if (distanceKm > radius) continue;

    const plan = await loadActiveTailorPlan(input.db, row.user_id);
    if (!plan || plan.garmentPrices.length === 0) continue;
    if (!planCanPriceDesign(plan, input.design.garment_type, input.design.fabric_quality)) {
      continue;
    }

    const quote = computeTailorQuote({
      plan,
      garmentType: input.design.garment_type,
      fabricQuality: input.design.fabric_quality,
      city: input.city,
    });
    if (!quote) continue;

    candidates.push({
      tailorId: row.user_id,
      tailorName: row.name ?? "Tailor",
      shopName: row.shop_name,
      lat: row.lat,
      lng: row.lng,
      distanceKm,
      plan,
      quote,
    });
  }

  if (candidates.length === 0) return null;

  candidates.sort((a, b) => {
    if (a.distanceKm !== b.distanceKm) return a.distanceKm - b.distanceKm;
    if (a.quote.total !== b.quote.total) return a.quote.total - b.quote.total;
    return (a.tailorId < b.tailorId ? -1 : 1);
  });

  return candidates[0] ?? null;
}
