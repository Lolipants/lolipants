"use client";

import { useState } from "react";
import { adminApi } from "@/lib/admin-api";
import { AdminScopes } from "@/lib/types";
import { Button, ErrorBanner, Input, PageHeader, Panel } from "@/components/ui";
import { RequireRole } from "@/components/RequireRole";
import { useI18n } from "@/components/I18nProvider";

export default function AdminModerationPage() {
  const { t } = useI18n();
  const [postId, setPostId] = useState("");
  const [designId, setDesignId] = useState("");
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  async function hidePost() {
    try {
      await adminApi.hidePost(postId.trim());
      setMessage(t("admin.moderation.postHidden"));
      setPostId("");
    } catch (e) {
      setError((e as { message?: string }).message ?? t("admin.common.failed"));
    }
  }

  async function hideDesign() {
    try {
      await adminApi.hideDesign(designId.trim());
      setMessage(t("admin.moderation.designHidden"));
      setDesignId("");
    } catch (e) {
      setError((e as { message?: string }).message ?? t("admin.common.failed"));
    }
  }

  return (
    <RequireRole role="admin" scope={AdminScopes.moderation}>
      <PageHeader title={t("admin.moderation.title")} subtitle={t("admin.moderation.subtitle")} />
      {error && <ErrorBanner message={error} />}
      {message && <p className="mb-4 text-sm text-emerald-400">{message}</p>}
      <div className="space-y-6 max-w-lg">
        <Panel>
          <label className="block text-sm">{t("admin.moderation.postId")}</label>
          <Input value={postId} onChange={(e) => setPostId(e.target.value)} className="mt-1" />
          <Button type="button" onClick={hidePost} className="mt-3">{t("admin.moderation.hidePost")}</Button>
        </Panel>
        <Panel>
          <label className="block text-sm">{t("admin.moderation.designId")}</label>
          <Input value={designId} onChange={(e) => setDesignId(e.target.value)} className="mt-1" />
          <Button type="button" onClick={hideDesign} className="mt-3">{t("admin.moderation.hideDesign")}</Button>
        </Panel>
      </div>
    </RequireRole>
  );
}
