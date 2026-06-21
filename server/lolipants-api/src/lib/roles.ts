/**
 * Canonical role + admin-scope constants shared between middleware, admin
 * routes, and tests. Keeping this in one place avoids drift between the
 * requireAdmin guard and the admin routes that declare the scope they need.
 */

/** Role values accepted by the app. */
export const ALLOWED_ROLES: ReadonlySet<string> = new Set([
  "user",
  "tailor",
  "delivery",
  "admin",
]);

/**
 * Scope sentinels. `*` grants every scope (super admin). Otherwise each
 * scope gates a specific admin sub-area.
 */
export const AdminScopes = {
  superAdmin: "*",
  usersMgmt: "users_mgmt",
  ordersOversight: "orders_oversight",
  payouts: "payouts",
  moderation: "moderation",
  cms: "cms",
  complaints: "complaints",
  tailorMgmt: "tailor_mgmt",
  deliveryMgmt: "delivery_mgmt",
  news: "news",
} as const;

export type AdminScope = typeof AdminScopes[keyof typeof AdminScopes];
