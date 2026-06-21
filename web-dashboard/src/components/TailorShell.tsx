"use client";

import { DashboardShell } from "./DashboardShell";
import { useI18n } from "./I18nProvider";
import { TAILOR_NAV } from "@/lib/admin-nav";

export function TailorShell({ children }: { children: React.ReactNode }) {
  const { t } = useI18n();

  return (
    <DashboardShell
      title={t("shell.tailorTitle")}
      subtitle={t("shell.tailorSubtitle")}
      items={TAILOR_NAV}
    >
      {children}
    </DashboardShell>
  );
}
