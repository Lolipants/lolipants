"use client";

import { useCallback, useEffect, useState } from "react";
import { adminApi } from "@/lib/admin-api";
import { AdminScopes } from "@/lib/types";
import {
  Badge,
  Button,
  CheckboxField,
  DataTable,
  EmptyState,
  ErrorBanner,
  Input,
  PageHeader,
  Panel,
  Select,
  StatusBadge,
  Textarea,
} from "@/components/ui";
import { RequireRole } from "@/components/RequireRole";
import { useI18n } from "@/components/I18nProvider";
import { MannequinAssetPreview } from "@/components/MannequinAssetPreview";
import {
  cmsRowsToMannequins,
  defaultMannequinForGender,
  fallbackMannequins,
  inferGenderLane,
  type MannequinDef,
} from "@/lib/mannequins";

const RESOURCES = [
  "fabrics",
  "presets",
  "design-catalog",
  "wedding-dresses",
  "accessories",
  "configurator_options",
];

const UPLOADABLE_RESOURCES = new Set([
  "design-catalog",
  "wedding-dresses",
  "accessories",
  "configurator_options",
]);

const MAX_ADMIN_IMAGE_BYTES = 8 * 1024 * 1024;

type CmsFormState = {
  id: string;
  labelEn: string;
  labelAr: string;
  name: string;
  category: string;
  garmentType: string;
  genderLane: "women" | "men";
  sortOrder: string;
  slotId: string;
  optionKey: string;
  metadataJson: string;
  imageUrl: string;
  isActive: boolean;
};

const emptyForm: CmsFormState = {
  id: "",
  labelEn: "",
  labelAr: "",
  name: "",
  category: "",
  garmentType: "",
  genderLane: "women",
  sortOrder: "",
  slotId: "",
  optionKey: "",
  metadataJson: "",
  imageUrl: "",
  isActive: true,
};

export default function AdminCmsPage() {
  const { t } = useI18n();
  const [resource, setResource] = useState(RESOURCES[0]);
  const [rows, setRows] = useState<Record<string, unknown>[]>([]);
  const [slots, setSlots] = useState<Record<string, unknown>[]>([]);
  const [mannequins, setMannequins] =
    useState<MannequinDef[]>(fallbackMannequins);
  const [error, setError] = useState("");
  const [form, setForm] = useState<CmsFormState>(emptyForm);
  const [file, setFile] = useState<File | null>(null);
  const [mannequinId, setMannequinId] = useState("standard_female");
  const [uploading, setUploading] = useState(false);

  const load = useCallback(() => {
    setError("");
    const request =
      resource === "configurator_options"
        ? adminApi.listConfigurator(resource)
        : adminApi.listCms(resource);
    request
      .then(setRows)
      .catch((e: { message?: string }) =>
        setError(e.message ?? t("admin.cms.loadError")),
      );
  }, [resource, t]);

  useEffect(() => {
    load();
  }, [load]);

  useEffect(() => {
    adminApi
      .listCms("mannequins")
      .then((rows) => {
        const parsed = cmsRowsToMannequins(rows);
        setMannequins(parsed.length > 0 ? parsed : fallbackMannequins);
      })
      .catch((e: { message?: string }) =>
        setError(e.message ?? t("admin.cms.mannequinLoadError")),
      );
  }, [t]);

  useEffect(() => {
    if (resource !== "configurator_options") {
      setSlots([]);
      return;
    }
    adminApi
      .listConfigurator("configurator_slots")
      .then(setSlots)
      .catch((e: { message?: string }) =>
        setError(e.message ?? t("admin.cms.slotsLoadError")),
      );
  }, [resource, t]);

  function resetForm() {
    setForm(emptyForm);
    setFile(null);
    setMannequinId(defaultMannequinForGender("women", mannequins));
  }

  function updateForm(patch: Partial<CmsFormState>) {
    setForm((current) => {
      const next = { ...current, ...patch };
      if (patch.genderLane) {
        setMannequinId(defaultMannequinForGender(patch.genderLane, mannequins));
      }
      return next;
    });
  }

  function onFileChange(next: File) {
    if (!next.type.startsWith("image/")) {
      setError(t("admin.cms.selectImage"));
      return;
    }
    if (next.size > MAX_ADMIN_IMAGE_BYTES) {
      setError(t("admin.cms.imageTooLarge"));
      return;
    }
    setError("");
    setFile(next);
    const lane = inferGenderLane([
      next.name,
      form.genderLane,
      form.category,
      form.garmentType,
      form.labelEn,
      form.optionKey,
    ]);
    updateForm({ genderLane: lane });
  }

  async function confirmUpload(): Promise<string> {
    if (!file) return form.imageUrl;
    setUploading(true);
    try {
      const category = resource === "configurator_options" ? "configurator" : "designs";
      const { url } = await adminApi.uploadCatalogAsset(file, category);
      setForm((current) => ({ ...current, imageUrl: url }));
      setFile(null);
      return url;
    } catch (e) {
      setError((e as { message?: string }).message ?? t("admin.news.uploadFailed"));
      return "";
    } finally {
      setUploading(false);
    }
  }

  async function save() {
    try {
      const imageUrl = await confirmUpload();
      if (UPLOADABLE_RESOURCES.has(resource) && !imageUrl) {
        setError(t("admin.cms.confirmImageBeforeSave"));
        return;
      }
      const body =
        resource === "configurator_options"
          ? configuratorBody({ ...form, imageUrl })
          : cmsBody(resource, { ...form, imageUrl });
      if (form.id) {
        if (resource === "configurator_options") {
          await adminApi.updateConfigurator(resource, form.id, body);
        } else {
          await adminApi.updateCms(resource, form.id, body);
        }
      } else if (resource === "configurator_options") {
        await adminApi.createConfigurator(resource, body);
      } else {
        await adminApi.createCms(resource, body);
      }
      resetForm();
      load();
    } catch (e) {
      setError((e as { message?: string }).message ?? t("admin.cms.saveFailed"));
    }
  }

  async function removeSelected() {
    if (!form.id || !confirm(t("admin.cms.deleteConfirm").replace("{id}", form.id))) return;
    try {
      if (resource === "configurator_options") {
        await adminApi.deleteConfigurator(resource, form.id);
      } else {
        await adminApi.deleteCms(resource, form.id);
      }
      resetForm();
      load();
    } catch (e) {
      setError((e as { message?: string }).message ?? t("admin.cms.deleteFailed"));
    }
  }

  function editRow(row: Record<string, unknown>) {
    const lane = inferGenderLane([
      row.gender_lane,
      row.category,
      row.garment_type,
      row.label_en,
      row.option_key,
    ]);
    setForm({
      id: String(row.id ?? ""),
      labelEn: String(row.label_en ?? row.name_en ?? row.labelEn ?? ""),
      labelAr: String(row.label_ar ?? row.name_ar ?? row.labelAr ?? ""),
      name: String(row.name ?? row.name_en ?? ""),
      category: String(row.category ?? ""),
      garmentType: String(row.garment_type ?? ""),
      genderLane: lane,
      sortOrder: String(row.sort_order ?? ""),
      slotId: String(row.slot_id ?? ""),
      optionKey: String(row.option_key ?? ""),
      metadataJson: String(row.metadata_json ?? ""),
      imageUrl: String(row.image_url ?? row.asset_url ?? ""),
      isActive: row.is_active === 0 || row.isActive === false ? false : true,
    });
    setFile(null);
    setMannequinId(defaultMannequinForGender(lane, mannequins));
  }

  const uploadable = UPLOADABLE_RESOURCES.has(resource);

  return (
    <RequireRole role="admin" scope={AdminScopes.cms}>
      <PageHeader title={t("admin.cms.title")} subtitle={t("admin.cms.subtitle")} />
      {error && <ErrorBanner message={error} />}
      <Panel className="mb-5">
        <div className="mb-3">
          <p className="text-sm font-medium text-zinc-200">{t("admin.cms.resourceLibrary")}</p>
          <p className="text-sm text-zinc-500">{t("admin.cms.resourceLibraryDescription")}</p>
        </div>
      <div className="flex flex-wrap gap-2">
        {RESOURCES.map((r) => (
          <Button
            key={r}
            type="button"
            onClick={() => setResource(r)}
            variant={resource === r ? "primary" : "secondary"}
          >
            {t(`admin.cms.resources.${r}`, r)}
          </Button>
        ))}
      </div>
      </Panel>
      <Panel className="mb-6 grid gap-5 lg:grid-cols-[minmax(0,1fr)_420px]">
        <div className="grid gap-3 md:grid-cols-2">
          <Input placeholder={t("admin.cms.labelEn")} value={form.labelEn} onChange={(e) => updateForm({ labelEn: e.target.value })} />
          <Input placeholder={t("admin.cms.labelAr")} value={form.labelAr} onChange={(e) => updateForm({ labelAr: e.target.value })} />
          {resource === "configurator_options" ? (
            <>
              <Select value={form.slotId} onChange={(e) => updateForm({ slotId: e.target.value })}>
                <option value="">{t("admin.cms.selectSlot")}</option>
                {slots.map((slot) => (
                  <option key={String(slot.id)} value={String(slot.id)}>
                    {String(slot.title_en ?? slot.slot_key ?? slot.id)}
                  </option>
                ))}
              </Select>
              <Input placeholder={t("admin.cms.optionKey")} value={form.optionKey} onChange={(e) => updateForm({ optionKey: e.target.value })} />
              <Textarea placeholder={t("admin.cms.metadataJson")} value={form.metadataJson} onChange={(e) => updateForm({ metadataJson: e.target.value })} className="min-h-24 md:col-span-2" />
            </>
          ) : (
            <>
              <Input placeholder={t("admin.cms.nameGarmentType")} value={form.name} onChange={(e) => updateForm({ name: e.target.value, garmentType: e.target.value })} />
              <Input placeholder={t("admin.cms.category")} value={form.category} onChange={(e) => updateForm({ category: e.target.value })} />
            </>
          )}
          <Select value={form.genderLane} onChange={(e) => updateForm({ genderLane: e.target.value as "women" | "men" })}>
            <option value="women">{t("admin.cms.women")}</option>
            <option value="men">{t("admin.cms.men")}</option>
          </Select>
          <Input placeholder={t("admin.cms.sortOrder")} value={form.sortOrder} onChange={(e) => updateForm({ sortOrder: e.target.value })} />
          <CheckboxField label={t("common.active")} checked={form.isActive} onChange={(checked) => updateForm({ isActive: checked })} />
          <div className="flex flex-wrap gap-2 md:col-span-2">
            <Button type="button" onClick={() => void save()} disabled={uploading}>
              {form.id ? t("admin.users.saveChanges") : t("admin.cms.createRow")}
            </Button>
            <Button type="button" variant="secondary" onClick={resetForm} disabled={uploading}>
              {t("admin.cms.reset")}
            </Button>
            {form.id && (
              <Button type="button" variant="danger" onClick={() => void removeSelected()} disabled={uploading}>
                {t("admin.cms.deleteSelected")}
              </Button>
            )}
          </div>
        </div>
        {uploadable ? (
          <MannequinAssetPreview
            file={file}
            existingUrl={form.imageUrl}
            mannequinId={mannequinId}
            mannequins={mannequins}
            onMannequinChange={setMannequinId}
            onFileChange={onFileChange}
            onClear={() => {
              setFile(null);
              updateForm({ imageUrl: "" });
            }}
            onConfirm={() => void confirmUpload()}
            uploadConfirmed={!file && form.imageUrl.length > 0}
            uploading={uploading}
            layerPreview
          />
        ) : (
          <EmptyState title={t("admin.cms.noPreview")} description={t("admin.cms.noPreviewDescription")} />
        )}
      </Panel>
      <DataTable
        emptyTitle={t("admin.cms.emptyTitle")}
        emptyDescription={t("admin.cms.emptyDescription")}
        columns={[
          { key: "id", label: t("admin.common.id") },
          { key: "label", label: t("admin.cms.label") },
          {
            key: "asset",
            label: t("admin.cms.asset"),
            render: (row) => (
              <Badge tone={row.asset === "yes" ? "success" : "neutral"}>
                {row.asset === "yes" ? t("common.yes") : t("common.no")}
              </Badge>
            ),
          },
          { key: "active", label: t("common.active"), render: (row) => <StatusBadge status={row.active === "yes" ? "active" : "inactive"} /> },
        ]}
        rows={rows.map((r) => ({
          id: r.id,
          label: r.label_en ?? r.name_en ?? r.labelEn,
          asset: (r.image_url ?? r.asset_url) ? "yes" : "no",
          active: r.is_active ?? r.isActive ? "yes" : "no",
        }))}
        onRowClick={(row) => editRow(rows.find((r) => r.id === row.id) ?? row)}
      />
    </RequireRole>
  );
}

function cmsBody(resource: string, form: CmsFormState): Record<string, unknown> {
  const sortOrder = Number.parseInt(form.sortOrder, 10);
  const base: Record<string, unknown> = {
    is_active: form.isActive ? 1 : 0,
  };
  if (Number.isFinite(sortOrder)) {
    base.sort_order = sortOrder;
  }

  switch (resource) {
    case "design-catalog":
      return {
        ...base,
        section_title: form.category || "Admin uploads",
        label_en: form.labelEn,
        label_ar: form.labelAr,
        garment_type: form.garmentType || form.name,
        gender_lane: form.genderLane,
        image_url: form.imageUrl,
      };
    case "wedding-dresses":
    case "accessories":
      return {
        ...base,
        label_en: form.labelEn,
        label_ar: form.labelAr,
        category: form.category,
        image_url: form.imageUrl,
      };
    default:
      return {
        ...base,
        label_en: form.labelEn,
        label_ar: form.labelAr,
        name_en: form.labelEn,
        name_ar: form.labelAr,
        name: form.name || form.labelEn,
      };
  }
}

function configuratorBody(form: CmsFormState): Record<string, unknown> {
  const sortOrder = Number.parseInt(form.sortOrder, 10);
  return {
    slot_id: form.slotId,
    option_key: form.optionKey,
    label_en: form.labelEn,
    label_ar: form.labelAr,
    asset_url: form.imageUrl,
    metadata_json: form.metadataJson,
    is_active: form.isActive ? 1 : 0,
    ...(Number.isFinite(sortOrder) ? { sort_order: sortOrder } : {}),
  };
}
