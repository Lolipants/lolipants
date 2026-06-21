import { apiFetch, apiUpload } from "./api";

export const adminApi = {
  stats: () => apiFetch<Record<string, unknown>>("/admin/stats"),
  listUsers: (query?: Record<string, string>) => {
    const q = query ? `?${new URLSearchParams(query)}` : "";
    return apiFetch<Record<string, unknown>[]>(`/admin/users${q}`);
  },
  patchUser: (id: string, body: Record<string, unknown>) =>
    apiFetch<Record<string, unknown>>(`/admin/users/${id}`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),
  listOrders: (status?: string) => {
    const q = status ? `?status=${encodeURIComponent(status)}` : "";
    return apiFetch<Record<string, unknown>[]>(`/admin/orders${q}`);
  },
  patchOrder: (id: string, body: Record<string, unknown>) =>
    apiFetch<Record<string, unknown>>(`/admin/orders/${id}`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),
  listPayouts: (status?: string) => {
    const q = status ? `?status=${encodeURIComponent(status)}` : "";
    return apiFetch<Record<string, unknown>[]>(`/admin/payouts${q}`);
  },
  patchPayout: (id: string, body: Record<string, unknown>) =>
    apiFetch<Record<string, unknown>>(`/admin/payouts/${id}`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),
  listComplaints: (status?: string) => {
    const q = status ? `?status=${encodeURIComponent(status)}` : "";
    return apiFetch<Record<string, unknown>[]>(`/admin/complaints${q}`);
  },
  patchComplaint: (id: string, body: Record<string, unknown>) =>
    apiFetch<Record<string, unknown>>(`/admin/complaints/${id}`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),
  listRoleRequests: (status?: string) => {
    const q = status ? `?status=${encodeURIComponent(status)}` : "";
    return apiFetch<Record<string, unknown>[]>(`/admin/role-requests${q}`);
  },
  patchRoleRequest: (id: string, body: Record<string, unknown>) =>
    apiFetch<Record<string, unknown>>(`/admin/role-requests/${id}`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),
  hidePost: (id: string) =>
    apiFetch<void>(`/admin/moderation/posts/${id}/hide`, { method: "PATCH", body: "{}" }),
  hideDesign: (id: string) =>
    apiFetch<void>(`/admin/moderation/designs/${id}/hide`, { method: "PATCH", body: "{}" }),
  listNews: () => apiFetch<Record<string, unknown>[]>("/admin/news"),
  createNews: (body: Record<string, unknown>) =>
    apiFetch<Record<string, unknown>>("/admin/news", {
      method: "POST",
      body: JSON.stringify(body),
    }),
  updateNews: (id: string, body: Record<string, unknown>) =>
    apiFetch<Record<string, unknown>>(`/admin/news/${id}`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),
  deleteNews: (id: string) =>
    apiFetch<void>(`/admin/news/${id}`, { method: "DELETE" }),
  uploadNewsAsset: (file: File) => {
    const form = new FormData();
    form.append("file", file);
    return apiUpload<{ url: string }>("/admin/upload/news-asset", form);
  },
  listCms: (resource: string) =>
    apiFetch<Record<string, unknown>[]>(`/admin/cms/${resource}`),
  createCms: (resource: string, body: Record<string, unknown>) =>
    apiFetch<Record<string, unknown>>(`/admin/cms/${resource}`, {
      method: "POST",
      body: JSON.stringify(body),
    }),
  updateCms: (resource: string, id: string, body: Record<string, unknown>) =>
    apiFetch<Record<string, unknown>>(`/admin/cms/${resource}/${id}`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),
  deleteCms: (resource: string, id: string) =>
    apiFetch<void>(`/admin/cms/${resource}/${id}`, { method: "DELETE" }),
  uploadCatalogAsset: (file: File, category: string) => {
    const form = new FormData();
    form.append("file", file);
    form.append("category", category);
    return apiUpload<{ url: string }>("/admin/upload/catalog-asset", form);
  },
  listConfigurator: (resource: string, query?: Record<string, string>) => {
    const q = query ? `?${new URLSearchParams(query)}` : "";
    return apiFetch<Record<string, unknown>[]>(`/admin/cms/configurator/${resource}${q}`);
  },
  createConfigurator: (resource: string, body: Record<string, unknown>) =>
    apiFetch<Record<string, unknown>>(`/admin/cms/configurator/${resource}`, {
      method: "POST",
      body: JSON.stringify(body),
    }),
  updateConfigurator: (resource: string, id: string, body: Record<string, unknown>) =>
    apiFetch<Record<string, unknown>>(`/admin/cms/configurator/${resource}/${id}`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),
  deleteConfigurator: (resource: string, id: string) =>
    apiFetch<void>(`/admin/cms/configurator/${resource}/${id}`, { method: "DELETE" }),
};
