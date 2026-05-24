import { describe, expect, it } from "vitest";
import {
  MANNEQUIN_CMS_DISABLED_MESSAGE,
  MANNEQUIN_CMS_MUTATIONS_DISABLED,
} from "../lib/cmsPolicy";

describe("cmsPolicy", () => {
  it("disables mannequin CMS mutations in v1", () => {
    expect(MANNEQUIN_CMS_MUTATIONS_DISABLED).toBe(true);
    expect(MANNEQUIN_CMS_DISABLED_MESSAGE).toContain("v1");
  });
});
