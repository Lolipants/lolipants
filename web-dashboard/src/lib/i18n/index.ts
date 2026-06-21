import { messages, type Locale, type MessageKey } from "./messages";

export { messages, type Locale };

export const defaultLocale: Locale = "en";
export const locales = ["en", "ar"] as const satisfies readonly Locale[];

export function isLocale(value: unknown): value is Locale {
  return value === "en" || value === "ar";
}

export function directionForLocale(locale: Locale) {
  return locale === "ar" ? "rtl" : "ltr";
}

export function translate(locale: Locale, key: MessageKey, fallback?: string): string {
  const value = getMessage(messages[locale], key);
  if (typeof value === "string") return value;
  const english = getMessage(messages.en, key);
  if (typeof english === "string") return english;
  return fallback ?? key;
}

export function translateDynamic(
  locale: Locale,
  namespace: string,
  value: unknown,
  fallback?: string,
) {
  const raw = String(value ?? "unknown");
  const normalized = raw.trim().toLowerCase().replaceAll(" ", "_");
  return translate(locale, `${namespace}.${normalized}`, fallback ?? humanize(raw));
}

export function humanize(value: unknown) {
  return String(value ?? "unknown")
    .replaceAll("_", " ")
    .replace(/\b\w/g, (letter) => letter.toUpperCase());
}

function getMessage(source: unknown, key: string): unknown {
  return key.split(".").reduce<unknown>((current, part) => {
    if (current && typeof current === "object" && part in current) {
      return (current as Record<string, unknown>)[part];
    }
    return undefined;
  }, source);
}
