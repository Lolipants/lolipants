"use client";

import Link from "next/link";
import Image from "next/image";
import { usePathname } from "next/navigation";
import { useState } from "react";
import { useAuth } from "./AuthProvider";
import { useI18n } from "./I18nProvider";
import { LanguageToggle } from "./LanguageToggle";
import { Button, cn } from "./ui";

type ShellNavItem = {
  label: string;
  labelKey?: string;
  href: string;
  group?: string;
};

export function DashboardShell({
  title,
  subtitle,
  badge,
  items,
  children,
}: {
  title: string;
  subtitle: string;
  badge?: string;
  items: ShellNavItem[];
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const { user, signOut } = useAuth();
  const { t } = useI18n();
  const [open, setOpen] = useState(false);

  const current = items.find(
    (item) => pathname === item.href || pathname.startsWith(`${item.href}/`),
  );

  return (
    <div className="min-h-screen text-zinc-100">
      <div className="flex min-h-screen">
        <aside className="hidden w-72 shrink-0 border-r border-white/10 bg-black/30 p-5 backdrop-blur-xl lg:block">
          <ShellBrand title={title} subtitle={subtitle} badge={badge} />
          <ShellNav items={items} pathname={pathname} />
          <AccountBlock email={user?.email} onSignOut={() => void signOut()} />
        </aside>

        <div className="flex min-w-0 flex-1 flex-col">
          <header className="sticky top-0 z-40 border-b border-white/10 bg-zinc-950/75 px-4 py-3 backdrop-blur-xl lg:hidden">
            <div className="flex items-center justify-between gap-3">
              <div>
                <p className="text-xs uppercase tracking-[0.24em] text-amber-300">
                  Lolipants
                </p>
                <p className="text-sm font-medium text-zinc-100">
                  {current ? t(current.labelKey ?? "", current.label) : title}
                </p>
              </div>
              <div className="flex items-center gap-2">
                <LanguageToggle />
                <Button variant="secondary" onClick={() => setOpen(true)}>
                  {t("common.menu")}
                </Button>
              </div>
            </div>
          </header>

          <main className="mx-auto w-full max-w-7xl flex-1 px-4 py-6 sm:px-6 lg:px-8 lg:py-8">
            {children}
          </main>
        </div>
      </div>

      {open && (
        <div className="fixed inset-0 z-50 bg-black/70 p-3 backdrop-blur-sm lg:hidden">
          <div className="flex h-full max-w-sm flex-col rounded-2xl border border-white/10 bg-zinc-950 p-5 shadow-2xl">
            <div className="flex items-start justify-between gap-4">
              <ShellBrand title={title} subtitle={subtitle} badge={badge} compact />
              <Button variant="ghost" onClick={() => setOpen(false)}>
                {t("common.close")}
              </Button>
            </div>
            <div className="mt-6 flex-1 overflow-auto">
              <ShellNav
                items={items}
                pathname={pathname}
                onNavigate={() => setOpen(false)}
              />
            </div>
            <AccountBlock email={user?.email} onSignOut={() => void signOut()} />
          </div>
        </div>
      )}
    </div>
  );
}

function ShellBrand({
  title,
  subtitle,
  badge,
  compact,
}: {
  title: string;
  subtitle: string;
  badge?: string;
  compact?: boolean;
}) {
  return (
    <div className={compact ? "" : "mb-8"}>
      <div className="mb-4 inline-flex h-11 w-11 items-center justify-center rounded-2xl bg-amber-400 text-lg font-bold text-zinc-950 shadow-lg shadow-amber-950/30">
        <Image
          src="/lolipants.jpg"
          alt="Lolipants"
          width={44}
          height={44}
          className="h-11 w-11 rounded-2xl object-cover"
          priority
        />
      </div>
      <p className="text-xs uppercase tracking-[0.28em] text-amber-300">Lolipants</p>
      <h1 className="mt-1 text-xl font-semibold text-zinc-50">{title}</h1>
      <p className="mt-1 text-sm text-zinc-500">{subtitle}</p>
      {badge && (
        <span className="mt-3 inline-flex rounded-full border border-amber-400/30 bg-amber-400/15 px-2.5 py-1 text-xs text-amber-200">
          {badge}
        </span>
      )}
    </div>
  );
}

function ShellNav({
  items,
  pathname,
  onNavigate,
}: {
  items: ShellNavItem[];
  pathname: string;
  onNavigate?: () => void;
}) {
  const { t } = useI18n();
  const groups = items.reduce<Record<string, ShellNavItem[]>>((acc, item) => {
    const key = item.group ?? "main";
    acc[key] = [...(acc[key] ?? []), item];
    return acc;
  }, {});

  return (
    <nav className="space-y-6">
      {Object.entries(groups).map(([group, groupItems]) => (
        <div key={group}>
          <p className="mb-2 px-3 text-xs font-medium uppercase tracking-[0.2em] text-zinc-600">
            {t(`nav.groups.${group}`, t("nav.groups.main"))}
          </p>
          <div className="space-y-1">
            {groupItems.map((item) => {
              const active =
                pathname === item.href || pathname.startsWith(`${item.href}/`);
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  onClick={onNavigate}
                  className={cn(
                    "block rounded-xl px-3 py-2.5 text-sm transition",
                    active
                      ? "bg-amber-400 text-zinc-950 shadow-lg shadow-amber-950/20"
                      : "text-zinc-300 hover:bg-white/[0.06] hover:text-zinc-50",
                  )}
                >
                  {t(item.labelKey ?? "", item.label)}
                </Link>
              );
            })}
          </div>
        </div>
      ))}
    </nav>
  );
}

function AccountBlock({
  email,
  onSignOut,
}: {
  email?: string;
  onSignOut: () => void;
}) {
  const { t } = useI18n();
  return (
    <div className="mt-8 rounded-2xl border border-white/10 bg-white/[0.03] p-4">
      <p className="text-xs text-zinc-500">{t("common.signedInAs")}</p>
      <p className="mt-1 truncate text-sm text-zinc-200">
        {email ?? t("common.dashboardUser")}
      </p>
      <LanguageToggle className="mt-4 w-full" />
      <Button variant="secondary" className="mt-4 w-full" onClick={onSignOut}>
        {t("common.signOut")}
      </Button>
    </div>
  );
}
