"use client";

import { useEffect, useState } from "react";
import { tailorApi } from "@/lib/tailor-api";
import {
  Button,
  CheckboxField,
  ErrorBanner,
  Input,
  LoadingState,
  PageHeader,
  Panel,
  Select,
  StatusBadge,
  Textarea,
} from "@/components/ui";
import { useI18n } from "@/components/I18nProvider";

type PriceRow = {
  garmentType: string;
  fabricQuality: string;
  basePrice: string;
  fabricFee: string;
};

type DeliveryFeeRow = {
  cityKey: string;
  fee: string;
};

type PricingForm = {
  shopName: string;
  address: string;
  city: string;
  lat: string;
  lng: string;
  serviceRadiusKm: string;
  isAcceptingOrders: boolean;
  planName: string;
  currency: string;
  garmentPrices: PriceRow[];
  deliveryFees: DeliveryFeeRow[];
  garmentTypes: string[];
  fabricQualities: string[];
};

const emptyForm: PricingForm = {
  shopName: "",
  address: "",
  city: "Doha",
  lat: "",
  lng: "",
  serviceRadiusKm: "50",
  isAcceptingOrders: false,
  planName: "Standard plan",
  currency: "QAR",
  garmentPrices: [],
  deliveryFees: [],
  garmentTypes: [],
  fabricQualities: [],
};

export default function TailorPricingPage() {
  const { t, td } = useI18n();
  const [form, setForm] = useState<PricingForm>(emptyForm);
  const [rawJson, setRawJson] = useState("");
  const [error, setError] = useState("");
  const [saved, setSaved] = useState(false);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [showAdvanced, setShowAdvanced] = useState(false);

  useEffect(() => {
    setLoading(true);
    tailorApi
      .getPricing()
      .then((data) => {
        setRawJson(JSON.stringify(data, null, 2));
        setForm(pricingToForm(data));
      })
      .catch((e: { message?: string }) => setError(e.message ?? t("tailor.pricing.loadError")))
      .finally(() => setLoading(false));
  }, [t]);

  async function save() {
    setSaving(true);
    setSaved(false);
    setError("");
    try {
      await tailorApi.updatePricingProfile({
        shopName: form.shopName,
        address: form.address,
        city: form.city,
        lat: numberOrNull(form.lat),
        lng: numberOrNull(form.lng),
        serviceRadiusKm: numberOrDefault(form.serviceRadiusKm, 50),
        isAcceptingOrders: form.isAcceptingOrders,
      });
      await tailorApi.updatePricingPlan({
        name: form.planName,
        currency: form.currency,
      });
      await tailorApi.updateGarmentPrices(
        form.garmentPrices.map((row) => ({
          garmentType: row.garmentType,
          fabricQuality: row.fabricQuality,
          basePrice: numberOrDefault(row.basePrice, 0),
          fabricFee: numberOrDefault(row.fabricFee, 0),
        })),
      );
      await tailorApi.updateDeliveryFees(
        form.deliveryFees.map((row) => ({
          cityKey: row.cityKey,
          fee: numberOrDefault(row.fee, 0),
        })),
      );
      const refreshed = await tailorApi.getPricing();
      setRawJson(JSON.stringify(refreshed, null, 2));
      setForm(pricingToForm(refreshed));
      setSaved(true);
    } catch (e) {
      setError(e instanceof Error ? e.message : t("tailor.pricing.saveFailed"));
    } finally {
      setSaving(false);
    }
  }

  function updatePrice(index: number, patch: Partial<PriceRow>) {
    setForm((current) => ({
      ...current,
      garmentPrices: current.garmentPrices.map((row, i) =>
        i === index ? { ...row, ...patch } : row,
      ),
    }));
  }

  function updateDelivery(index: number, patch: Partial<DeliveryFeeRow>) {
    setForm((current) => ({
      ...current,
      deliveryFees: current.deliveryFees.map((row, i) =>
        i === index ? { ...row, ...patch } : row,
      ),
    }));
  }

  return (
    <div>
      <PageHeader
        title={t("tailor.pricing.title")}
        subtitle={t("tailor.pricing.subtitle")}
        actions={
          <Button type="button" onClick={save} disabled={saving || loading}>
            {saving ? t("common.saving") : t("tailor.pricing.savePricing")}
          </Button>
        }
      />
      {error && <ErrorBanner message={error} />}
      {saved && (
        <div className="mb-4 rounded-xl border border-emerald-500/30 bg-emerald-950/30 px-4 py-3 text-sm text-emerald-200">
          {t("tailor.pricing.saved")}
        </div>
      )}
      {loading ? (
        <LoadingState label={t("tailor.pricing.loading")} />
      ) : (
        <div className="space-y-5">
          <Panel>
            <div className="mb-4 flex items-center justify-between">
              <div>
                <h2 className="text-base font-semibold text-zinc-100">{t("tailor.pricing.workshopProfile")}</h2>
                <p className="text-sm text-zinc-500">{t("tailor.pricing.workshopProfileDescription")}</p>
              </div>
              <StatusBadge status={form.isAcceptingOrders ? "accepting_orders" : "not_accepting"} />
            </div>
            <div className="grid gap-3 md:grid-cols-2">
              <Input placeholder={t("tailor.pricing.shopName")} value={form.shopName} onChange={(e) => setForm({ ...form, shopName: e.target.value })} />
              <Input placeholder={t("tailor.pricing.city")} value={form.city} onChange={(e) => setForm({ ...form, city: e.target.value })} />
              <Input placeholder={t("tailor.pricing.address")} value={form.address} onChange={(e) => setForm({ ...form, address: e.target.value })} className="md:col-span-2" />
              <Input placeholder={t("tailor.pricing.latitude")} value={form.lat} onChange={(e) => setForm({ ...form, lat: e.target.value })} />
              <Input placeholder={t("tailor.pricing.longitude")} value={form.lng} onChange={(e) => setForm({ ...form, lng: e.target.value })} />
              <Input placeholder={t("tailor.pricing.serviceRadius")} value={form.serviceRadiusKm} onChange={(e) => setForm({ ...form, serviceRadiusKm: e.target.value })} />
              <CheckboxField label={t("tailor.pricing.acceptNewOrders")} checked={form.isAcceptingOrders} onChange={(checked) => setForm({ ...form, isAcceptingOrders: checked })} />
            </div>
          </Panel>

          <Panel>
            <div className="mb-4">
              <h2 className="text-base font-semibold text-zinc-100">{t("tailor.pricing.pricePlan")}</h2>
              <p className="text-sm text-zinc-500">{t("tailor.pricing.pricePlanDescription")}</p>
            </div>
            <div className="grid gap-3 md:grid-cols-2">
              <Input value={form.planName} onChange={(e) => setForm({ ...form, planName: e.target.value })} />
              <Select value={form.currency} onChange={(e) => setForm({ ...form, currency: e.target.value })}>
                <option value="QAR">QAR</option>
                <option value="USD">USD</option>
              </Select>
            </div>
          </Panel>

          <Panel>
            <div className="mb-4">
              <h2 className="text-base font-semibold text-zinc-100">{t("tailor.pricing.garmentPrices")}</h2>
              <p className="text-sm text-zinc-500">{t("tailor.pricing.garmentPricesDescription")}</p>
            </div>
            <div className="overflow-x-auto">
              <table className="min-w-full text-start text-sm">
                <thead className="text-xs uppercase tracking-wide text-zinc-500">
                  <tr>
                    <th className="px-3 py-2">{t("orders.garment")}</th>
                    <th className="px-3 py-2">{t("tailor.pricing.fabric")}</th>
                    <th className="px-3 py-2">{t("tailor.pricing.basePrice")}</th>
                    <th className="px-3 py-2">{t("tailor.pricing.fabricFee")}</th>
                    <th className="px-3 py-2">{t("tailor.pricing.customerTotal")}</th>
                  </tr>
                </thead>
                <tbody>
                  {form.garmentPrices.map((row, index) => (
                    <tr key={`${row.garmentType}-${row.fabricQuality}`} className="border-t border-white/10">
                      <td className="px-3 py-2 text-zinc-200">{td("garments", row.garmentType)}</td>
                      <td className="px-3 py-2 text-zinc-400">{td("fabrics", row.fabricQuality)}</td>
                      <td className="px-3 py-2">
                        <Input value={row.basePrice} onChange={(e) => updatePrice(index, { basePrice: e.target.value })} className="w-28" />
                      </td>
                      <td className="px-3 py-2">
                        <Input value={row.fabricFee} onChange={(e) => updatePrice(index, { fabricFee: e.target.value })} className="w-28" />
                      </td>
                      <td className="px-3 py-2 font-medium text-amber-200">
                        {money(numberOrDefault(row.basePrice, 0) + numberOrDefault(row.fabricFee, 0), form.currency)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </Panel>

          <Panel>
            <div className="mb-4">
              <h2 className="text-base font-semibold text-zinc-100">{t("tailor.pricing.deliveryFees")}</h2>
              <p className="text-sm text-zinc-500">{t("tailor.pricing.deliveryFeesDescription")}</p>
            </div>
            <div className="grid gap-3 md:grid-cols-2">
              {form.deliveryFees.map((row, index) => (
                <div key={`${row.cityKey}-${index}`} className="grid grid-cols-[1fr_140px] gap-2">
                  <Input value={row.cityKey} onChange={(e) => updateDelivery(index, { cityKey: e.target.value })} />
                  <Input value={row.fee} onChange={(e) => updateDelivery(index, { fee: e.target.value })} />
                </div>
              ))}
            </div>
          </Panel>

          <Panel>
            <button type="button" className="text-sm text-amber-300" onClick={() => setShowAdvanced(!showAdvanced)}>
              {showAdvanced ? t("tailor.pricing.hideAdvanced") : t("tailor.pricing.showAdvanced")}
            </button>
            {showAdvanced && (
              <Textarea
                value={rawJson}
                readOnly
                className="mt-4 min-h-80 font-mono text-xs"
              />
            )}
          </Panel>
        </div>
      )}
    </div>
  );
}

function pricingToForm(data: Record<string, unknown>): PricingForm {
  const profile = asRecord(data.profile);
  const plan = asRecord(data.plan);
  const garmentTypes = asStringArray(data.garmentTypes);
  const fabricQualities = asStringArray(data.fabricQualities);
  const existingPrices = asArray(data.garmentPrices);
  const priceRows = buildPriceRows(garmentTypes, fabricQualities, existingPrices);
  const deliveryRows = asArray(data.deliveryFees).map((row) => ({
    cityKey: String(row.cityKey ?? row.city_key ?? ""),
    fee: String(row.fee ?? ""),
  }));
  const defaults = data.defaultDeliveryFees;
  const fallbackDelivery =
    deliveryRows.length > 0
      ? deliveryRows
      : Object.entries(asRecord(defaults)).map(([cityKey, fee]) => ({
          cityKey,
          fee: String(fee),
        }));

  return {
    ...emptyForm,
    shopName: String(profile.shop_name ?? profile.shopName ?? ""),
    address: String(profile.address ?? ""),
    city: String(profile.city ?? "Doha"),
    lat: String(profile.lat ?? ""),
    lng: String(profile.lng ?? ""),
    serviceRadiusKm: String(profile.service_radius_km ?? profile.serviceRadiusKm ?? "50"),
    isAcceptingOrders: profile.is_accepting_orders === 1 || profile.isAcceptingOrders === true,
    planName: String(plan.name ?? "Standard plan"),
    currency: String(plan.currency ?? "QAR"),
    garmentPrices: priceRows,
    deliveryFees: fallbackDelivery,
    garmentTypes,
    fabricQualities,
  };
}

function buildPriceRows(
  garmentTypes: string[],
  fabricQualities: string[],
  existing: Record<string, unknown>[],
): PriceRow[] {
  const map = new Map(
    existing.map((row) => [
      `${row.garmentType ?? row.garment_type}:${row.fabricQuality ?? row.fabric_quality}`,
      row,
    ]),
  );
  const garments = garmentTypes.length > 0 ? garmentTypes : ["thobe", "abaya", "dress"];
  const fabrics = fabricQualities.length > 0 ? fabricQualities : ["standard"];
  return garments.flatMap((garmentType) =>
    fabrics.map((fabricQuality) => {
      const row = map.get(`${garmentType}:${fabricQuality}`) ?? {};
      return {
        garmentType,
        fabricQuality,
        basePrice: String(row.basePrice ?? row.base_price ?? ""),
        fabricFee: String(row.fabricFee ?? row.fabric_fee ?? ""),
      };
    }),
  );
}

function asRecord(value: unknown): Record<string, unknown> {
  return value && typeof value === "object" && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : {};
}

function asArray(value: unknown): Record<string, unknown>[] {
  return Array.isArray(value) ? value.filter((row) => row && typeof row === "object") as Record<string, unknown>[] : [];
}

function asStringArray(value: unknown): string[] {
  return Array.isArray(value) ? value.map(String) : [];
}

function numberOrDefault(value: string, fallback: number): number {
  const n = Number(value);
  return Number.isFinite(n) ? n : fallback;
}

function numberOrNull(value: string): number | null {
  const n = Number(value);
  return Number.isFinite(n) ? n : null;
}

function money(value: number, currency: string): string {
  return `${Math.round(value)} ${currency}`;
}
