"use client";

import { useEffect, useState } from "react";
import { tailorApi, TAILOR_QUEUE } from "@/lib/tailor-api";
import type { OrderRow } from "@/lib/types";
import { DataTable, EmptyState, ErrorBanner, LoadingState, PageHeader, StatusBadge } from "@/components/ui";
import { useI18n } from "@/components/I18nProvider";

type Bucket = keyof typeof TAILOR_QUEUE;

export function TailorQueuePage({
  title,
  subtitle,
  bucket,
  detailPrefix,
}: {
  title: string;
  subtitle: string;
  bucket: Bucket;
  detailPrefix: string;
}) {
  const { t, td } = useI18n();
  const [rows, setRows] = useState<OrderRow[]>([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    tailorApi
      .getQueue([...TAILOR_QUEUE[bucket]])
      .then(setRows)
      .catch((e: { message?: string }) => setError(e.message ?? t("tailor.queue.loadError")))
      .finally(() => setLoading(false));
  }, [bucket, t]);

  return (
    <div>
      <PageHeader title={title} subtitle={subtitle} />
      {error && <ErrorBanner message={error} />}
      {loading ? (
        <LoadingState label={t("tailor.queue.loading")} />
      ) : rows.length === 0 ? (
        <EmptyState
          title={t("tailor.queue.clear")}
          description={t("tailor.queue.clearDescription")}
        />
      ) : (
        <DataTable
          columns={[
            { key: "id", label: t("orders.order") },
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
            { key: "action", label: t("orders.next"), render: () => t("orders.openDetails") },
          ]}
          rows={rows.map((r) => ({
            id: r.id,
            status: r.status,
            garmentType: r.garmentType ?? r.garment_type,
          }))}
          onRowClick={(row) => {
            window.location.href = `/tailor/orders/${row.id}?from=${detailPrefix}`;
          }}
        />
      )}
    </div>
  );
}
