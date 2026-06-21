"use client";

import { FormEvent, useEffect, useState } from "react";
import Image from "next/image";
import { useRouter } from "next/navigation";
import { Button, ErrorBanner, Input, Panel } from "@/components/ui";
import { useAuth } from "@/components/AuthProvider";
import { useI18n } from "@/components/I18nProvider";
import { LanguageToggle } from "@/components/LanguageToggle";
import { canAccessDashboard, homeForRole } from "@/lib/rbac";

export default function LoginPage() {
  const { signIn, signOut, user, loading } = useAuth();
  const { t } = useI18n();
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (!loading && user) {
      if (canAccessDashboard(user)) {
        router.replace(homeForRole(user));
        return;
      }
      void signOut();
    }
  }, [loading, user, router, signOut]);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError("");
    try {
      const u = await signIn(email.trim(), password);
      router.replace(homeForRole(u));
    } catch (err) {
      setError(err instanceof Error ? err.message : t("auth.signInFailed"));
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center px-4 py-10">
      <div className="w-full max-w-5xl">
        <div className="grid overflow-hidden rounded-3xl border border-white/10 bg-black/30 shadow-2xl shadow-black/40 backdrop-blur-xl lg:grid-cols-[1fr_430px]">
          <div className="hidden min-h-[560px] flex-col justify-between bg-gradient-to-br from-amber-400/20 via-zinc-950 to-black p-10 lg:flex">
            <div>
              <div className="mb-8 inline-flex h-14 w-14 items-center justify-center rounded-2xl bg-amber-400 text-2xl font-bold text-zinc-950">
                <Image
                  src="/lolipants.jpg"
                  alt="Lolipants"
                  width={56}
                  height={56}
                  className="h-14 w-14 rounded-2xl object-cover"
                  priority
                />
              </div>
              <p className="text-xs uppercase tracking-[0.32em] text-amber-200">
                Lolipants
              </p>
              <h1 className="mt-4 max-w-sm text-4xl font-semibold tracking-tight text-zinc-50">
                {t("auth.heroTitle")}
              </h1>
              <p className="mt-4 max-w-md text-sm leading-6 text-zinc-400">
                {t("auth.heroSubtitle")}
              </p>
            </div>
            <div className="grid grid-cols-3 gap-3 text-sm">
              {[
                t("auth.tiles.admin"),
                t("auth.tiles.tailor"),
                t("auth.tiles.cms"),
              ].map((label) => (
                <div key={label} className="rounded-2xl border border-white/10 bg-white/[0.04] p-4 text-zinc-200">
                  {label}
                </div>
              ))}
            </div>
          </div>
          <Panel className="rounded-none border-0 bg-zinc-950/80 p-8 shadow-none">
      <form
        onSubmit={onSubmit}
              className="mx-auto flex min-h-[500px] max-w-md flex-col justify-center"
      >
              <p className="text-xs uppercase tracking-[0.28em] text-amber-300">
                {t("auth.secureDashboard")}
              </p>
              <h2 className="mt-3 text-3xl font-semibold tracking-tight text-zinc-50">
                {t("auth.signIn")}
              </h2>
              <p className="mt-2 text-sm text-zinc-400">
                {t("auth.restrictedCopy")}
              </p>
              <LanguageToggle className="mt-5 w-full" />
              {error && <div className="mt-5"><ErrorBanner message={error} /></div>}
        <label className="mt-6 block text-sm text-zinc-300">
          {t("common.email")}
                <Input
            type="email"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
                  className="mt-2"
          />
        </label>
        <label className="mt-4 block text-sm text-zinc-300">
          {t("common.password")}
                <Input
            type="password"
            required
            value={password}
            onChange={(e) => setPassword(e.target.value)}
                  className="mt-2"
          />
        </label>
              <Button
          type="submit"
          disabled={busy}
                className="mt-6 w-full"
        >
                {busy ? t("auth.signingIn") : t("auth.signIn")}
              </Button>
      </form>
          </Panel>
        </div>
      </div>
    </div>
  );
}


