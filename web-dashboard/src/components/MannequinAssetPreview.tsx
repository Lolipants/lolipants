"use client";

/* eslint-disable @next/next/no-img-element -- Local object URLs are not compatible with next/image. */

import { useEffect, useMemo, useState } from "react";
import { useI18n } from "./I18nProvider";
import { fallbackMannequins, mannequinById, type MannequinDef } from "@/lib/mannequins";

export function MannequinAssetPreview({
  file,
  existingUrl,
  mannequinId,
  onMannequinChange,
  onFileChange,
  onClear,
  onConfirm,
  uploadConfirmed,
  uploading,
  layerPreview = false,
  mannequins = fallbackMannequins,
}: {
  file: File | null;
  existingUrl?: string;
  mannequinId: string;
  mannequins?: MannequinDef[];
  onMannequinChange: (id: string) => void;
  onFileChange: (file: File) => void;
  onClear: () => void;
  onConfirm?: () => void;
  uploadConfirmed?: boolean;
  uploading?: boolean;
  layerPreview?: boolean;
}) {
  const { t } = useI18n();
  const [objectUrl, setObjectUrl] = useState("");
  const options = mannequins.length > 0 ? mannequins : fallbackMannequins;
  const selected = mannequinById(mannequinId, options);
  const fallbackBody =
    fallbackMannequins.find((m) => m.genderLane === selected.genderLane) ??
    fallbackMannequins[1];
  const [bodySrc, setBodySrc] = useState(selected.path || fallbackBody.path);

  useEffect(() => {
    if (!file) {
      setObjectUrl("");
      return;
    }
    const url = URL.createObjectURL(file);
    setObjectUrl(url);
    return () => URL.revokeObjectURL(url);
  }, [file]);

  useEffect(() => {
    setBodySrc(selected.path || fallbackBody.path);
  }, [selected.path, fallbackBody.path]);

  const previewUrl = objectUrl || existingUrl || "";
  const hasPreview = previewUrl.length > 0;
  const inputId = useMemo(
    () => `asset-preview-${Math.random().toString(36).slice(2)}`,
    [],
  );

  return (
    <div className="rounded-xl border border-zinc-800 bg-zinc-950/60 p-4">
      <div className="mb-3">
        <p className="text-sm font-medium text-zinc-100">{t("preview.title")}</p>
        <p className="text-xs text-zinc-500">
          {t("preview.description")}
        </p>
      </div>
      <div className="mb-3 flex flex-wrap gap-2">
        {options.map((m) => (
          <button
            key={m.id}
            type="button"
            onClick={() => onMannequinChange(m.id)}
            disabled={uploading}
            className={`rounded-full px-3 py-1 text-xs ${
              m.id === selected.id
                ? "bg-amber-500 text-zinc-950"
                : "border border-zinc-700 text-zinc-300"
            }`}
          >
            {fallbackLabel(m, t)}
          </button>
        ))}
      </div>
      <div className="relative flex h-80 items-end justify-center overflow-hidden rounded-lg bg-zinc-900">
        <img
          src={bodySrc}
          alt={selected.label}
          onError={() => setBodySrc(fallbackBody.path)}
          className="absolute bottom-0 left-1/2 h-full w-auto max-w-none -translate-x-1/2 opacity-80"
        />
        {hasPreview ? (
          <img
            src={previewUrl}
            alt={t("preview.selectedUploadAlt")}
            className={
              layerPreview
                ? "absolute bottom-0 left-1/2 z-10 h-full w-auto max-w-none -translate-x-1/2"
                : "relative z-10 h-full max-w-[72%] object-contain object-bottom"
            }
          />
        ) : (
          <div className="relative z-10 rounded border border-dashed border-zinc-700 px-4 py-3 text-sm text-zinc-500">
            {t("preview.empty")}
          </div>
        )}
      </div>
      <div className="mt-3 flex flex-wrap items-center gap-2">
        <label
          htmlFor={inputId}
          className="cursor-pointer rounded border border-zinc-700 px-3 py-2 text-sm text-zinc-200 hover:bg-zinc-900"
        >
          {hasPreview ? t("common.replaceImage") : t("common.chooseImage")}
        </label>
        <input
          id={inputId}
          type="file"
          accept="image/*"
          className="hidden"
          disabled={uploading}
          onChange={(e) => {
            const next = e.target.files?.[0];
            if (next) onFileChange(next);
            e.currentTarget.value = "";
          }}
        />
        {file && onConfirm && (
          <button
            type="button"
            onClick={onConfirm}
            disabled={uploading}
            className="rounded bg-amber-500 px-3 py-2 text-sm font-medium text-zinc-950 disabled:opacity-60"
          >
            {uploading
              ? t("preview.uploading")
              : uploadConfirmed
                ? t("preview.uploadConfirmed")
                : t("preview.confirmUpload")}
          </button>
        )}
        {hasPreview && (
          <button
            type="button"
            onClick={onClear}
            disabled={uploading}
            className="rounded px-3 py-2 text-sm text-zinc-400 hover:text-zinc-100"
          >
            {t("common.remove")}
          </button>
        )}
      </div>
    </div>
  );
}

function fallbackLabel(mannequin: MannequinDef, t: (key: string, fallback?: string) => string) {
  const labels: Record<string, string> = {
    petite_female: "Petite (Female)",
    standard_female: "Standard (Female)",
    standard_male: "Standard (Male)",
    slim_male: "Slim (Male)",
  };
  if (!(mannequin.id in labels)) return mannequin.label;
  return t(`mannequins.${mannequin.id}`, mannequin.label);
}
