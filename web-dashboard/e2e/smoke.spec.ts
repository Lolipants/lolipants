import { test, expect } from "@playwright/test";

test("login page renders", async ({ page }) => {
  await page.goto("/login");
  await expect(page.getByRole("heading", { name: "Dashboard sign in" })).toBeVisible();
  await expect(page.getByLabel("Email")).toBeVisible();
});
