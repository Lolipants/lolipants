"use client";

import { useCallback, useEffect, useState } from "react";
import { adminApi } from "@/lib/admin-api";
import { AdminScopes } from "@/lib/types";
import { Button, CheckboxField, DataTable, ErrorBanner, Input, PageHeader, Textarea } from "@/components/ui";
import { RequireRole } from "@/components/RequireRole";
import { useI18n } from "@/components/I18nProvider";

export default function AdminNewsPage() {
  const { t } = useI18n();
  const [rows, setRows] = useState<Record<string, unknown>[]>([]);
  const [error, setError] = useState("");
  const [form, setForm] = useState({
    titleEn: "",
    titleAr: "",
    summaryEn: "",
    summaryAr: "",
    bodyEn: "",
    bodyAr: "",
    isPublished: true,
    isFeatured: false,
  });

  const load = useCallback(() => {
    adminApi.listNews().then(setRows).catch((e: { message?: string }) => setError(e.message ?? t("admin.common.error")));
  }, [t]);

  useEffect(() => {
    load();
  }, [load]);

  async function create() {
    try {
      await adminApi.createNews(form);
      setForm({ titleEn: "", titleAr: "", summaryEn: "", summaryAr: "", bodyEn: "", bodyAr: "", isPublished: true, isFeatured: false });
      load();
    } catch (e) {
      setError((e as { message?: string }).message ?? t("admin.news.createFailed"));
    }
  }

  async function onCoverUpload(e: React.ChangeEvent<HTMLInputElement>, id: string) {
    const file = e.target.files?.[0];
    if (!file) return;
    try {
      const { url } = await adminApi.uploadNewsAsset(file);
      await adminApi.updateNews(id, { coverImageUrl: url });
      load();
    } catch (err) {
      setError((err as { message?: string }).message ?? t("admin.news.uploadFailed"));
    }
  }

  return (
    <RequireRole role="admin" scope={AdminScopes.news}>
      <PageHeader title={t("admin.news.title")} subtitle={t("admin.news.subtitle")} />
      {error && <ErrorBanner message={error} />}
      <div className="mb-8 grid gap-3 rounded-xl border border-zinc-800 p-4 md:grid-cols-2">
        {(["titleEn", "titleAr", "summaryEn", "summaryAr"] as const).map((k) => (
          <Input
            key={k}
            placeholder={t(`admin.news.fields.${k}`, k)}
            value={form[k]}
            onChange={(e) => setForm({ ...form, [k]: e.target.value })}
          />
        ))}
        <Textarea placeholder={t("admin.news.fields.bodyEn")} value={form.bodyEn} onChange={(e) => setForm({ ...form, bodyEn: e.target.value })} className="md:col-span-2 min-h-24" />
        <Textarea placeholder={t("admin.news.fields.bodyAr")} value={form.bodyAr} onChange={(e) => setForm({ ...form, bodyAr: e.target.value })} className="md:col-span-2 min-h-24" />
        <CheckboxField label={t("admin.news.published")} checked={form.isPublished} onChange={(checked) => setForm({ ...form, isPublished: checked })} />
        <CheckboxField label={t("admin.news.featured")} checked={form.isFeatured} onChange={(checked) => setForm({ ...form, isFeatured: checked })} />
        <Button type="button" onClick={create} className="md:col-span-2">{t("admin.news.createArticle")}</Button>
      </div>
      <DataTable
        columns={[
          { key: "titleEn", label: t("admin.news.tableTitle") },
          { key: "published", label: t("admin.news.published") },
          { key: "featured", label: t("admin.news.featured") },
        ]}
        rows={rows.map((r) => ({
          id: r.id,
          titleEn: r.titleEn ?? r.title_en,
          published: r.isPublished ?? r.is_published ? t("common.yes") : t("common.no"),
          featured: r.isFeatured ?? r.is_featured ? t("common.yes") : t("common.no"),
        }))}
        onRowClick={(row) => {
          const id = String(row.id);
          const input = document.createElement("input");
          input.type = "file";
          input.accept = "image/*";
          input.onchange = (ev) => onCoverUpload(ev as unknown as React.ChangeEvent<HTMLInputElement>, id);
          input.click();
        }}
      />
    </RequireRole>
  );
}
