import {
  seedTailorPricingTables,
  TEST_PLAN_ID,
  TEST_TAILOR_ID,
  type TailorMockTables,
} from "./tailorOrderFixtures";

type Row = Record<string, unknown>;

export function ensureTailorTables(db: TailorMockTables): Required<TailorMockTables> {
  seedTailorPricingTables(db);
  return {
    users: db.users!,
    tailorProfiles: db.tailorProfiles!,
    tailorPlans: db.tailorPlans!,
    tailorGarmentPrices: db.tailorGarmentPrices!,
    tailorDeliveryFees: db.tailorDeliveryFees!,
  };
}

export function tailorMockSelect(
  db: TailorMockTables,
  sql: string,
  binds: unknown[],
): Row[] | null {
  const tables = ensureTailorTables(db);
  if (sql.includes("FROM tailor_profiles tp") && sql.includes("JOIN users u")) {
    return [...tables.tailorProfiles.values()]
      .map((tp) => {
        const user = tables.users.get(String(tp.user_id));
        if (!user || user.role !== "tailor") return null;
        return { ...tp, name: user.name };
      })
      .filter((r): r is Row => r != null);
  }
  if (sql.includes("FROM tailor_garment_prices WHERE plan_id = ?")) {
    const planId = String(binds[0] ?? "");
    return tables.tailorGarmentPrices.filter((r) => r.plan_id === planId);
  }
  if (sql.includes("FROM tailor_delivery_fees WHERE plan_id = ?")) {
    const planId = String(binds[0] ?? "");
    return tables.tailorDeliveryFees.filter((r) => r.plan_id === planId);
  }
  if (sql.includes("FROM orders WHERE tailor_id = ?")) {
    return null; // handled by each mock's orders map
  }
  return null;
}

export function tailorMockFirst(
  db: TailorMockTables,
  sql: string,
  binds: unknown[],
): Row | null | undefined {
  const tables = ensureTailorTables(db);

  if (sql.includes("FROM tailor_price_plans") && sql.includes("tailor_id = ?")) {
    const tailorId = String(binds[0] ?? "");
    for (const plan of tables.tailorPlans.values()) {
      if (plan.tailor_id === tailorId && (plan.is_active ?? 1) === 1) {
        return {
          id: plan.id,
          tailor_id: plan.tailor_id,
          currency: plan.currency ?? "QAR",
        };
      }
    }
    return null;
  }

  if (sql.includes("SELECT id FROM orders WHERE design_id = ?")) {
    return undefined;
  }

  return undefined;
}

/** Parses extended INSERT INTO orders bind positions. */
export function parseOrderInsertBinds(binds: unknown[]): Row {
  return {
    id: binds[0],
    user_id: binds[1],
    design_id: binds[2],
    designer_id: binds[3],
    tailor_id: binds[4],
    status: "placed",
    delivery_address: binds[5],
    delivery_city: binds[6],
    base_price: binds[13],
    fabric_fee: binds[14],
    delivery_fee: binds[15],
    total_price: binds[16],
  };
}
