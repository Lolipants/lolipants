import { AdminScopes, type DashboardUser } from "./types";

export function hasScope(user: DashboardUser, scope: string): boolean {
  if (user.role !== "admin") return false;
  if (user.adminScopes.length === 0) return true;
  if (user.adminScopes.includes(AdminScopes.superAdmin)) return true;
  return user.adminScopes.includes(scope);
}

export function isSuperAdmin(user: DashboardUser): boolean {
  return user.role === "admin" && user.adminScopes.includes(AdminScopes.superAdmin);
}

export function defaultAdminPath(user: DashboardUser): string {
  if (user.role !== "admin") return "/unauthorized";
  if (isSuperAdmin(user) || user.adminScopes.length === 0) return "/admin/stats";
  const routes: Array<[string, string]> = [
    [AdminScopes.usersMgmt, "/admin/users"],
    [AdminScopes.ordersOversight, "/admin/orders"],
    [AdminScopes.payouts, "/admin/payouts"],
    [AdminScopes.moderation, "/admin/moderation"],
    [AdminScopes.news, "/admin/news"],
    [AdminScopes.cms, "/admin/cms"],
    [AdminScopes.complaints, "/admin/complaints"],
  ];
  for (const [scope, path] of routes) {
    if (hasScope(user, scope)) return path;
  }
  return "/admin/stats";
}

export function homeForRole(user: DashboardUser): string {
  switch (user.role) {
    case "admin":
      return defaultAdminPath(user);
    case "tailor":
      return "/tailor/incoming";
    default:
      return "/unauthorized";
  }
}

export function canAccessDashboard(user: DashboardUser): boolean {
  return user.role === "admin" || user.role === "tailor";
}
