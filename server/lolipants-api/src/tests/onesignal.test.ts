/**
 * Unit coverage for the server-side OneSignal helper. We mock fetch to verify
 * the request shape, and confirm the helper no-ops when credentials are
 * missing so production traffic is never blocked by a misconfigured push
 * layer.
 */
import { afterEach, describe, expect, it, vi } from "vitest";
import { orderStatusTemplates, sendToUser } from "../lib/onesignal";
import type { Env } from "../types";

function makeEnv(overrides: Partial<Env> = {}): Env {
  return {
    ONESIGNAL_API_KEY: "test-key",
    ONESIGNAL_APP_ID: "test-app",
    DB: {} as Env["DB"],
    R2: {} as Env["R2"],
    AUTH_SERVICE: {} as Env["AUTH_SERVICE"],
    BETTER_AUTH_BASE_URL: "",
    OPENAI_API_KEY: "",
    TAP_SECRET_KEY: "",
    CLOUDFLARE_R2_BASE_URL: "",
    ENVIRONMENT: "test",
    ...overrides,
  } as Env;
}

describe("sendToUser", () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("posts a bilingual payload with route metadata", async () => {
    const fetchSpy = vi
      .spyOn(globalThis, "fetch")
      .mockResolvedValue(new Response("{}", { status: 200 }));
    await sendToUser({
      env: makeEnv(),
      userIds: ["u1"],
      headings: orderStatusTemplates.delivered.headings,
      contents: orderStatusTemplates.delivered.contents,
      route: "/orders/detail/123",
    });
    expect(fetchSpy).toHaveBeenCalledTimes(1);
    const [url, init] = fetchSpy.mock.calls[0];
    expect(url).toBe("https://onesignal.com/api/v1/notifications");
    const body = JSON.parse((init as RequestInit).body as string);
    expect(body.app_id).toBe("test-app");
    expect(body.include_external_user_ids).toEqual(["u1"]);
    expect(body.headings.ar).toBe("تم التسليم");
    expect(body.data).toEqual({ route: "/orders/detail/123" });
  });

  it("skips the HTTP call when credentials are missing", async () => {
    const fetchSpy = vi.spyOn(globalThis, "fetch");
    await sendToUser({
      env: makeEnv({ ONESIGNAL_API_KEY: "" }),
      userIds: ["u1"],
      headings: { en: "x" },
      contents: { en: "y" },
    });
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it("skips when the target list is empty", async () => {
    const fetchSpy = vi.spyOn(globalThis, "fetch");
    await sendToUser({
      env: makeEnv(),
      userIds: [],
      headings: { en: "x" },
      contents: { en: "y" },
    });
    expect(fetchSpy).not.toHaveBeenCalled();
  });
});

describe("orderStatusTemplates", () => {
  it("covers every lifecycle status emitted by the orders route", () => {
    const expectedKeys = [
      "confirmed",
      "in_production",
      "ready_for_delivery",
      "out_for_delivery",
      "delivered",
    ];
    for (const key of expectedKeys) {
      expect(orderStatusTemplates[key].headings.en).toBeTruthy();
      expect(orderStatusTemplates[key].headings.ar).toBeTruthy();
      expect(orderStatusTemplates[key].contents.en).toBeTruthy();
      expect(orderStatusTemplates[key].contents.ar).toBeTruthy();
    }
  });
});
