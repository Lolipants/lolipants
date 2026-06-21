"use client";

import { useEffect, useState } from "react";
import { tailorApi } from "@/lib/tailor-api";
import {
  DataTable,
  EmptyState,
  ErrorBanner,
  LoadingState,
  PageHeader,
  StatusBadge,
} from "@/components/ui";
import { useI18n } from "@/components/I18nProvider";

export default function TailorPriceRequestsPage() {
  const { t, td } = useI18n();
  const [rows, setRows] = useState<Record<string, unknown>[]>([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    tailorApi
      .listQuoteNegotiations()
      .then(setRows)
      .catch((e: { message?: string }) => setError(e.message ?? t("tailor.priceRequests.loadError")))
      .finally(() => setLoading(false));
  }, [t]);

  return (
    <div>
      <PageHeader title={t("tailor.priceRequests.title")} subtitle={t("tailor.priceRequests.subtitle")} />
      {error && <ErrorBanner message={error} />}
      {loading ? (
        <LoadingState label={t("tailor.priceRequests.loading")} />
      ) : rows.length === 0 ? (
        <EmptyState
          title={t("tailor.priceRequests.emptyTitle")}
          description={t("tailor.priceRequests.emptyDescription")}
        />
      ) : (
        <DataTable
          columns={[
            { key: "id", label: t("admin.common.id") },
            {
              key: "status",
              label: t("orders.status"),
              render: (row) => <StatusBadge status={row.status} />,
            },
            {
              key: "garmentType",
              label: t("orders.garment"),
              render: (row) => td("garments", row.garmentType),
            },
            { key: "offeredTotal", label: t("tailor.priceRequests.offer") },
          ]}
          rows={rows.map((r) => ({
            id: r.id,
            status: r.status,
            garmentType: r.garmentType ?? r.garment_type ?? r.garment,
            offeredTotal:
              r.offeredTotal ?? r.offered_total ?? r.lockedTotal ?? r.locked_total,
          }))}
        />
      )}
    </div>
  );
}
