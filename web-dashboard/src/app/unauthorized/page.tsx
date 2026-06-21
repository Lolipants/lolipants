"use client";

import { useRouter } from "next/navigation";
import { useAuth } from "@/components/AuthProvider";
import { useI18n } from "@/components/I18nProvider";
import { LanguageToggle } from "@/components/LanguageToggle";

export default function UnauthorizedPage() {
  const { signOut } = useAuth();
  const { t } = useI18n();
  const router = useRouter();

  async function backToLogin() {
    await signOut();
    router.replace("/login");
  }

  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-zinc-950 px-4 text-center">
      <LanguageToggle className="mb-6" />
      <h1 className="text-2xl font-semibold text-zinc-50">{t("auth.accessDenied")}</h1>
      <p className="mt-2 max-w-md text-sm text-zinc-400">
        {t("auth.unauthorizedCopy")}
      </p>
      <button
        type="button"
        onClick={() => void backToLogin()}
        className="mt-6 rounded-lg bg-amber-500 px-4 py-2 text-sm font-medium text-zinc-950"
      >
        {t("auth.backToSignIn")}
      </button>
    </div>
  );
}
