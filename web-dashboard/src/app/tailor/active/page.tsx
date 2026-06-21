"use client";

import { TailorQueuePage } from "@/components/TailorQueuePage";
import { useI18n } from "@/components/I18nProvider";

export default function TailorActivePage() {
  const { t } = useI18n();

  return (
    <TailorQueuePage
      title={t("tailor.active.title")}
      subtitle={t("tailor.active.subtitle")}
      bucket="active"
      detailPrefix="active"
    />
  );
}
