import { describe, expect, it, vi } from "vitest";
import { generateGarmentLookImageOpenAI } from "../lib/openaiImageClient";

const miniPngB64 =
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==";

describe("openaiImageClient", () => {
  it("parses b64_json from OpenAI images response", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async () =>
        Response.json({
          data: [{ b64_json: miniPngB64 }],
        }),
      ),
    );

    const result = await generateGarmentLookImageOpenAI({
      apiKey: "test-key",
      prompt: "Modest abaya studio photo",
    });

    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.bytes.byteLength).toBeGreaterThan(0);
      expect(result.mimeType).toBe("image/png");
    }

    vi.unstubAllGlobals();
  });
});
