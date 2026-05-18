import { Hono } from "hono";
import { v4 as uuidv4 } from "uuid";
import { apiError } from "../lib/http";
import type { WeddingDressCategory } from "../lib/weddingPricing";
import { requireAuth, requireRole } from "../middleware/auth";
import type { AppVariables, Env } from "../types";

const WEDDING_CATEGORIES: WeddingDressCategory[] = [
  "wedding_dress",
  "bridesmaid",
];

const DEFAULT_WEDDING_PRICES: Record<
  WeddingDressCategory,
  { rentPricePerDay: number; salePrice: number; insuranceDeposit: number }
> = {
  wedding_dress: { rentPricePerDay: 120, salePrice: 4500, insuranceDeposit: 800 },
  bridesmaid: { rentPricePerDay: 45, salePrice: 650, insuranceDeposit: 200 },
};

function isCategory(value: string): value is WeddingDressCategory {
  return WEDDING_CATEGORIES.includes(value as WeddingDressCategory);
}

export const tailorWeddingPricingRoutes = new Hono<{
  Bindings: Env;
  Variables: AppVariables;
}>();

tailorWeddingPricingRoutes.use("*", requireAuth);
tailorWeddingPricingRoutes.use("*", requireRole("tailor"));

tailorWeddingPricingRoutes.get("/", async (c) => {
  const tailorId = c.get("userId") as string;
  const { results } = await c.env.DB.prepare(
    `SELECT id, tailor_id, category, rent_price_per_day, sale_price,
            insurance_deposit, created_at, updated_at
     FROM tailor_wedding_prices
     WHERE tailor_id = ?
     ORDER BY category`,
  )
    .bind(tailorId)
    .all();

  const byCategory = new Map(
    (results ?? []).map((row) => [
      String((row as Record<string, unknown>).category),
      row,
    ]),
  );

  const prices = WEDDING_CATEGORIES.map((category) => {
    const existing = byCategory.get(category) as Record<string, unknown> | undefined;
    const defaults = DEFAULT_WEDDING_PRICES[category];
    return (
      existing ?? {
        category,
        rent_price_per_day: defaults.rentPricePerDay,
        sale_price: defaults.salePrice,
        insurance_deposit: defaults.insuranceDeposit,
        tailor_id: tailorId,
      }
    );
  });

  return c.json({
    categories: WEDDING_CATEGORIES,
    prices,
  });
});

tailorWeddingPricingRoutes.patch("/", async (c) => {
  const tailorId = c.get("userId") as string;
  const body = (await c.req.json().catch(() => ({}))) as {
    prices?: Array<{
      category?: string;
      rentPricePerDay?: number;
      salePrice?: number;
      insuranceDeposit?: number;
    }>;
  };
  const items = body.prices ?? [];
  if (items.length === 0) {
    return apiError(c, 400, "PRICES_REQUIRED", "prices array is required");
  }

  for (const item of items) {
    const category = String(item.category ?? "").trim();
    if (!isCategory(category)) {
      return apiError(c, 400, "INVALID_CATEGORY", `Invalid category: ${category}`);
    }
    const rent = Number(item.rentPricePerDay);
    const sale = Number(item.salePrice);
    const deposit = Number(item.insuranceDeposit);
    if (!Number.isFinite(rent) || rent < 0) {
      return apiError(c, 400, "INVALID_RENT", "rentPricePerDay must be >= 0");
    }
    if (!Number.isFinite(sale) || sale < 0) {
      return apiError(c, 400, "INVALID_SALE", "salePrice must be >= 0");
    }
    if (!Number.isFinite(deposit) || deposit < 0) {
      return apiError(
        c,
        400,
        "INVALID_DEPOSIT",
        "insuranceDeposit must be >= 0",
      );
    }

    const existing = await c.env.DB.prepare(
      `SELECT id FROM tailor_wedding_prices WHERE tailor_id = ? AND category = ?`,
    )
      .bind(tailorId, category)
      .first<{ id: string }>();

    if (existing) {
      await c.env.DB.prepare(
        `UPDATE tailor_wedding_prices
         SET rent_price_per_day = ?, sale_price = ?, insurance_deposit = ?,
             updated_at = datetime('now')
         WHERE id = ?`,
      )
        .bind(rent, sale, deposit, existing.id)
        .run();
    } else {
      await c.env.DB.prepare(
        `INSERT INTO tailor_wedding_prices
         (id, tailor_id, category, rent_price_per_day, sale_price, insurance_deposit)
         VALUES (?, ?, ?, ?, ?, ?)`,
      )
        .bind(uuidv4(), tailorId, category, rent, sale, deposit)
        .run();
    }
  }

  const { results } = await c.env.DB.prepare(
    `SELECT id, tailor_id, category, rent_price_per_day, sale_price,
            insurance_deposit, created_at, updated_at
     FROM tailor_wedding_prices
     WHERE tailor_id = ?
     ORDER BY category`,
  )
    .bind(tailorId)
    .all();

  return c.json({ prices: results ?? [] });
});
