"use client";

import { useEffect, useState } from "react";
import { adminApi } from "@/lib/admin-api";
import { AdminScopes } from "@/lib/types";
import { DataTable, ErrorBanner, PageHeader, StatusBadge } from "@/components/ui";
import { RequireRole } from "@/components/RequireRole";
import { useI18n } from "@/components/I18nProvider";

export default function AdminComplaintsPage() {
  const { t } = useI18n();
  const [rows, setRows] = useState<Record<string, unknown>[]>([]);
  const [error, setError] = useState("");

  useEffect(() => {
    adminApi.listComplaints().then(setRows).catch((e: { message?: string }) => setError(e.message ?? t("admin.common.error")));
  }, [t]);

  return (
    <RequireRole role="admin" scope={AdminScopes.complaints}>
      <PageHeader title={t("admin.complaints.title")} subtitle={t("admin.complaints.subtitle")} />
      {error && <ErrorBanner message={error} />}
      <DataTable
        columns={[
          { key: "id", label: t("admin.common.id") },
          {
            key: "status",
            label: t("orders.status"),
            render: (row) => <StatusBadge status={row.status} />,
          },
          { key: "category", label: t("admin.complaints.category") },
          { key: "userId", label: t("admin.complaints.user") },
        ]}
        rows={rows.map((r) => ({
          id: r.id,
          status: r.status,
          category: r.category,
          userId: r.userId ?? r.user_id,
        }))}
        onRowClick={async (row) => {
          const status = prompt(t("admin.complaints.statusPrompt"), String(row.status));
          if (!status) return;
          try {
            await adminApi.patchComplaint(String(row.id), { status });
            setRows(await adminApi.listComplaints());
          } catch (e) {
            setError((e as { message?: string }).message ?? t("admin.common.updateFailed"));
          }
        }}
      />
    </RequireRole>
  );
}
