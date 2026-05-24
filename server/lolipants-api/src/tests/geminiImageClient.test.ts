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
      hasDesignPreviewReference: true,
    });
    expect(prompt).toContain("Modular design");
    expect(prompt).toContain("Halter");
    expect(prompt).toContain("white");
    expect(prompt).toContain("REFINE");
    expect(prompt).toContain("overlay panels as sleeves");
  });

  it("includes AI layer notes for sleeveless and overlay semantics", () => {
    const prompt = buildGarmentLookPrompt({
      garmentType: "abaya",
      primaryColour: "#162F28",
      accentColour: "#C9A84C",
      fabricQuality: "standard",
      configuratorAiLayerNotes:
        '- Sleeve: "No sleeves" — NO SLEEVES on this design.\n- Overlay: "Chest panel" — NOT sleeves.',
      hasDesignPreviewReference: true,
    });
    expect(prompt).toContain("Layer semantics");
    expect(prompt).toContain("NO SLEEVES");
    expect(prompt).toContain("NOT sleeves");
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
