"use client";

import { useEffect, useState } from "react";
import { adminApi } from "@/lib/admin-api";
import { AdminScopes } from "@/lib/types";
import { Badge, DataTable, ErrorBanner, PageHeader, StatusBadge } from "@/components/ui";
import { RequireRole } from "@/components/RequireRole";
import { useI18n } from "@/components/I18nProvider";

export default function AdminRoleRequestsPage() {
  const { t, td } = useI18n();
  const [rows, setRows] = useState<Record<string, unknown>[]>([]);
  const [error, setError] = useState("");

  useEffect(() => {
    adminApi.listRoleRequests("pending").then(setRows).catch((e: { message?: string }) => setError(e.message ?? t("admin.common.error")));
  }, [t]);

  return (
    <RequireRole role="admin" scope={AdminScopes.usersMgmt}>
      <PageHeader title={t("admin.roleRequests.title")} subtitle={t("admin.roleRequests.subtitle")} />
      {error && <ErrorBanner message={error} />}
      <DataTable
        columns={[
          { key: "id", label: t("admin.common.id") },
          {
            key: "requestedRole",
            label: t("admin.users.role"),
            render: (row) => <Badge>{td("roles", row.requestedRole)}</Badge>,
          },
          {
            key: "status",
            label: t("orders.status"),
            render: (row) => <StatusBadge status={row.status} />,
          },
          { key: "userId", label: t("admin.complaints.user") },
        ]}
        rows={rows.map((r) => ({
          id: r.id,
          requestedRole: r.requestedRole ?? r.requested_role,
          status: r.status,
          userId: r.userId ?? r.user_id,
        }))}
        onRowClick={async (row) => {
          const status = prompt(t("admin.roleRequests.statusPrompt"), "approved");
          if (!status) return;
          try {
            await adminApi.patchRoleRequest(String(row.id), { status });
            setRows(await adminApi.listRoleRequests("pending"));
          } catch (e) {
            setError((e as { message?: string }).message ?? t("admin.common.updateFailed"));
          }
        }}
      />
    </RequireRole>
  );
}
