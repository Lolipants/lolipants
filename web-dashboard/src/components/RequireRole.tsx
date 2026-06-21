"use client";

import { useRouter } from "next/navigation";
import { useEffect } from "react";
import { useAuth } from "./AuthProvider";
import { useI18n } from "./I18nProvider";
import { homeForRole, hasScope } from "@/lib/rbac";

export function RequireRole({
  role,
  scope,
  children,
}: {
  role: "admin" | "tailor";
  scope?: string;
  children: React.ReactNode;
}) {
  const { user, loading } = useAuth();
  const { t } = useI18n();
  const router = useRouter();

  useEffect(() => {
    if (loading) return;
    if (!user) {
      router.replace("/login");
      return;
    }
    if (user.role !== role) {
      router.replace(homeForRole(user));
      return;
    }
    if (scope && role === "admin" && !hasScope(user, scope)) {
      router.replace(homeForRole(user));
    }
  }, [user, loading, role, scope, router]);

  if (loading || !user || user.role !== role) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-zinc-950 text-zinc-300">
        {t("common.loading")}
      </div>
    );
  }

  return <>{children}</>;
}
