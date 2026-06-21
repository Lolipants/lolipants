"use client";

import { TailorQueuePage } from "@/components/TailorQueuePage";
import { useI18n } from "@/components/I18nProvider";

export default function TailorIncomingPage() {
  const { t } = useI18n();

  return (
    <TailorQueuePage
      title={t("tailor.incoming.title")}
      subtitle={t("tailor.incoming.subtitle")}
      bucket="incoming"
      detailPrefix="incoming"
    />
  );
}
