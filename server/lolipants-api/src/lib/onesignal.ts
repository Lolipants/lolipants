/**
 * Thin server-side wrapper around the OneSignal REST API. Each helper resolves
 * silently on failure so the surrounding request (order creation, status
 * transition, post publish, etc.) isn't blocked by push delivery problems.
 */

import type { Env } from "../types";

export type PushPayload = {
  en: string;
  ar?: string;
};

export type PushHeadings = {
  en: string;
  ar?: string;
};

const ONESIGNAL_URL = "https://onesignal.com/api/v1/notifications";

type SendToUserOptions = {
  env: Env;
  userIds: string[];
  headings: PushHeadings;
  contents: PushPayload;
  route?: string;
};

/**
 * Sends a push to one or more internal user ids. Targets via
 * `include_external_user_ids` so the OneSignal player id doesn't need to
 * flow through the backend. Silently skips when credentials are missing.
 */
export async function sendToUser(opts: SendToUserOptions): Promise<void> {
  const apiKey = opts.env.ONESIGNAL_API_KEY?.trim();
  const appId = opts.env.ONESIGNAL_APP_ID?.trim();
  if (!apiKey || !appId || opts.userIds.length === 0) {
    return;
  }
  const body: Record<string, unknown> = {
    app_id: appId,
    include_external_user_ids: opts.userIds,
    contents: {
      en: opts.contents.en,
      ...(opts.contents.ar ? { ar: opts.contents.ar } : {}),
    },
    headings: {
      en: opts.headings.en,
      ...(opts.headings.ar ? { ar: opts.headings.ar } : {}),
    },
    channel_for_external_user_ids: "push",
  };
  if (opts.route) {
    body.data = { route: opts.route };
  }
  try {
    await fetch(ONESIGNAL_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Basic ${apiKey}`,
      },
      body: JSON.stringify(body),
    });
  } catch (err) {
    console.error("onesignal.send_failed", err);
  }
}

/** Bilingual order-status templates shared by the orders + delivery routes. */
export const orderStatusTemplates: Record<
  string,
  { headings: PushHeadings; contents: PushPayload }
> = {
  confirmed: {
    headings: { en: "Order confirmed", ar: "تم تأكيد الطلب" },
    contents: {
      en: "Your custom garment is on its way to production.",
      ar: "تم بدء تصنيع تصميمك المخصّص.",
    },
  },
  in_production: {
    headings: { en: "In production", ar: "قيد التصنيع" },
    contents: {
      en: "A tailor has picked up your design.",
      ar: "تم استلام التصميم من قبل خياط.",
    },
  },
  ready_for_delivery: {
    headings: { en: "Ready for delivery", ar: "جاهز للتسليم" },
    contents: {
      en: "Your order is packaged and awaiting a driver.",
      ar: "جاهز طلبك للتسليم.",
    },
  },
  out_for_delivery: {
    headings: { en: "Out for delivery", ar: "قيد التوصيل" },
    contents: {
      en: "A driver is on the way to you.",
      ar: "المندوب في طريقه إليك.",
    },
  },
  delivered: {
    headings: { en: "Delivered", ar: "تم التسليم" },
    contents: {
      en: "Hope you love it — share a photo in the community!",
      ar: "نتمنى أن ينال التصميم إعجابك — شاركنا صورة في المجتمع!",
    },
  },
};
