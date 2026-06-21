"use client";

import { useEffect, useState } from "react";
import { adminApi } from "@/lib/admin-api";
import { AdminScopes } from "@/lib/types";
import { DataTable, ErrorBanner, PageHeader, StatusBadge } from "@/components/ui";
import { RequireRole } from "@/components/RequireRole";
import { useI18n } from "@/components/I18nProvider";

export default function AdminPayoutsPage() {
  const { t } = useI18n();
  const [rows, setRows] = useState<Record<string, unknown>[]>([]);
  const [error, setError] = useState("");

  useEffect(() => {
    adminApi.listPayouts().then(setRows).catch((e: { message?: string }) => setError(e.message ?? t("admin.common.error")));
  }, [t]);

  return (
    <RequireRole role="admin" scope={AdminScopes.payouts}>
      <PageHeader title={t("admin.payouts.title")} subtitle={t("admin.payouts.subtitle")} />
      {error && <ErrorBanner message={error} />}
      <DataTable
        columns={[
          { key: "id", label: t("admin.common.id") },
          {
            key: "status",
            label: t("orders.status"),
            render: (row) => <StatusBadge status={row.status} />,
          },
          { key: "amount", label: t("admin.payouts.amount") },
          { key: "designerId", label: t("admin.payouts.designer") },
        ]}
        rows={rows.map((r) => ({
          id: r.id,
          status: r.status,
          amount: r.amount,
          designerId: r.designerId ?? r.designer_id,
        }))}
        onRowClick={async (row) => {
          const status = prompt(t("admin.payouts.statusPrompt"), String(row.status));
          if (!status) return;
          try {
            await adminApi.patchPayout(String(row.id), { status });
            const fresh = await adminApi.listPayouts();
            setRows(fresh);
          } catch (e) {
            setError((e as { message?: string }).message ?? t("admin.common.updateFailed"));
          }
        }}
      />
    </RequireRole>
  );
}
