"use client";

import { useI18n } from "./I18nProvider";
import { Button } from "./ui";

export function LanguageToggle({ className }: { className?: string }) {
  const { locale, setLocale, t } = useI18n();
  const nextLocale = locale === "ar" ? "en" : "ar";

  return (
    <Button
      type="button"
      variant="secondary"
      className={className}
      aria-label={t("common.language")}
      onClick={() => setLocale(nextLocale)}
    >
      {locale === "ar" ? t("common.english") : t("common.arabic")}
    </Button>
  );
}
