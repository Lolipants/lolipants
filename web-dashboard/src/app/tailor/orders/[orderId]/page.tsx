"use client";

import { useCallback, useEffect, useState } from "react";
import { useParams, useSearchParams } from "next/navigation";
import Link from "next/link";
import { tailorApi, TAILOR_TRANSITIONS } from "@/lib/tailor-api";
import type { OrderRow } from "@/lib/types";
import { Button, ErrorBanner, LoadingState, PageHeader, Panel, StatusBadge } from "@/components/ui";
import { useI18n } from "@/components/I18nProvider";

export default function TailorOrderDetailPage() {
  const { t, td } = useI18n();
  const params = useParams();
  const searchParams = useSearchParams();
  const orderId = String(params.orderId);
  const from = searchParams.get("from") ?? "incoming";
  const [order, setOrder] = useState<OrderRow | null>(null);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  const load = useCallback(() => {
    tailorApi
      .getOrder(orderId)
      .then(setOrder)
      .catch((e: { message?: string }) => setError(e.message ?? t("tailor.order.loadError")));
  }, [orderId, t]);

  useEffect(() => {
    load();
  }, [load]);

  const status = String(order?.status ?? "");
  const nextStatuses = TAILOR_TRANSITIONS[status] ?? [];

  async function claim() {
    setBusy(true);
    try {
      await tailorApi.claim(orderId);
      load();
    } catch (e) {
      setError((e as { message?: string }).message ?? t("tailor.order.claimFailed"));
    } finally {
      setBusy(false);
    }
  }

  async function advance(next: string) {
    setBusy(true);
    try {
      await tailorApi.advanceStatus(orderId, next);
      load();
    } catch (e) {
      setError((e as { message?: string }).message ?? t("admin.common.updateFailed"));
    } finally {
      setBusy(false);
    }
  }

  return (
    <div>
      <PageHeader
        title={t("orders.orderWithId", `Order ${orderId}`).replace("{id}", orderId)}
        subtitle={t("tailor.order.subtitle")}
        actions={
          <Link href={`/tailor/${from}`} className="rounded-xl border border-white/10 px-4 py-2 text-sm text-zinc-200 hover:bg-white/[0.06]">
            {t("tailor.order.backToQueue")}
          </Link>
        }
      />
      {error && <ErrorBanner message={error} />}
      {!order && !error && <LoadingState label={t("tailor.order.loading")} />}
      {order && (
        <div className="grid gap-5 lg:grid-cols-[1fr_360px]">
          <Panel>
            <div className="mb-5 flex items-center justify-between gap-4">
              <div>
                <p className="text-sm text-zinc-500">{t("admin.orders.currentStatus")}</p>
                <div className="mt-2"><StatusBadge status={status} /></div>
              </div>
              <p className="text-sm text-zinc-500">{t("tailor.order.workshopOrder")}</p>
            </div>
            <dl className="grid gap-4 sm:grid-cols-2">
              <Detail label={t("orders.garment")} value={td("garments", order.garmentType ?? order.garment_type)} />
              <Detail label={t("orders.customer")} value={order.customerName ?? order.customer_name ?? order.userId} />
              <Detail label={t("orders.total")} value={order.totalAmount ?? order.total_amount} />
              <Detail label={t("tailor.order.created")} value={order.createdAt ?? order.created_at} />
            </dl>
          </Panel>
          <Panel>
            <h2 className="text-base font-semibold text-zinc-100">{t("tailor.order.nextAction")}</h2>
            <p className="mt-1 text-sm text-zinc-500">
              {t("tailor.order.nextActionDescription")}
            </p>
          {status === "placed" && (
              <Button type="button" disabled={busy} onClick={claim} className="mt-4 w-full">
              {t("tailor.order.claimOrder")}
              </Button>
          )}
          {nextStatuses.length > 0 && status !== "placed" && (
              <div className="mt-4 grid gap-2">
              {nextStatuses.map((s) => (
                  <Button
                  key={s}
                  type="button"
                    variant={s === "cancelled" ? "danger" : "secondary"}
                  disabled={busy}
                  onClick={() => advance(s)}
                >
                    {t("tailor.order.moveTo").replace("{status}", td("status", s))}
                  </Button>
              ))}
            </div>
          )}
            {nextStatuses.length === 0 && status !== "placed" && (
              <p className="mt-4 text-sm text-zinc-500">{t("tailor.order.noActions")}</p>
            )}
          </Panel>
        </div>
      )}
    </div>
  );
}

function Detail({ label, value }: { label: string; value: unknown }) {
  return (
    <div className="rounded-xl border border-white/10 bg-white/[0.03] p-4">
      <dt className="text-xs uppercase tracking-wide text-zinc-500">{label}</dt>
      <dd className="mt-2 text-sm font-medium text-zinc-100">{String(value ?? "—")}</dd>
    </div>
  );
}
