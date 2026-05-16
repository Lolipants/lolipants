import { v4 as uuidv4 } from "uuid";
import {
  PLATFORM_BASE_PRICE,
  PLATFORM_DELIVERY_FEES,
  TAILOR_FABRIC_QUALITIES,
  TAILOR_GARMENT_TYPES,
  platformFabricFeeFor,
} from "./platformPricingDefaults";

/** Creates tailor profile + active default price plan for a new tailor user. */
export async function seedTailorPricingDefaults(
  db: D1Database,
  tailorId: string,
  options?: {
    shopName?: string;
    lat?: number;
    lng?: number;
    city?: string;
    acceptingOrders?: boolean;
  },
): Promise<{ planId: string }> {
  const lat = options?.lat ?? 25.2854;
  const lng = options?.lng ?? 51.531;
  const existingProfile = await db
    .prepare("SELECT user_id FROM tailor_profiles WHERE user_id = ?")
    .bind(tailorId)
    .first();
  if (!existingProfile) {
    await db
      .prepare(
        `INSERT INTO tailor_profiles
         (user_id, shop_name, address, city, lat, lng, service_radius_km, is_accepting_orders)
         VALUES (?, ?, NULL, ?, ?, ?, 50, ?)`,
      )
      .bind(
        tailorId,
        options?.shopName ?? "My workshop",
        options?.city ?? "Doha",
        lat,
        lng,
        options?.acceptingOrders === true ? 1 : 0,
      )
      .run();
  }

  const existingPlan = await db
    .prepare(
      `SELECT id FROM tailor_price_plans WHERE tailor_id = ? AND is_active = 1 LIMIT 1`,
    )
    .bind(tailorId)
    .first<{ id: string }>();
  if (existingPlan) return { planId: existingPlan.id };

  const planId = uuidv4();
  await db
    .prepare(
      `INSERT INTO tailor_price_plans (id, tailor_id, name, currency, is_active)
       VALUES (?, ?, 'Default', 'QAR', 1)`,
    )
    .bind(planId, tailorId)
    .run();

  for (const garmentType of TAILOR_GARMENT_TYPES) {
    for (const fabricQuality of TAILOR_FABRIC_QUALITIES) {
      await db
        .prepare(
          `INSERT INTO tailor_garment_prices
           (id, plan_id, garment_type, fabric_quality, base_price, fabric_fee)
           VALUES (?, ?, ?, ?, ?, ?)`,
        )
        .bind(
          uuidv4(),
          planId,
          garmentType,
          fabricQuality,
          PLATFORM_BASE_PRICE,
          platformFabricFeeFor(fabricQuality),
        )
        .run();
    }
  }

  for (const [cityKey, fee] of Object.entries(PLATFORM_DELIVERY_FEES)) {
    await db
      .prepare(
        `INSERT INTO tailor_delivery_fees (id, plan_id, city_key, fee)
         VALUES (?, ?, ?, ?)`,
      )
      .bind(uuidv4(), planId, cityKey, fee)
      .run();
  }

  return { planId };
}
