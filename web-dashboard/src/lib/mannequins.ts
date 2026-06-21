import { catalogCdnBaseUrl } from "./config";

export type MannequinGenderLane = "women" | "men";

export type MannequinDef = {
  id: string;
  label: string;
  genderLane: MannequinGenderLane;
  path: string;
};

export const fallbackMannequins: MannequinDef[] = [
  {
    id: "petite_female",
    label: "Petite (Female)",
    genderLane: "women",
    path: "/mannequins/petite_female.svg",
  },
  {
    id: "standard_female",
    label: "Standard (Female)",
    genderLane: "women",
    path: "/mannequins/standard_female.svg",
  },
  {
    id: "standard_male",
    label: "Standard (Male)",
    genderLane: "men",
    path: "/mannequins/standard_male.svg",
  },
  {
    id: "slim_male",
    label: "Slim (Male)",
    genderLane: "men",
    path: "/mannequins/slim_male.svg",
  },
];

export function cmsRowsToMannequins(rows: Record<string, unknown>[]): MannequinDef[] {
  return rows
    .map((row) => {
      if (row.is_active === 0 || row.isActive === false) return null;
      const id = String(row.id ?? "").trim();
      const label = String(row.label_en ?? row.labelEn ?? id).trim();
      const path = resolveCatalogImageUrl(
        String(row.preview_url ?? row.previewUrl ?? "").trim(),
      );
      if (!id || !path) return null;
      return {
        id,
        label: label || id,
        genderLane: inferGenderLane([id, label]),
        path,
      } satisfies MannequinDef;
    })
    .filter((row): row is MannequinDef => row !== null);
}

export function resolveCatalogImageUrl(pathOrUrl: string): string {
  const value = pathOrUrl.trim();
  if (!value) return "";
  if (value.startsWith("http://") || value.startsWith("https://")) return value;
  if (value.startsWith("/")) return value;
  if (value.startsWith("assets/images/")) {
    const base = catalogCdnBaseUrl();
    const relative = value.slice("assets/images/".length);
    if (base) return `${base}/catalog/${relative}`;
    if (relative.startsWith("mannequins/")) {
      return `/${relative.replace(/\.png$/i, ".svg")}`;
    }
    return "";
  }
  return value;
}

export function defaultMannequinForGender(
  genderLane: string,
  options: MannequinDef[] = fallbackMannequins,
): string {
  const lane = genderLane.trim().toLowerCase();
  const target: MannequinGenderLane = lane === "men" || lane === "male" ? "men" : "women";
  return options.find((m) => m.genderLane === target)?.id ?? fallbackMannequins[1].id;
}

export function inferGenderLane(values: Array<unknown>): MannequinGenderLane {
  const text = values
    .filter((value) => value !== null && value !== undefined)
    .map(String)
    .join(" ")
    .toLowerCase();
  if (text.includes("men") || text.includes("male") || text.includes("thobe")) {
    return "men";
  }
  return "women";
}

export function mannequinById(
  id: string,
  options: MannequinDef[] = fallbackMannequins,
): MannequinDef {
  return options.find((m) => m.id === id) ?? options[0] ?? fallbackMannequins[1];
}
