"use client";

import { TailorQueuePage } from "@/components/TailorQueuePage";
import { useI18n } from "@/components/I18nProvider";

export default function TailorCompletedPage() {
  const { t } = useI18n();

  return (
    <TailorQueuePage
      title={t("tailor.completed.title")}
      subtitle={t("tailor.completed.subtitle")}
      bucket="completed"
      detailPrefix="completed"
    />
  );
}
