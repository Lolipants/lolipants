import { Hono } from "hono";
import { cors } from "hono/cors";
import { logger } from "hono/logger";
import { apiError } from "./lib/http";
import { adminRoutes } from "./routes/admin";
import { aiRoutes } from "./routes/ai";
import { bookingRoutes } from "./routes/bookings";
import { catalogRoutes } from "./routes/catalog";
import { communityRoutes } from "./routes/community";
import { complaintRoutes } from "./routes/complaints";
import { roleRequestRoutes } from "./routes/roleRequests";
import { deliveryRoutes } from "./routes/delivery";
import { designerRoutes } from "./routes/designers";
import { designRoutes } from "./routes/designs";
import { fabricRoutes } from "./routes/fabrics";
import { measurementRoutes } from "./routes/measurements";
import { mannequinRoutes } from "./routes/mannequins";
import { orderRoutes } from "./routes/orders";
import { tailorPricingRoutes } from "./routes/tailorPricing";
import { tailorWeddingPricingRoutes } from "./routes/tailorWeddingPricing";
import { weddingRoutes } from "./routes/wedding";
import { accessoryRoutes } from "./routes/accessories";
import { paymentRoutes } from "./routes/payments";
import { postRoutes } from "./routes/posts";
import { newsRoutes } from "./routes/news";
import { configuratorRoutes } from "./routes/configurator";
import { presetRoutes } from "./routes/presets";
import { showcaseRoutes } from "./routes/showcase";
import { uploadRoutes } from "./routes/uploads";
import { userRoutes } from "./routes/users";
import type { AppVariables, Env } from "./types";

const app = new Hono<{ Bindings: Env; Variables: AppVariables }>();
const throttleStore = new Map<string, { count: number; windowStart: number }>();
const THROTTLE_WINDOW_MS = 60_000;
const THROTTLE_LIMIT = 20;

function allowedOriginsForEnv(env: Env): string[] {
  const configured = env.APP_ALLOWED_ORIGINS?.trim();
  if (configured) {
    return configured
      .split(",")
      .map((o) => o.trim())
      .filter((o) => o.length > 0);
  }
  if (env.ENVIRONMENT === "production") return ["https://lolipants.com"];
  return ["*"];
}

app.use(
  "*",
  async (c, next) => {
    const origins = allowedOriginsForEnv(c.env);
    return cors({
      origin:
        origins.length === 1 && origins[0] === "*"
          ? "*"
          : (origin) => (origin && origins.includes(origin) ? origin : origins[0]),
      allowMethods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
      allowHeaders: ["Content-Type", "Authorization", "X-Idempotency-Key"],
    })(c, next);
  },
);
app.use("/ai/*", async (c, next) => {
  const key = `${c.req.header("cf-connecting-ip") ?? "unknown"}:${c.req.path}`;
  const now = Date.now();
  const entry = throttleStore.get(key);
  if (!entry || now - entry.windowStart > THROTTLE_WINDOW_MS) {
    throttleStore.set(key, { count: 1, windowStart: now });
    await next();
    return;
  }
  if (entry.count >= THROTTLE_LIMIT) {
    return apiError(c, 429, "RATE_LIMITED", "Too many requests, try again later");
  }
  entry.count++;
  await next();
});
app.use("/upload/*", async (c, next) => {
  const key = `${c.req.header("cf-connecting-ip") ?? "unknown"}:${c.req.path}`;
  const now = Date.now();
  const entry = throttleStore.get(key);
  if (!entry || now - entry.windowStart > THROTTLE_WINDOW_MS) {
    throttleStore.set(key, { count: 1, windowStart: now });
    await next();
    return;
  }
  if (entry.count >= THROTTLE_LIMIT) {
    return apiError(c, 429, "RATE_LIMITED", "Too many requests, try again later");
  }
  entry.count++;
  await next();
});
app.use("*", async (c, next) => {
  const started = Date.now();
  await next();
  console.info(
    JSON.stringify({
      method: c.req.method,
      path: c.req.path,
      status: c.res.status,
      elapsedMs: Date.now() - started,
    }),
  );
});
app.use("*", logger());

/** Return JSON (not HTML) on uncaught errors so mobile clients can parse [error.message]. */
app.onError((err, c) => {
  console.error("[unhandled]", err);
  return c.json(
    {
      error: {
        code: "INTERNAL",
        message: err instanceof Error ? err.message : String(err),
        status: 500,
      },
    },
    500,
  );
});

app.get("/health", (c) => c.json({ status: "ok", env: c.env.ENVIRONMENT }));

app.route("/designs", designRoutes);
app.route("/orders", orderRoutes);
app.route("/tailor/pricing", tailorPricingRoutes);
app.route("/tailor/wedding-pricing", tailorWeddingPricingRoutes);
app.route("/wedding", weddingRoutes);
app.route("/accessories", accessoryRoutes);
app.route("/payments", paymentRoutes);
app.route("/mannequins", mannequinRoutes);
app.route("/fabrics", fabricRoutes);
app.route("/presets", presetRoutes);
app.route("/configurator", configuratorRoutes);
app.route("/catalog", catalogRoutes);
app.route("/measurements", measurementRoutes);
app.route("/posts", postRoutes);
app.route("/news", newsRoutes);
app.route("/community", communityRoutes);
app.route("/designers", designerRoutes);
app.route("/showcase", showcaseRoutes);
app.route("/bookings", bookingRoutes);
app.route("/upload", uploadRoutes);
app.route("/ai", aiRoutes);
app.route("/users", userRoutes);
app.route("/delivery", deliveryRoutes);
app.route("/complaints", complaintRoutes);
app.route("/role-requests", roleRequestRoutes);
app.route("/admin", adminRoutes);

export default app;
