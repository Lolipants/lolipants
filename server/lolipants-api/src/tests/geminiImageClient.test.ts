import { describe, expect, it } from "vitest";
import { extractInlineImageFromGeminiResponse } from "../lib/geminiImageClient";

describe("geminiImageClient", () => {
  it("extracts inline_data from Gemini REST shape", () => {
    const out = extractInlineImageFromGeminiResponse({
      candidates: [
        {
          content: {
            parts: [
              { text: "ok" },
              {
                inline_data: {
                  mime_type: "image/png",
                  data: "aaa",
                },
              },
            ],
          },
        },
      ],
    });
    expect(out?.mimeType).toBe("image/png");
    expect(out?.base64).toBe("aaa");
  });
});
