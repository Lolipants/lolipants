import { describe, expect, it } from "vitest";
import app from "../index";

const env = {
  DB: {} as unknown,
  BETTER_AUTH_SECRET: "test-secret",
  BETTER_AUTH_URL: "http://localhost",
  TRUSTED_ORIGINS: "http://localhost:3000,lolipants://auth",
  AWS_SES_REGION: "us-east-1",
  RESET_FROM_EMAIL: "test@lolipants.com",
  APP_NAME: "LOLIPANTS",
};

describe("better-auth worker smoke", () => {
  it("serves a health-check at /", async () => {
    const res = await app.request("http://localhost/", {}, env);
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body).toMatchObject({ ok: true, service: "lolipants-better-auth" });
  });

  it("exposes the email-OTP send endpoint (CORS preflight ok)", async () => {
    const res = await app.request(
      "http://localhost/auth/email-otp/send-verification-otp",
      {
        method: "OPTIONS",
        headers: {
          Origin: "http://localhost:3000",
          "Access-Control-Request-Method": "POST",
        },
      },
      env,
    );
    expect([200, 204]).toContain(res.status);
  });

  it("exposes social sign-in route for google (CORS preflight ok)", async () => {
    const res = await app.request(
      "http://localhost/auth/sign-in/social",
      {
        method: "OPTIONS",
        headers: {
          Origin: "http://localhost:3000",
          "Access-Control-Request-Method": "POST",
        },
      },
      env,
    );
    expect([200, 204]).toContain(res.status);
  });

});
