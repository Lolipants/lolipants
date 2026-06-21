"use client";

import { useI18n } from "./I18nProvider";

export function cn(...classes: Array<string | false | null | undefined>) {
  return classes.filter(Boolean).join(" ");
}

export function PageHeader({
  title,
  subtitle,
  actions,
}: {
  title: string;
  subtitle?: string;
  actions?: React.ReactNode;
}) {
  const { t } = useI18n();
  return (
    <div className="mb-6 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
      <div>
        <p className="mb-2 text-xs font-medium uppercase tracking-[0.28em] text-amber-300/80">
          {t("common.operations")}
        </p>
        <h1 className="text-3xl font-semibold tracking-tight text-zinc-50">{title}</h1>
        {subtitle && <p className="mt-2 max-w-2xl text-sm text-zinc-400">{subtitle}</p>}
      </div>
      {actions && <div className="flex flex-wrap gap-2">{actions}</div>}
    </div>
  );
}

export function Card({
  children,
  className,
}: {
  children: React.ReactNode;
  className?: string;
}) {
  return <Panel className={className}>{children}</Panel>;
}

export function Panel({
  children,
  className,
}: {
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <div
      className={cn(
        "rounded-2xl border border-white/10 bg-zinc-950/70 p-5 shadow-2xl shadow-black/20 backdrop-blur",
        "ring-1 ring-white/[0.03]",
        className,
      )}
    >
      {children}
    </div>
  );
}

export function SectionHeader({
  title,
  subtitle,
  action,
}: {
  title: string;
  subtitle?: string;
  action?: React.ReactNode;
}) {
  return (
    <div className="mb-4 flex items-center justify-between gap-4">
      <div>
        <h2 className="text-base font-semibold text-zinc-100">{title}</h2>
        {subtitle && <p className="mt-1 text-sm text-zinc-500">{subtitle}</p>}
      </div>
      {action}
    </div>
  );
}

export function Button({
  variant = "primary",
  className,
  children,
  ...props
}: React.ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: "primary" | "secondary" | "ghost" | "danger";
}) {
  const variants = {
    primary:
      "bg-amber-400 text-zinc-950 shadow-lg shadow-amber-950/20 hover:bg-amber-300",
    secondary:
      "border border-white/10 bg-white/[0.04] text-zinc-100 hover:bg-white/[0.08]",
    ghost: "text-zinc-300 hover:bg-white/[0.06] hover:text-zinc-50",
    danger:
      "border border-red-500/30 bg-red-950/40 text-red-100 hover:bg-red-900/50",
  };
  return (
    <button
      {...props}
      className={cn(
        "inline-flex items-center justify-center rounded-xl px-4 py-2 text-sm font-medium transition disabled:cursor-not-allowed disabled:opacity-55",
        "focus:outline-none focus:ring-2 focus:ring-amber-300/60 focus:ring-offset-2 focus:ring-offset-zinc-950",
        variants[variant],
        className,
      )}
    >
      {children}
    </button>
  );
}

const fieldClass =
  "w-full rounded-xl border border-white/10 bg-zinc-950/70 px-3 py-2 text-sm text-zinc-100 outline-none transition placeholder:text-zinc-600 focus:border-amber-300/60 focus:ring-2 focus:ring-amber-300/20 disabled:opacity-60";

export function Input(props: React.InputHTMLAttributes<HTMLInputElement>) {
  return <input {...props} className={cn(fieldClass, props.className)} />;
}

export function Select(props: React.SelectHTMLAttributes<HTMLSelectElement>) {
  return <select {...props} className={cn(fieldClass, props.className)} />;
}

export function Textarea(props: React.TextareaHTMLAttributes<HTMLTextAreaElement>) {
  return <textarea {...props} className={cn(fieldClass, props.className)} />;
}

export function CheckboxField({
  label,
  checked,
  onChange,
}: {
  label: string;
  checked: boolean;
  onChange: (checked: boolean) => void;
}) {
  return (
    <label className="flex items-center gap-2 text-sm text-zinc-300">
      <input
        type="checkbox"
        checked={checked}
        onChange={(e) => onChange(e.target.checked)}
        className="h-4 w-4 rounded border-white/20 bg-zinc-950 accent-amber-400"
      />
      {label}
    </label>
  );
}

export function Badge({
  children,
  tone = "neutral",
}: {
  children: React.ReactNode;
  tone?: "neutral" | "success" | "warning" | "danger" | "info" | "gold";
}) {
  const tones = {
    neutral: "border-zinc-700 bg-zinc-900 text-zinc-300",
    success: "border-emerald-500/30 bg-emerald-950/40 text-emerald-200",
    warning: "border-amber-500/30 bg-amber-950/40 text-amber-200",
    danger: "border-red-500/30 bg-red-950/40 text-red-200",
    info: "border-sky-500/30 bg-sky-950/40 text-sky-200",
    gold: "border-amber-400/30 bg-amber-400/15 text-amber-200",
  };
  return (
    <span
      className={cn(
        "inline-flex items-center rounded-full border px-2.5 py-1 text-xs font-medium",
        tones[tone],
      )}
    >
      {children}
    </span>
  );
}

export function StatusBadge({ status }: { status: unknown }) {
  const value = String(status ?? "unknown").replaceAll("_", " ");
  const normalized = value.toLowerCase();
  const { td } = useI18n();
  const tone =
    normalized.includes("cancel") || normalized.includes("ban")
      ? "danger"
      : normalized.includes("deliver") ||
          normalized.includes("complete") ||
          normalized.includes("active")
        ? "success"
        : normalized.includes("pending") ||
            normalized.includes("placed") ||
            normalized.includes("review")
          ? "warning"
          : normalized.includes("ready") || normalized.includes("ship")
            ? "info"
            : "neutral";
  return <Badge tone={tone}>{td("status", status, value)}</Badge>;
}

export function MetricCard({
  label,
  value,
  detail,
}: {
  label: string;
  value: string | number;
  detail?: string;
}) {
  return (
    <Panel className="bg-gradient-to-br from-zinc-900/90 to-zinc-950">
      <p className="text-sm text-zinc-500">{label}</p>
      <p className="mt-3 text-3xl font-semibold tracking-tight text-zinc-50">{value}</p>
      {detail && <p className="mt-2 text-xs text-zinc-500">{detail}</p>}
    </Panel>
  );
}

export function ErrorBanner({ message }: { message: string }) {
  return (
    <div className="mb-4 rounded-xl border border-red-500/30 bg-red-950/40 px-4 py-3 text-sm text-red-100">
      {message}
    </div>
  );
}

export function EmptyState({
  title,
  description,
}: {
  title?: string;
  description?: string;
}) {
  const { t } = useI18n();
  return (
    <div className="rounded-2xl border border-dashed border-white/10 bg-white/[0.02] px-6 py-10 text-center">
      <p className="font-medium text-zinc-200">{title ?? t("common.nothingHere")}</p>
      {description && <p className="mt-1 text-sm text-zinc-500">{description}</p>}
    </div>
  );
}

export function LoadingState({ label }: { label?: string }) {
  const { t } = useI18n();
  return (
    <div className="rounded-2xl border border-white/10 bg-white/[0.02] px-6 py-8 text-sm text-zinc-400">
      {label ?? t("common.loading")}
    </div>
  );
}

export function Drawer({
  title,
  subtitle,
  children,
  footer,
  onClose,
}: {
  title: string;
  subtitle?: string;
  children: React.ReactNode;
  footer?: React.ReactNode;
  onClose: () => void;
}) {
  const { t } = useI18n();
  return (
    <div className="fixed inset-0 z-50 flex justify-end bg-black/70 p-3 backdrop-blur-sm">
      <div className="flex h-full w-full max-w-xl flex-col rounded-2xl border border-white/10 bg-zinc-950 shadow-2xl">
        <div className="border-b border-white/10 p-5">
          <div className="flex items-start justify-between gap-4">
            <div>
              <h2 className="text-lg font-semibold text-zinc-50">{title}</h2>
              {subtitle && <p className="mt-1 text-sm text-zinc-500">{subtitle}</p>}
            </div>
            <Button variant="ghost" onClick={onClose}>
              {t("common.close")}
            </Button>
          </div>
        </div>
        <div className="flex-1 overflow-auto p-5">{children}</div>
        {footer && <div className="border-t border-white/10 p-5">{footer}</div>}
      </div>
    </div>
  );
}

export type DataTableColumn = {
  key: string;
  label: string;
  render?: (row: Record<string, unknown>) => React.ReactNode;
};

export function DataTable({
  columns,
  rows,
  onRowClick,
  emptyTitle,
  emptyDescription,
}: {
  columns: DataTableColumn[];
  rows: Record<string, unknown>[];
  onRowClick?: (row: Record<string, unknown>) => void;
  emptyTitle?: string;
  emptyDescription?: string;
}) {
  const { t } = useI18n();
  if (rows.length === 0) {
    return (
      <EmptyState
        title={emptyTitle ?? t("common.noRows")}
        description={emptyDescription}
      />
    );
  }

  return (
    <div className="overflow-hidden rounded-2xl border border-white/10 bg-zinc-950/70 shadow-2xl shadow-black/10">
      <div className="overflow-x-auto">
        <table className="min-w-full text-start text-sm">
          <thead className="bg-white/[0.03] text-xs uppercase tracking-wide text-zinc-500">
            <tr>
              {columns.map((c) => (
                <th key={c.key} className="px-4 py-3 font-medium">
                  {c.label}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {rows.map((row, i) => (
              <tr
                key={String(row.id ?? i)}
                className={cn(
                  "border-t border-white/10 transition",
                  onRowClick && "cursor-pointer hover:bg-white/[0.04]",
                )}
                onClick={() => onRowClick?.(row)}
              >
                {columns.map((c) => (
                  <td key={c.key} className="px-4 py-3 text-zinc-200">
                    {c.render
                      ? c.render(row)
                      : String(
                          row[c.key] ??
                            row[c.key.replace(/([A-Z])/g, "_$1").toLowerCase()] ??
                            "—",
                        )}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
