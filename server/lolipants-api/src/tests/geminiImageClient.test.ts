import { describe, expect, it } from "vitest";
import {
  buildGarmentLookPrompt,
  extractInlineImageFromGeminiResponse,
} from "../lib/geminiImageClient";

describe("geminiImageClient", () => {
  it("uses prompt-only home draft mode without refine or fabric language", () => {
    const prompt = buildGarmentLookPrompt({
      garmentType: "abaya",
      primaryColour: "#C9A84C",
      accentColour: "#FFFFFF",
      fabricQuality: "standard",
      userExtra: "Elegant gold abaya for a wedding",
      isPromptOnlyHomeDraft: true,
    });
    expect(prompt).toContain("Creative brief:");
    expect(prompt).toContain("Elegant gold abaya for a wedding");
    expect(prompt).toContain("ON the mannequin");
    expect(prompt).toContain("pure solid white (#FFFFFF)");
    expect(prompt).not.toContain("REFINE");
    expect(prompt).not.toContain("Modular design");
    expect(prompt).not.toContain("Fabric material");
  });

  it("uses catalogue dress prompt without configurator slots", () => {
    const prompt = buildGarmentLookPrompt({
      garmentType: "dress",
      primaryColour: "#162F28",
      accentColour: "#C9A84C",
      fabricQuality: "standard",
      userExtra: "Softer drape",
      configuratorSummary: "Should not appear",
      isCatalogDesignMode: true,
      hasDesignPreviewReference: true,
    });
    expect(prompt).toContain("catalogue dress");
    expect(prompt).toContain("Softer drape");
    expect(prompt).not.toContain("Modular design");
    expect(prompt).not.toContain("Should not appear");
  });

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

  it("includes fabric material name in garment look prompt", () => {
    const prompt = buildGarmentLookPrompt({
      garmentType: "abaya",
      primaryColour: "#162F28",
      accentColour: "#C9A84C",
      fabricName: "Silk",
      hasFabricSwatchReference: true,
      fabricQuality: "premium",
      hasDesignPreviewReference: true,
    });
    expect(prompt).toContain("Fabric material (mandatory): Silk");
    expect(prompt).toContain("IGNORE that fill");
    expect(prompt).toContain("attached fabric swatch");
    expect(prompt).not.toContain("Primary fabric colour:");
    expect(prompt).toContain("Fabric quality tier: premium");
  });

  it("uses fabric-first prompt without primary colour when fabric is selected", () => {
    const prompt = buildGarmentLookPrompt({
      garmentType: "dress",
      primaryColour: "#FF0000",
      accentColour: "#C9A84C",
      fabricName: "Blue vintage floral",
      fabricQuality: "standard",
      hasDesignPreviewReference: true,
    });
    expect(prompt).toContain("placeholder colour");
    expect(prompt).not.toContain("Primary fabric colour:");
    expect(prompt).not.toContain("#FF0000");
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
