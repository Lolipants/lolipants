import { AdminScopes } from "./types";

export type AdminNavItem = {
  label: string;
  labelKey: string;
  href: string;
  scope?: string;
  group: "overview" | "people" | "operations" | "platform";
};

export const ADMIN_NAV: AdminNavItem[] = [
  { label: "Overview", labelKey: "nav.admin.overview", href: "/admin/stats", group: "overview" },
  { label: "Users", labelKey: "nav.admin.users", href: "/admin/users", scope: AdminScopes.usersMgmt, group: "people" },
  { label: "Role requests", labelKey: "nav.admin.roleRequests", href: "/admin/role-requests", scope: AdminScopes.usersMgmt, group: "people" },
  { label: "Orders", labelKey: "nav.admin.orders", href: "/admin/orders", scope: AdminScopes.ordersOversight, group: "operations" },
  { label: "Payouts", labelKey: "nav.admin.payouts", href: "/admin/payouts", scope: AdminScopes.payouts, group: "operations" },
  { label: "Complaints", labelKey: "nav.admin.complaints", href: "/admin/complaints", scope: AdminScopes.complaints, group: "operations" },
  { label: "Moderation", labelKey: "nav.admin.moderation", href: "/admin/moderation", scope: AdminScopes.moderation, group: "platform" },
  { label: "News", labelKey: "nav.admin.news", href: "/admin/news", scope: AdminScopes.news, group: "platform" },
  { label: "CMS", labelKey: "nav.admin.cms", href: "/admin/cms", scope: AdminScopes.cms, group: "platform" },
];

export const TAILOR_NAV = [
  { label: "Incoming", labelKey: "nav.tailor.incoming", href: "/tailor/incoming" },
  { label: "Price requests", labelKey: "nav.tailor.priceRequests", href: "/tailor/price-requests" },
  { label: "Active", labelKey: "nav.tailor.active", href: "/tailor/active" },
  { label: "Completed", labelKey: "nav.tailor.completed", href: "/tailor/completed" },
  { label: "Pricing", labelKey: "nav.tailor.pricing", href: "/tailor/pricing" },
];
