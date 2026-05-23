import { describe, expect, it } from "vitest";
import {
  buildGarmentLookPrompt,
  extractInlineImageFromGeminiResponse,
} from "../lib/geminiImageClient";

describe("geminiImageClient", () => {
  it("includes configurator summary in garment look prompt", () => {
    const prompt = buildGarmentLookPrompt({
      garmentType: "dress",
      primaryColour: "#162F28",
      accentColour: "#C9A84C",
      fabricQuality: "standard",
      configuratorSummary: "Western dress · Halter · Circle skirt",
    });
    expect(prompt).toContain("Modular design");
    expect(prompt).toContain("Halter");
  });

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
