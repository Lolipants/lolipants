import { describe, expect, it, vi } from "vitest";
import app from "../index";

const env = {
  DB: { prepare: () => ({ bind: () => ({ first: async () => null }) }) } as unknown as D1Database,
  R2: {} as R2Bucket,
  AUTH_SERVICE: {
    fetch: async () =>
      new Response(
        JSON.stringify({
          user: { id: "user-1", role: "user", name: "Test", email: "t@x.com" },
        }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      ),
  } as Fetcher,
  BETTER_AUTH_BASE_URL: "https://auth.local",
  OPENAI_API_KEY: "test-key",
  ENVIRONMENT: "test",
} as const;

describe("POST /ai/design", () => {
  it("parses markdown-wrapped JSON from OpenAI", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async () =>
        Response.json({
          choices: [
            {
              message: {
                content:
                  '```json\n{"primaryColour":"#C9A84C","accentColour":"#FFFFFF","fabricId":"silk","patternId":"plain","description":"Gold abaya","descriptionAr":"عباية ذهبية"}\n```',
              },
            },
          ],
        }),
      ),
    );

    const res = await app.fetch(
      new Request("http://local/ai/design", {
        method: "POST",
        headers: {
          Authorization: "Bearer tok",
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          prompt: "Elegant gold abaya",
          garmentType: "abaya",
          currentStyle: "classic",
          gender: "women",
        }),
      }),
      env,
      { waitUntil: () => undefined, passThroughOnException: () => undefined } as ExecutionContext,
    );

    expect(res.status).toBe(200);
    const body = (await res.json()) as Record<string, string>;
    expect(body.primaryColour).toBe("#C9A84C");
    expect(body.description).toContain("Gold abaya");

    vi.unstubAllGlobals();
  });
});
