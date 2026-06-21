"use client";

import { useCallback, useEffect, useState } from "react";
import { adminApi } from "@/lib/admin-api";
import { AdminScopes } from "@/lib/types";
import {
  Button,
  DataTable,
  Drawer,
  ErrorBanner,
  Input,
  LoadingState,
  PageHeader,
  Panel,
  StatusBadge,
} from "@/components/ui";
import { RequireRole } from "@/components/RequireRole";
import { useI18n } from "@/components/I18nProvider";

const QUICK_STATUSES = ["", "placed", "confirmed", "cutting", "ready_to_ship", "delivered", "cancelled"];

export default function AdminOrdersPage() {
  const { t, td } = useI18n();
  const [rows, setRows] = useState<Record<string, unknown>[]>([]);
  const [error, setError] = useState("");
  const [statusFilter, setStatusFilter] = useState("");
  const [selected, setSelected] = useState<Record<string, unknown> | null>(null);
  const [newStatus, setNewStatus] = useState("");

  const load = useCallback(() => {
    adminApi
      .listOrders(statusFilter || undefined)
      .then(setRows)
      .catch((e: { message?: string }) => setError(e.message ?? t("admin.orders.loadError")));
  }, [statusFilter, t]);

  useEffect(() => {
    load();
  }, [load]);

  async function save() {
    if (!selected?.id || !newStatus) return;
    try {
      await adminApi.patchOrder(String(selected.id), { status: newStatus });
      setSelected(null);
      load();
    } catch (e) {
      setError((e as { message?: string }).message ?? t("admin.orders.updateFailed"));
    }
  }

  const tableRows = rows.map((r) => ({
    id: r.id,
    status: r.status,
    userId: r.userId ?? r.user_id,
    tailorId: r.tailorId ?? r.tailor_id,
    total: r.totalAmount ?? r.total_amount,
  }));

  return (
    <RequireRole role="admin" scope={AdminScopes.ordersOversight}>
      <PageHeader title={t("admin.orders.title")} subtitle={t("admin.orders.subtitle")} />
      <Panel className="mb-5">
        <div className="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
          <div className="flex flex-wrap gap-2">
            {QUICK_STATUSES.map((status) => (
              <Button
                key={status || "all"}
                variant={statusFilter === status ? "primary" : "secondary"}
                onClick={() => setStatusFilter(status)}
              >
                {status ? td("status", status) : t("common.all")}
              </Button>
            ))}
          </div>
          <Input
            placeholder={t("admin.orders.customStatus")}
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="lg:max-w-xs"
          />
        </div>
      </Panel>
      {error && <ErrorBanner message={error} />}
      {rows.length === 0 && !error ? <LoadingState /> : (
        <DataTable
          emptyTitle={t("admin.orders.emptyTitle")}
          emptyDescription={t("admin.orders.emptyDescription")}
          columns={[
            { key: "id", label: t("admin.common.id") },
            {
              key: "status",
              label: t("orders.status"),
              render: (row) => <StatusBadge status={row.status} />,
            },
            { key: "userId", label: t("orders.customer") },
            { key: "tailorId", label: t("roles.tailor") },
            { key: "total", label: t("orders.total") },
          ]}
          rows={tableRows}
          onRowClick={(row) => {
            setSelected(row);
            setNewStatus(String(row.status ?? ""));
          }}
        />
      )}
      {selected && (
        <Drawer
          title={t("orders.orderWithId", `Order ${String(selected.id)}`).replace("{id}", String(selected.id))}
          subtitle={t("admin.orders.drawerSubtitle")}
          onClose={() => setSelected(null)}
          footer={
            <div className="flex gap-2">
              <Button type="button" onClick={save}>
                {t("admin.orders.updateStatus")}
              </Button>
              <Button type="button" variant="secondary" onClick={() => setSelected(null)}>
                {t("common.close")}
              </Button>
            </div>
          }
        >
          <div className="space-y-5">
            <div className="rounded-2xl border border-white/10 bg-white/[0.03] p-4">
              <p className="text-sm text-zinc-500">{t("admin.orders.currentStatus")}</p>
              <div className="mt-2"><StatusBadge status={selected.status} /></div>
            </div>
            <label className="block text-sm text-zinc-300">
              {t("orders.status")}
              <Input
                value={newStatus}
                onChange={(e) => setNewStatus(e.target.value)}
                className="mt-2"
              />
            </label>
          </div>
        </Drawer>
      )}
    </RequireRole>
  );
}
