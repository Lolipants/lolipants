"use client";

import { useAuth } from "./AuthProvider";
import { DashboardShell } from "./DashboardShell";
import { useI18n } from "./I18nProvider";
import { ADMIN_NAV } from "@/lib/admin-nav";
import { hasScope, isSuperAdmin } from "@/lib/rbac";

export function AdminShell({ children }: { children: React.ReactNode }) {
  const { user } = useAuth();
  const { t } = useI18n();
  const items = ADMIN_NAV.filter(
    (item) => !item.scope || (user && hasScope(user, item.scope)),
  );

  return (
    <DashboardShell
      title={t("shell.adminTitle")}
      subtitle={t("shell.adminSubtitle")}
      badge={user && isSuperAdmin(user) ? t("shell.superAdmin") : undefined}
      items={items}
    >
      {children}
    </DashboardShell>
  );
}
