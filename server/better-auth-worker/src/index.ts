import { drizzle } from "drizzle-orm/d1";
import { Hono } from "hono";
import { cors } from "hono/cors";
import { createAuth } from "./auth";
import * as schema from "./db/schema";

type Bindings = {
  DB: D1Database;
  BETTER_AUTH_SECRET: string;
  BETTER_AUTH_URL?: string;
  TRUSTED_ORIGINS?: string;
  AWS_ACCESS_KEY_ID?: string;
  AWS_SECRET_ACCESS_KEY?: string;
  AWS_SESSION_TOKEN?: string;
  AWS_SES_REGION?: string;
  RESET_FROM_EMAIL?: string;
  APP_NAME?: string;
};

const app = new Hono<{ Bindings: Bindings }>();

app.use(
  "/auth/*",
  cors({
    origin: (origin, c) => {
      const configured = c.env.TRUSTED_ORIGINS?.split(",")
        .map((x: string) => x.trim())
        .filter((x: string) => x.length > 0);
      if (!configured || configured.length === 0) {
        return origin || "*";
      }
      if (!origin) {
        return configured[0]!;
      }
      return configured.includes(origin) ? origin : configured[0]!;
    },
    allowMethods: ["GET", "POST", "OPTIONS"],
    allowHeaders: ["Content-Type", "Authorization"],
    exposeHeaders: ["set-auth-token"],
  }),
);

app.on(["GET", "POST", "OPTIONS"], "/auth/*", async (c) => {
  const db = drizzle(c.env.DB, { schema });
  const baseURL = c.env.BETTER_AUTH_URL ?? new URL(c.req.url).origin;
  const trustedOrigins = (c.env.TRUSTED_ORIGINS ?? "")
    .split(",")
    .map((x) => x.trim())
    .filter((x) => x.length > 0);

  const auth = createAuth({
    db,
    secret: c.env.BETTER_AUTH_SECRET,
    baseURL,
    trustedOrigins,
    awsAccessKeyId: c.env.AWS_ACCESS_KEY_ID,
    awsSecretAccessKey: c.env.AWS_SECRET_ACCESS_KEY,
    awsSessionToken: c.env.AWS_SESSION_TOKEN,
    awsSesRegion: c.env.AWS_SES_REGION ?? "us-east-1",
    resetFromEmail: c.env.RESET_FROM_EMAIL ?? "LOLIPANTS <no-reply@lolipants.com>",
    appName: c.env.APP_NAME ?? "LOLIPANTS",
  });

  return auth.handler(c.req.raw);
});

app.get("/", (c) =>
  c.json({
    ok: true,
    service: "lolipants-better-auth",
    authPath: "/auth",
  }),
);

export default app;
