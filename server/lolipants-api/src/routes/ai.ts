import { Hono } from "hono";
import { requireAuth } from "../middleware/auth";
import type { AppVariables, Env } from "../types";

export const aiRoutes = new Hono<{ Bindings: Env; Variables: AppVariables }>();
aiRoutes.use("*", requireAuth);

aiRoutes.post("/design", async (c) => {
  const { prompt, garmentType, currentStyle } = await c.req.json();

  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${c.env.OPENAI_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: "gpt-4o-mini",
      messages: [
        {
          role: "system",
          content:
            "Return ONLY JSON for fashion design suggestion fields: primaryColour, accentColour, fabricId, patternId, embroideryId, description, descriptionAr.",
        },
        {
          role: "user",
          content: `Garment: ${garmentType}\nStyle: ${currentStyle ?? "none"}\nPrompt: ${prompt}`,
        },
      ],
      temperature: 0.7,
      max_tokens: 350,
    }),
  });

  if (!response.ok) return c.json({ error: "AI service unavailable" }, 503);
  const data = (await response.json()) as { choices?: Array<{ message?: { content?: string } }> };
  const raw = data.choices?.[0]?.message?.content ?? "{}";
  try {
    return c.json(JSON.parse(raw));
  } catch {
    return c.json({ error: "Could not parse AI response" }, 500);
  }
});

aiRoutes.post("/measure", async (c) => {
  const { imageBase64 } = await c.req.json();
  if (!imageBase64) return c.json({ error: "imageBase64 is required" }, 400);

  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${c.env.OPENAI_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: "gpt-4o",
      messages: [
        {
          role: "user",
          content: [
            {
              type: "text",
              text: "Estimate body measurements in cm from this image. Return ONLY JSON with chest, waist, hips, shoulderWidth, height, armLength.",
            },
            {
              type: "image_url",
              image_url: {
                url: `data:image/jpeg;base64,${imageBase64}`,
                detail: "high",
              },
            },
          ],
        },
      ],
      max_tokens: 200,
    }),
  });

  if (!response.ok) return c.json({ error: "AI measurement service unavailable" }, 503);
  const data = (await response.json()) as { choices?: Array<{ message?: { content?: string } }> };
  const raw = data.choices?.[0]?.message?.content ?? "{}";
  try {
    return c.json(JSON.parse(raw));
  } catch {
    return c.json({ error: "Could not parse measurement response" }, 500);
  }
});
