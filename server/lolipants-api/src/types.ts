export type Env = {
  DB: D1Database;
  R2: R2Bucket;
  AUTH_SERVICE: Fetcher;
  BETTER_AUTH_BASE_URL: string;
  OPENAI_API_KEY: string;
  TAP_SECRET_KEY: string;
  ONESIGNAL_API_KEY: string;
  ONESIGNAL_APP_ID: string;
  CLOUDFLARE_R2_BASE_URL: string;
  ENVIRONMENT: string;
  APP_ALLOWED_ORIGINS?: string;
  ADMIN_HMAC_SECRET?: string;
  INTERNAL_SYNC_SECRET?: string;
};

export type AppVariables = {
  userId: string;
  userRole: string;
  adminScopes: string[];
};
