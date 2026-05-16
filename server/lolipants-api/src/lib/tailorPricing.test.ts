import { describe, expect, it } from "vitest";
import {
  computeTailorQuote,
  resolveDeliveryFee,
  resolveGarmentPriceRow,
  type ActiveTailorPlan,
} from "./tailorPricing";
import { haversineKm } from "./tailorAssignment";

describe("resolveGarmentPriceRow", () => {
  const rows = [
    { garment_type: "thobe", fabric_quality: "standard", base_price: 300, fabric_fee: 50 },
    { garment_type: "thobe", fabric_quality: "*", base_price: 280, fabric_fee: 40 },
    { garment_type: "*", fabric_quality: "*", base_price: 200, fabric_fee: 30 },
  ];

  it("prefers exact garment and fabric match", () => {
    const hit = resolveGarmentPriceRow(rows, "thobe", "standard");
    expect(hit?.base_price).toBe(300);
  });

  it("falls back to wildcard fabric", () => {
    const hit = resolveGarmentPriceRow(rows, "thobe", "premium");
    expect(hit?.base_price).toBe(280);
  });

  it("falls back to global wildcard", () => {
    const hit = resolveGarmentPriceRow(rows, "abaya", "premium");
    expect(hit?.base_price).toBe(200);
  });
});

describe("computeTailorQuote", () => {
  const plan: ActiveTailorPlan = {
    planId: "p1",
    tailorId: "t1",
    currency: "QAR",
    garmentPrices: [
      { garment_type: "thobe", fabric_quality: "standard", base_price: 350, fabric_fee: 60 },
    ],
    deliveryFees: [{ city_key: "doha", fee: 20 }],
  };

  it("sums base fabric and delivery", () => {
    const quote = computeTailorQuote({
      plan,
      garmentType: "thobe",
      fabricQuality: "standard",
      city: "Doha",
    });
    expect(quote?.total).toBe(430);
    expect(quote?.deliveryFee).toBe(20);
  });
});

describe("resolveDeliveryFee", () => {
  it("uses default city key when city unknown", () => {
    const fee = resolveDeliveryFee(
      [
        { city_key: "doha", fee: 15 },
        { city_key: "default", fee: 25 },
      ],
      "Al Rayyan",
    );
    expect(fee).toBe(25);
  });
});

describe("haversineKm", () => {
  it("returns zero for identical points", () => {
    expect(haversineKm(25.28, 51.53, 25.28, 51.53)).toBe(0);
  });
});
