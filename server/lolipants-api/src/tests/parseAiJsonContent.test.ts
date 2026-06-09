import { describe, expect, it } from "vitest";
import { parseAiJsonContent } from "../lib/parseAiJsonContent";

describe("parseAiJsonContent", () => {
  it("parses bare JSON", () => {
    const out = parseAiJsonContent(
      '{"primaryColour":"#C9A84C","description":"Gold abaya"}',
    ) as Record<string, string>;
    expect(out.primaryColour).toBe("#C9A84C");
  });

  it("parses markdown fenced JSON", () => {
    const out = parseAiJsonContent(
      '```json\n{"primaryColour":"#FFFFFF","fabricId":"silk"}\n```',
    ) as Record<string, string>;
    expect(out.fabricId).toBe("silk");
  });

  it("extracts JSON object from prose wrapper", () => {
    const out = parseAiJsonContent(
      'Here is the design:\n{"primaryColour":"#162F28"}\nHope you like it!',
    ) as Record<string, string>;
    expect(out.primaryColour).toBe("#162F28");
  });
});
