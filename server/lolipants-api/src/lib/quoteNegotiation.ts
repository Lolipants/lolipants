/** Scale base+fabric to match negotiated total; delivery fee stays fixed. */
export function freezeNegotiatedLineItems(input: {
  listBase: number;
  listFabric: number;
  listDelivery: number;
  agreedTotal: number;
}): { base: number; fabric: number; delivery: number; total: number } {
  const delivery = input.listDelivery;
  const subtotalTarget = Math.max(0, agreedTotal - delivery);
  const listSubtotal = input.listBase + input.listFabric;
  if (listSubtotal <= 0) {
    return { base: subtotalTarget, fabric: 0, delivery, total: agreedTotal };
  }
  const ratio = subtotalTarget / listSubtotal;
  const base = Math.round(input.listBase * ratio);
  const fabric = subtotalTarget - base;
  return { base, fabric, delivery, total: base + fabric + delivery };
}

export const NEGOTIATION_FLOOR_RATIO = 0.7;
export const QUOTE_LOCK_HOURS = 24;

export function negotiationFloor(listTotal: number): number {
  return Math.ceil(listTotal * NEGOTIATION_FLOOR_RATIO);
}

export function quoteLockExpiryIso(): string {
  const d = new Date();
  d.setHours(d.getHours() + QUOTE_LOCK_HOURS);
  return d.toISOString();
}

export function negotiationExpiryIso(days = 7): string {
  const d = new Date();
  d.setDate(d.getDate() + days);
  return d.toISOString();
}

export type NegotiationRow = {
  id: string;
  user_id: string;
  tailor_id: string;
  design_id: string;
  delivery_city: string;
  delivery_lat: number;
  delivery_lng: number;
  delivery_address: string;
  delivery_phone: string;
  list_base_price: number;
  list_fabric_fee: number;
  list_delivery_fee: number;
  list_total: number;
  price_plan_id: string;
  currency: string;
  offered_total: number;
  offered_by: string;
  customer_note: string | null;
  locked_base_price: number | null;
  locked_fabric_fee: number | null;
  locked_delivery_fee: number | null;
  locked_total: number | null;
  status: string;
  tailor_counter_used: number;
  quote_lock_token: string | null;
  quote_lock_expires_at: string | null;
  expires_at: string;
  accepted_at: string | null;
  created_at: string;
  updated_at: string;
};

export function serializeNegotiation(row: NegotiationRow) {
  return {
    id: row.id,
    userId: row.user_id,
    tailorId: row.tailor_id,
    designId: row.design_id,
    deliveryCity: row.delivery_city,
    deliveryLat: row.delivery_lat,
    deliveryLng: row.delivery_lng,
    deliveryAddress: row.delivery_address,
    deliveryPhone: row.delivery_phone,
    listBasePrice: row.list_base_price,
    listFabricFee: row.list_fabric_fee,
    listDeliveryFee: row.list_delivery_fee,
    listTotal: row.list_total,
    pricePlanId: row.price_plan_id,
    currency: row.currency,
    offeredTotal: row.offered_total,
    offeredBy: row.offered_by,
    customerNote: row.customer_note,
    lockedBasePrice: row.locked_base_price,
    lockedFabricFee: row.locked_fabric_fee,
    lockedDeliveryFee: row.locked_delivery_fee,
    lockedTotal: row.locked_total,
    status: row.status,
    tailorCounterUsed: Boolean(row.tailor_counter_used),
    quoteLockToken: row.quote_lock_token,
    quoteLockExpiresAt: row.quote_lock_expires_at,
    expiresAt: row.expires_at,
    acceptedAt: row.accepted_at,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}
