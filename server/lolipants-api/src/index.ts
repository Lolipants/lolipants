import { Hono } from "hono";
import { cors } from "hono/cors";
import { logger } from "hono/logger";
import { aiRoutes } from "./routes/ai";
import { bookingRoutes } from "./routes/bookings";
import { communityRoutes } from "./routes/community";
import { designRoutes } from "./routes/designs";
import { fabricRoutes } from "./routes/fabrics";
import { measurementRoutes } from "./routes/measurements";
import { orderRoutes } from "./routes/orders";
import { postRoutes } from "./routes/posts";
import { presetRoutes } from "./routes/presets";
import { uploadRoutes } from "./routes/uploads";
import { userRoutes } from "./routes/users";
import type { AppVariables, Env } from "./types";

const app = new Hono<{ Bindings: Env; Variables: AppVariables }>();

app.use(
  "*",
  cors({
    origin: "*",
    allowMethods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allowHeaders: ["Content-Type", "Authorization"],
  }),
);
app.use("*", logger());

app.get("/health", (c) => c.json({ status: "ok", env: c.env.ENVIRONMENT }));

app.route("/designs", designRoutes);
app.route("/orders", orderRoutes);
app.route("/fabrics", fabricRoutes);
app.route("/presets", presetRoutes);
app.route("/measurements", measurementRoutes);
app.route("/posts", postRoutes);
app.route("/community", communityRoutes);
app.route("/bookings", bookingRoutes);
app.route("/upload", uploadRoutes);
app.route("/ai", aiRoutes);
app.route("/users", userRoutes);

export default app;
