export type Env = {
  DB: D1Database;
  R2: R2Bucket;
  AUTH_SERVICE: Fetcher;
  BETTER_AUTH_BASE_URL: string;
  OPENAI_API_KEY: string;
  /** Google AI Studio key for Gemini native image generation (design-render refinement). */
  GEMINI_API_KEY?: string;
  /** Defaults to gemini-2.5-flash-image when GEMINI_API_KEY is set. */
  GEMINI_IMAGE_MODEL?: string;
  /** OpenAI Images model for design-render fallback (defaults to gpt-image-1). */
  OPENAI_IMAGE_MODEL?: string;
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
