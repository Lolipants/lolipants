"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";
import {
  defaultLocale,
  directionForLocale,
  isLocale,
  translate,
  translateDynamic,
  type Locale,
} from "@/lib/i18n";

type I18nContextValue = {
  locale: Locale;
  dir: "ltr" | "rtl";
  setLocale: (locale: Locale) => void;
  t: (key: string, fallback?: string) => string;
  td: (namespace: string, value: unknown, fallback?: string) => string;
};

const I18nContext = createContext<I18nContextValue | null>(null);

export function I18nProvider({ children }: { children: React.ReactNode }) {
  const [locale, setLocaleState] = useState<Locale>(defaultLocale);

  useEffect(() => {
    const stored = window.localStorage.getItem("lolipants.locale");
    if (isLocale(stored)) {
      setLocaleState(stored);
      return;
    }

    const cookieLocale = document.cookie
      .split("; ")
      .find((entry) => entry.startsWith("lolipants.locale="))
      ?.split("=")[1];
    if (isLocale(cookieLocale)) {
      setLocaleState(cookieLocale);
    }
  }, []);

  useEffect(() => {
    const dir = directionForLocale(locale);
    document.documentElement.lang = locale;
    document.documentElement.dir = dir;
    window.localStorage.setItem("lolipants.locale", locale);
    document.cookie = `lolipants.locale=${locale}; path=/; max-age=31536000; samesite=lax`;
  }, [locale]);

  const setLocale = useCallback((nextLocale: Locale) => {
    setLocaleState(nextLocale);
  }, []);

  const value = useMemo<I18nContextValue>(
    () => ({
      locale,
      dir: directionForLocale(locale),
      setLocale,
      t: (key, fallback) => translate(locale, key, fallback),
      td: (namespace, dynamicValue, fallback) =>
        translateDynamic(locale, namespace, dynamicValue, fallback),
    }),
    [locale, setLocale],
  );

  return <I18nContext.Provider value={value}>{children}</I18nContext.Provider>;
}

export function useI18n() {
  const context = useContext(I18nContext);
  if (!context) {
    throw new Error("useI18n must be used within I18nProvider");
  }
  return context;
}
