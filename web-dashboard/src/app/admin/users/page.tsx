"use client";

import { useCallback, useEffect, useState } from "react";
import { adminApi } from "@/lib/admin-api";
import { AdminScopes } from "@/lib/types";
import {
  Badge,
  Button,
  CheckboxField,
  DataTable,
  Drawer,
  ErrorBanner,
  Input,
  LoadingState,
  PageHeader,
  Panel,
  Select,
  StatusBadge,
} from "@/components/ui";
import { RequireRole } from "@/components/RequireRole";
import { useI18n } from "@/components/I18nProvider";

const ALL_SCOPES = Object.values(AdminScopes);

export default function AdminUsersPage() {
  const { t, td } = useI18n();
  const [rows, setRows] = useState<Record<string, unknown>[]>([]);
  const [error, setError] = useState("");
  const [selected, setSelected] = useState<Record<string, unknown> | null>(null);
  const [role, setRole] = useState("user");
  const [scopes, setScopes] = useState<string[]>([]);
  const [saving, setSaving] = useState(false);
  const [query, setQuery] = useState("");
  const [roleFilter, setRoleFilter] = useState("all");

  const load = useCallback(() => {
    adminApi
      .listUsers()
      .then(setRows)
      .catch((e: { message?: string }) => setError(e.message ?? t("admin.users.loadError")));
  }, [t]);

  useEffect(() => {
    load();
  }, [load]);

  function openEdit(row: Record<string, unknown>) {
    setSelected(row);
    setRole(String(row.role ?? "user"));
    const raw = row.adminScopes ?? row.admin_scopes;
    setScopes(Array.isArray(raw) ? raw.map(String) : []);
  }

  async function save() {
    if (!selected?.id) return;
    setSaving(true);
    setError("");
    try {
      await adminApi.patchUser(String(selected.id), {
        role,
        adminScopes: role === "admin" ? scopes : [],
      });
      setSelected(null);
      load();
    } catch (e) {
      setError((e as { message?: string }).message ?? t("admin.cms.saveFailed"));
    } finally {
      setSaving(false);
    }
  }

  const filteredRows = rows.filter((r) => {
    const text = `${String(r.name ?? "")} ${String(r.email ?? "")}`.toLowerCase();
    const roleValue = String(r.role ?? "user");
    return (
      text.includes(query.toLowerCase()) &&
      (roleFilter === "all" || roleValue === roleFilter)
    );
  });

  const tableRows = filteredRows.map((r) => ({
    ...r,
    id: r.id,
    name: r.name,
    email: r.email,
    role: r.role,
    banned: r.banned_at ? "banned" : "active",
  }));

  return (
    <RequireRole role="admin" scope={AdminScopes.usersMgmt}>
      <PageHeader title={t("admin.users.title")} subtitle={t("admin.users.subtitle")} />
      {error && <ErrorBanner message={error} />}
      <Panel className="mb-5">
        <div className="grid gap-3 md:grid-cols-[1fr_220px]">
          <Input
            placeholder={t("admin.users.searchPlaceholder")}
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
          <Select value={roleFilter} onChange={(e) => setRoleFilter(e.target.value)}>
            <option value="all">{t("admin.users.allRoles")}</option>
            {["user", "tailor", "delivery", "admin"].map((r) => (
              <option key={r} value={r}>{td("roles", r)}</option>
            ))}
          </Select>
        </div>
      </Panel>
      {rows.length === 0 && !error ? <LoadingState /> : (
        <DataTable
          emptyTitle={t("admin.users.emptyTitle")}
          emptyDescription={t("admin.users.emptyDescription")}
          columns={[
            { key: "name", label: t("admin.users.name") },
            { key: "email", label: t("common.email") },
            {
              key: "role",
              label: t("admin.users.role"),
              render: (row) => (
                <Badge tone={row.role === "admin" ? "gold" : "neutral"}>
                  {td("roles", row.role)}
                </Badge>
              ),
            },
            {
              key: "banned",
              label: t("orders.status"),
              render: (row) => <StatusBadge status={row.banned} />,
            },
          ]}
          rows={tableRows}
          onRowClick={openEdit}
        />
      )}
      {selected && (
        <Drawer
          title={t("admin.users.editUser")}
          subtitle={String(selected.email)}
          onClose={() => setSelected(null)}
          footer={
            <div className="flex gap-2">
              <Button type="button" onClick={save} disabled={saving}>
                {saving ? t("common.saving") : t("admin.users.saveChanges")}
              </Button>
              <Button type="button" variant="secondary" onClick={() => setSelected(null)}>
                {t("common.cancel")}
              </Button>
            </div>
          }
        >
          <div className="space-y-5">
            <label className="block text-sm text-zinc-300">
              {t("admin.users.role")}
              <Select
                value={role}
                onChange={(e) => setRole(e.target.value)}
                className="mt-2"
              >
                {["user", "tailor", "delivery", "admin"].map((r) => (
                  <option key={r} value={r}>{td("roles", r)}</option>
                ))}
              </Select>
            </label>
            {role === "admin" && (
              <div>
                <p className="text-sm font-medium text-zinc-200">{t("admin.users.adminScopes")}</p>
                <p className="mt-1 text-sm text-zinc-500">
                  {t("admin.users.adminScopesDescription")}
                </p>
                <div className="mt-3 grid gap-2 sm:grid-cols-2">
                  {ALL_SCOPES.map((s) => (
                    <CheckboxField
                      key={s}
                      label={td("adminScopes", s)}
                        checked={scopes.includes(s)}
                      onChange={(checked) =>
                          setScopes((prev) =>
                          checked ? [...prev, s] : prev.filter((x) => x !== s),
                          )
                        }
                    />
                  ))}
                </div>
              </div>
            )}
          </div>
        </Drawer>
      )}
    </RequireRole>
  );
}
