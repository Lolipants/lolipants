import { describe, expect, it } from "vitest";
import { pickTailorForDelivery, quoteForTailorId } from "./tailorAssignment";
import {
  seedTailorPricingTables,
  TEST_TAILOR_ID,
  type TailorMockTables,
} from "../tests/tailorOrderFixtures";
import { createTailorMockDb } from "../tests/tailorMockSql";

describe("pickTailorForDelivery", () => {
  function dbWithTwoTailors(nearAccepting: boolean, farAccepting: boolean) {
    const mock: TailorMockTables = {
      users: new Map(),
      tailorProfiles: new Map(),
      tailorPlans: new Map(),
      tailorGarmentPrices: [],
      tailorDeliveryFees: [],
    };

    const users = mock.users!;
    const profiles = mock.tailorProfiles!;
    const plans = mock.tailorPlans!;

    users.set("tailor-near", { id: "tailor-near", role: "tailor", name: "Near" });
    users.set("tailor-far", { id: "tailor-far", role: "tailor", name: "Far" });

    profiles.set("tailor-near", {
      user_id: "tailor-near",
      shop_name: "Near Shop",
      lat: 25.2854,
      lng: 51.531,
      service_radius_km: 5,
      is_accepting_orders: nearAccepting ? 1 : 0,
      created_at: "2026-01-01",
    });
    profiles.set("tailor-far", {
      user_id: "tailor-far",
      shop_name: "Far Shop",
      lat: -33.8688,
      lng: 151.2093,
      service_radius_km: 5,
      is_accepting_orders: farAccepting ? 1 : 0,
      created_at: "2026-01-02",
    });

    plans.set("plan-near", {
      id: "plan-near",
      tailor_id: "tailor-near",
      currency: "QAR",
      is_active: 1,
    });
    plans.set("plan-far", {
      id: "plan-far",
      tailor_id: "tailor-far",
      currency: "QAR",
      is_active: 1,
    });

    const garment = mock.tailorGarmentPrices!;
    for (const planId of ["plan-near", "plan-far"]) {
      garment.push(
        {
          garment_type: "thobe",
          fabric_quality: "standard",
          base_price: 350,
          fabric_fee: 60,
          plan_id: planId,
        },
        {
          garment_type: "*",
          fabric_quality: "*",
          base_price: 350,
          fabric_fee: 60,
          plan_id: planId,
        },
      );
    }

    const fees = mock.tailorDeliveryFees!;
    for (const planId of ["plan-near", "plan-far"]) {
      fees.push(
        { city_key: "doha", fee: 20, plan_id: planId },
        { city_key: "default", fee: 25, plan_id: planId },
      );
    }

    return createTailorMockDb(mock);
  }

  it("prefers a tailor within service radius", async () => {
    const db = dbWithTwoTailors(true, true);
    const picked = await pickTailorForDelivery({
      db,
      deliveryLat: 25.29,
      deliveryLng: 51.53,
      city: "Doha",
      design: { garment_type: "thobe", fabric_quality: "standard" },
    });
    expect(picked?.assignmentMethod).toBe("proximity");
    expect(picked?.candidate.tailorId).toBe("tailor-near");
  });

  it("falls back to the nearest available tailor when none are in radius", async () => {
    const db = dbWithTwoTailors(true, true);
    const picked = await pickTailorForDelivery({
      db,
      // Delivery far from both Doha workshops (no tailor within 5 km radius).
      deliveryLat: 51.5074,
      deliveryLng: -0.1278,
      city: "Doha",
      design: { garment_type: "thobe", fabric_quality: "standard" },
    });
    expect(picked?.assignmentMethod).toBe("fallback");
    expect(picked?.candidate.tailorId).toBe("tailor-near");
  });

  it("uses the default seeded tailor when delivery is at the workshop", async () => {
    const mock: TailorMockTables = {};
    seedTailorPricingTables(mock);
    const db = createTailorMockDb(mock);
    const picked = await pickTailorForDelivery({
      db,
      deliveryLat: 25.29,
      deliveryLng: 51.53,
      city: "Doha",
      design: { garment_type: "thobe", fabric_quality: "premium" },
    });
    expect(picked?.candidate.tailorId).toBe(TEST_TAILOR_ID);
    expect(picked?.assignmentMethod).toBe("proximity");
  });
});

describe("quoteForTailorId", () => {
  function dbWithTwoTailors(nearAccepting: boolean, farAccepting: boolean) {
    const mock: TailorMockTables = {
      users: new Map(),
      tailorProfiles: new Map(),
      tailorPlans: new Map(),
      tailorGarmentPrices: [],
      tailorDeliveryFees: [],
    };
    const users = mock.users!;
    const profiles = mock.tailorProfiles!;
    const plans = mock.tailorPlans!;
    users.set("tailor-near", { id: "tailor-near", role: "tailor", name: "Near" });
    users.set("tailor-far", { id: "tailor-far", role: "tailor", name: "Far" });
    profiles.set("tailor-near", {
      user_id: "tailor-near",
      shop_name: "Near Shop",
      lat: 25.2854,
      lng: 51.531,
      service_radius_km: 5,
      is_accepting_orders: nearAccepting ? 1 : 0,
      created_at: "2026-01-01",
    });
    profiles.set("tailor-far", {
      user_id: "tailor-far",
      shop_name: "Far Shop",
      lat: -33.8688,
      lng: 151.2093,
      service_radius_km: 5,
      is_accepting_orders: farAccepting ? 1 : 0,
      created_at: "2026-01-02",
    });
    plans.set("plan-near", {
      id: "plan-near",
      tailor_id: "tailor-near",
      currency: "QAR",
      is_active: 1,
    });
    plans.set("plan-far", {
      id: "plan-far",
      tailor_id: "tailor-far",
      currency: "QAR",
      is_active: 1,
    });
    for (const planId of ["plan-near", "plan-far"]) {
      mock.tailorGarmentPrices!.push(
        {
          garment_type: "thobe",
          fabric_quality: "standard",
          base_price: 350,
          fabric_fee: 60,
          plan_id: planId,
        },
        {
          garment_type: "*",
          fabric_quality: "*",
          base_price: 350,
          fabric_fee: 60,
          plan_id: planId,
        },
      );
      mock.tailorDeliveryFees!.push(
        { city_key: "doha", fee: 20, plan_id: planId },
        { city_key: "default", fee: 25, plan_id: planId },
      );
    }
    return createTailorMockDb(mock);
  }

  it("returns quote for a specific tailor from compare list", async () => {
    const db = dbWithTwoTailors(true, true);
    const quote = await quoteForTailorId({
      db,
      tailorId: "tailor-near",
      deliveryLat: 25.29,
      deliveryLng: 51.53,
      city: "Doha",
      design: { garment_type: "thobe", fabric_quality: "standard" },
    });
    expect(quote?.tailorId).toBe("tailor-near");
    expect(quote?.total).toBeGreaterThan(0);
  });
});
