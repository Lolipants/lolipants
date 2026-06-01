import { v4 as uuidv4 } from "uuid";
import { haversineKm } from "./tailorAssignment";
import { platformDeliveryFeeFor } from "./platformPricingDefaults";
import { loadActiveTailorPlan, resolveDeliveryFee } from "./tailorPricing";

export type AccessoryCategory = "scarf" | "bag" | "jewellery" | "other";

export type AccessoryRow = {
  id: string;
  label_en: string;
  label_ar: string;
  category: AccessoryCategory;
  image_url: string;
  sale_price: number;
  description_en: string | null;
  description_ar: string | null;
  allow_addon: number;
  is_active: number;
  sort_order: number;
};

const VALID_CATEGORIES = new Set<AccessoryCategory>([
  "scarf",
  "bag",
  "jewellery",
  "other",
]);

export function isAccessoryCategory(value: string): value is AccessoryCategory {
  return VALID_CATEGORIES.has(value as AccessoryCategory);
}

export function parseAccessoryIds(raw: unknown): string[] {
  if (raw == null) return [];
  if (Array.isArray(raw)) {
    return [...new Set(raw.map((v) => String(v).trim()).filter((id) => id.length > 0))].slice(
      0,
      10,
    );
  }
  const single = String(raw).trim();
  if (!single) return [];
  return single
    .split(",")
    .map((s) => s.trim())
    .filter((id) => id.length > 0)
    .slice(0, 10);
}

export function sumAccessorySalePrice(rows: AccessoryRow[]): number {
  return rows.reduce((sum, row) => sum + (row.sale_price ?? 0), 0);
}

export async function loadAccessoriesByIds(
  db: D1Database,
  ids: string[],
  options?: { requireAddon?: boolean },
): Promise<AccessoryRow[] | null> {
  if (ids.length === 0) return [];
  const placeholders = ids.map(() => "?").join(", ");
  let query = `SELECT id, label_en, label_ar, category, image_url, sale_price,
                      description_en, description_ar, allow_addon, is_active, sort_order
               FROM accessories
               WHERE is_active = 1 AND id IN (${placeholders})`;
  if (options?.requireAddon) {
    query += " AND allow_addon = 1";
  }
  const { results } = await db.prepare(query).bind(...ids).all<AccessoryRow>();
  const rows = results ?? [];
  if (rows.length !== ids.length) return null;
  const byId = new Map(rows.map((r) => [r.id, r]));
  return ids.map((id) => byId.get(id)!).filter(Boolean);
}

export type AccessoryTailorCandidate = {
  tailorId: string;
  tailorName: string;
  shopName: string | null;
  distanceKm: number;
  deliveryFee: number;
  assignmentMethod: "proximity" | "fallback";
};

export async function pickTailorForAccessory(input: {
  db: D1Database;
  city: string;
  deliveryLat: number;
  deliveryLng: number;
}): Promise<AccessoryTailorCandidate | null> {
  const { results } = await input.db
    .prepare(
      `SELECT tp.user_id, tp.shop_name, tp.lat, tp.lng, tp.service_radius_km,
              tp.is_accepting_orders, u.name
       FROM tailor_profiles tp
       JOIN users u ON u.id = tp.user_id
       WHERE tp.is_accepting_orders = 1
         AND tp.lat IS NOT NULL AND tp.lng IS NOT NULL`,
    )
    .all<{
      user_id: string;
      shop_name: string | null;
      lat: number;
      lng: number;
      service_radius_km: number | null;
      name: string | null;
    }>();

  const rows = results ?? [];
  if (rows.length === 0) return null;

  type Scored = AccessoryTailorCandidate & { distanceKm: number };
  const candidates: Scored[] = [];

  for (const row of rows) {
    const distanceKm = haversineKm(
      input.deliveryLat,
      input.deliveryLng,
      row.lat,
      row.lng,
    );
    const radius = row.service_radius_km ?? 50;
    if (distanceKm > radius) continue;

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
      deliveryFee,
      assignmentMethod: "proximity",
    });
  }

  if (candidates.length === 0) {
    const fallback = rows[0]!;
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
        fallback.lat,
        fallback.lng,
      ),
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

export type AccessoryQuoteResult = {
  accessorySubtotal: number;
  basePrice: number;
  fabricFee: number;
  deliveryFee: number;
  accessoryFee: number;
  total: number;
  currency: string;
};

export function computeAccessoryPurchaseQuote(input: {
  accessories: AccessoryRow[];
  deliveryFee: number;
}): AccessoryQuoteResult {
  const accessorySubtotal = sumAccessorySalePrice(input.accessories);
  const deliveryFee = input.deliveryFee;
  return {
    accessorySubtotal,
    basePrice: accessorySubtotal,
    fabricFee: 0,
    deliveryFee,
    accessoryFee: accessorySubtotal,
    total: accessorySubtotal + deliveryFee,
    currency: "QAR",
  };
}

export async function insertOrderAccessoryLines(
  db: D1Database,
  orderId: string,
  accessories: AccessoryRow[],
): Promise<void> {
  for (const row of accessories) {
    await db
      .prepare(
        `INSERT INTO order_accessories
           (id, order_id, accessory_id, quantity, unit_price, label_en, label_ar)
         VALUES (?, ?, ?, 1, ?, ?, ?)`,
      )
      .bind(
        uuidv4(),
        orderId,
        row.id,
        row.sale_price,
        row.label_en,
        row.label_ar,
      )
      .run();
  }
}

export async function loadOrderAccessoryLines(
  db: D1Database,
  orderId: string,
): Promise<Record<string, unknown>[]> {
  const { results } = await db
    .prepare(
      `SELECT id, order_id, accessory_id, quantity, unit_price, label_en, label_ar, created_at
       FROM order_accessories WHERE order_id = ? ORDER BY created_at ASC`,
    )
    .bind(orderId)
    .all();
  return (results ?? []) as Record<string, unknown>[];
}
