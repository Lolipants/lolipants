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

export type TailorAssignmentMethod = "proximity" | "fallback";

export type TailorPickResult = {
  candidate: TailorCandidate;
  assignmentMethod: TailorAssignmentMethod;
};

function sortTailorCandidates(a: TailorCandidate, b: TailorCandidate): number {
  if (a.distanceKm !== b.distanceKm) return a.distanceKm - b.distanceKm;
  if (a.quote.total !== b.quote.total) return a.quote.total - b.quote.total;
  return a.tailorId < b.tailorId ? -1 : 1;
}

async function collectTailorCandidates(
  input: {
    db: D1Database;
    deliveryLat: number;
    deliveryLng: number;
    city: string;
    design: DesignForAssignment;
  },
  options: { withinServiceRadius: boolean },
): Promise<TailorCandidate[]> {
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
    if (options.withinServiceRadius && distanceKm > radius) continue;

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

  candidates.sort(sortTailorCandidates);
  return candidates;
}

/**
 * Picks a tailor for checkout: nearest within service radius, else nearest
 * accepting tailor who can price the design (ignores radius).
 */
export async function pickTailorForDelivery(input: {
  db: D1Database;
  deliveryLat: number;
  deliveryLng: number;
  city: string;
  design: DesignForAssignment;
}): Promise<TailorPickResult | null> {
  const base = {
    db: input.db,
    deliveryLat: input.deliveryLat,
    deliveryLng: input.deliveryLng,
    city: input.city,
    design: input.design,
  };

  const inRadius = await collectTailorCandidates(base, {
    withinServiceRadius: true,
  });
  if (inRadius.length > 0) {
    return { candidate: inRadius[0]!, assignmentMethod: "proximity" };
  }

  const fallback = await collectTailorCandidates(base, {
    withinServiceRadius: false,
  });
  if (fallback.length > 0) {
    return { candidate: fallback[0]!, assignmentMethod: "fallback" };
  }

  return null;
}

/** @deprecated Use [pickTailorForDelivery]; kept for tests. */
export async function pickNearestTailor(input: {
  db: D1Database;
  deliveryLat: number;
  deliveryLng: number;
  city: string;
  design: DesignForAssignment;
}): Promise<TailorCandidate | null> {
  const picked = await pickTailorForDelivery(input);
  return picked?.candidate ?? null;
}
