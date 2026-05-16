/** Platform-wide default pricing (legacy checkout values) for new tailor plan seeds. */

export const PLATFORM_BASE_PRICE = 350;

export function platformFabricFeeFor(quality: string | null | undefined): number {
  const q = (quality ?? "").toLowerCase();
  if (q === "premium") return 120;
  if (q === "suit_grade") return 180;
  return 60;
}

export const PLATFORM_DELIVERY_FEES: Record<string, number> = {
  doha: 20,
  al_wakrah: 25,
  al_khor: 25,
  lusail: 22,
  default: 25,
};

export function platformDeliveryFeeFor(city: string): number {
  const key = normalizeCityKey(city);
  return PLATFORM_DELIVERY_FEES[key] ?? PLATFORM_DELIVERY_FEES.default;
}

export function normalizeCityKey(city: string): string {
  return city
    .trim()
    .toLowerCase()
    .replace(/\s+/g, "_")
    .replace(/[^a-z0-9_]/g, "");
}

/** Canonical garment types for tailor price matrix UI and seeds. */
export const TAILOR_GARMENT_TYPES = [
  "thobe",
  "abaya",
  "bisht",
  "jubbah",
  "kaftan",
  "kandura",
  "tshirt",
  "polo",
  "hoodie",
  "longsleeve",
  "trousers",
  "jumpsuit",
] as const;

export const TAILOR_FABRIC_QUALITIES = ["standard", "premium", "suit_grade"] as const;

export type TailorGarmentType = (typeof TAILOR_GARMENT_TYPES)[number];
export type TailorFabricQuality = (typeof TAILOR_FABRIC_QUALITIES)[number];
