export type UserRole = "user" | "tailor" | "delivery" | "admin";

export const AdminScopes = {
  superAdmin: "*",
  usersMgmt: "users_mgmt",
  ordersOversight: "orders_oversight",
  payouts: "payouts",
  moderation: "moderation",
  cms: "cms",
  complaints: "complaints",
  tailorMgmt: "tailor_mgmt",
  deliveryMgmt: "delivery_mgmt",
  news: "news",
} as const;

export type AdminScope = (typeof AdminScopes)[keyof typeof AdminScopes];

export type DashboardUser = {
  id: string;
  name: string;
  email: string;
  role: UserRole;
  adminScopes: string[];
  imageUrl?: string;
};

export type ApiError = {
  code?: string;
  message: string;
  status: number;
};

export type OrderRow = {
  id: string;
  status: string;
  userId?: string;
  tailorId?: string;
  courierId?: string;
  totalAmount?: number;
  createdAt?: string;
  garmentType?: string;
  customerName?: string;
  [key: string]: unknown;
};
