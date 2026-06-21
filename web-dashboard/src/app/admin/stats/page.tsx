"use client";

import { useEffect, useState } from "react";
import { adminApi } from "@/lib/admin-api";
import {
  EmptyState,
  ErrorBanner,
  LoadingState,
  MetricCard,
  PageHeader,
  Panel,
  SectionHeader,
  StatusBadge,
} from "@/components/ui";
import { useI18n } from "@/components/I18nProvider";

function rowsToMap(raw: unknown, keyField: string): Record<string, string> {
  if (Array.isArray(raw)) {
    const out: Record<string, string> = {};
    for (const row of raw) {
      if (row && typeof row === "object") {
        const r = row as Record<string, unknown>;
        const k = String(r[keyField] ?? "");
        out[k] = String(r.count ?? "0");
      }
    }
    return out;
  }
  if (raw && typeof raw === "object") {
    const out: Record<string, string> = {};
    for (const [k, v] of Object.entries(raw as Record<string, unknown>)) {
      out[k] = String(v);
    }
    return out;
  }
  return {};
}

export default function AdminStatsPage() {
  const { t } = useI18n();
  const [data, setData] = useState<Record<string, unknown> | null>(null);
  const [error, setError] = useState("");

  useEffect(() => {
    adminApi
      .stats()
      .then(setData)
      .catch((e: { message?: string }) => setError(e.message ?? t("admin.stats.loadError")));
  }, [t]);

  return (
    <div>
      <PageHeader title={t("admin.stats.title")} subtitle={t("admin.stats.subtitle")} />
      {error && <ErrorBanner message={error} />}
      {!data && !error && <LoadingState />}
      {data && (
        <div className="space-y-6">
          <div className="grid gap-4 md:grid-cols-4">
            <MetricCard
              label={t("admin.stats.openComplaints")}
              value={String(data.openComplaints ?? "0")}
              detail={t("admin.stats.needsAttention")}
            />
            <MetricCard
              label={t("admin.stats.userRoles")}
              value={Object.keys(rowsToMap(data.usersByRole, "role")).length}
              detail={t("admin.stats.roleBuckets")}
            />
            <MetricCard
              label={t("admin.stats.orderStatuses")}
              value={Object.keys(rowsToMap(data.ordersByStatus, "status")).length}
              detail={t("admin.stats.operationalStages")}
            />
            <MetricCard
              label={t("admin.stats.commissionStates")}
              value={Object.keys(rowsToMap(data.commissionsByStatus, "status")).length}
              detail={t("admin.stats.payoutHealth")}
            />
          </div>
          <div className="grid gap-4 lg:grid-cols-3">
            <StatCard title={t("admin.stats.usersByRole")} values={rowsToMap(data.usersByRole, "role")} />
            <StatCard title={t("admin.stats.ordersByStatus")} values={rowsToMap(data.ordersByStatus, "status")} />
            <StatCard
              title={t("admin.stats.commissionsByStatus")}
              values={rowsToMap(data.commissionsByStatus, "status")}
            />
          </div>
        </div>
      )}
    </div>
  );
}

function StatCard({ title, values }: { title: string; values: Record<string, string> }) {
  const { t } = useI18n();
  return (
    <Panel>
      <SectionHeader title={title} />
      <dl className="space-y-3">
        {Object.entries(values).map(([k, v]) => (
          <div key={k} className="flex items-center justify-between gap-3 text-sm">
            <dt>
              <StatusBadge status={k || "—"} />
            </dt>
            <dd className="text-lg font-semibold text-zinc-100">{v}</dd>
          </div>
        ))}
        {Object.keys(values).length === 0 && (
          <EmptyState title={t("admin.stats.noData")} description={t("admin.stats.noDataDescription")} />
        )}
      </dl>
    </Panel>
  );
}
