import { apiFetch } from "./api";
import type { OrderRow } from "./types";

export const TAILOR_QUEUE = {
  incoming: ["placed", "confirmed"],
  active: [
    "cutting",
    "stitching",
    "embroidery",
    "quality_check",
    "ready_to_ship",
    "out_for_delivery",
  ],
  completed: ["delivered", "cancelled"],
} as const;

export const TAILOR_TRANSITIONS: Record<string, string[]> = {
  placed: ["confirmed", "cancelled"],
  confirmed: ["cutting", "cancelled"],
  cutting: ["stitching", "cancelled"],
  stitching: ["embroidery", "quality_check", "cancelled"],
  embroidery: ["quality_check", "cancelled"],
  quality_check: ["ready_to_ship", "cancelled"],
  ready_to_ship: ["cancelled"],
};

export const tailorApi = {
  getQueue: (statuses: string[]) => {
    const q = `?status=${encodeURIComponent(statuses.join(","))}`;
    return apiFetch<OrderRow[]>(`/orders/queue${q}`);
  },
  getOrder: (id: string) => apiFetch<OrderRow>(`/orders/tailor/${id}`),
  claim: (id: string) =>
    apiFetch<void>(`/orders/${id}/claim`, { method: "POST", body: "{}" }),
  advanceStatus: (id: string, status: string, note?: string) =>
    apiFetch<OrderRow>(`/orders/${id}/status`, {
      method: "PATCH",
      body: JSON.stringify({ status, ...(note ? { note } : {}) }),
    }),
  listQuoteNegotiations: async () => {
    const body = await apiFetch<{
      negotiations?: Record<string, unknown>[];
    }>("/orders/quote-negotiations/tailor");
    return body.negotiations ?? [];
  },
  getPricing: () => apiFetch<Record<string, unknown>>("/tailor/pricing"),
  updatePricing: (body: Record<string, unknown>) =>
    apiFetch<Record<string, unknown>>("/tailor/pricing", {
      method: "PUT",
      body: JSON.stringify(body),
    }),
  updatePricingProfile: (body: Record<string, unknown>) =>
    apiFetch<Record<string, unknown>>("/tailor/pricing/profile", {
      method: "PUT",
      body: JSON.stringify(body),
    }),
  updatePricingPlan: (body: Record<string, unknown>) =>
    apiFetch<Record<string, unknown>>("/tailor/pricing/plan", {
      method: "PUT",
      body: JSON.stringify(body),
    }),
  updateGarmentPrices: (prices: Record<string, unknown>[]) =>
    apiFetch<Record<string, unknown>>("/tailor/pricing/garment-prices", {
      method: "PUT",
      body: JSON.stringify({ prices }),
    }),
  updateDeliveryFees: (fees: Record<string, unknown>[]) =>
    apiFetch<Record<string, unknown>>("/tailor/pricing/delivery-fees", {
      method: "PUT",
      body: JSON.stringify({ fees }),
    }),
  getWeddingPricing: () => apiFetch<Record<string, unknown>[]>("/tailor/wedding-pricing"),
};
