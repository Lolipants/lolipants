-- One-off: Summer 2026 coming-soon hero article for the News tab.
UPDATE fashion_news SET is_featured = 0 WHERE is_featured = 1;

INSERT INTO fashion_news (
  id,
  title_en,
  title_ar,
  summary_en,
  summary_ar,
  body_en,
  body_ar,
  cover_image_url,
  is_published,
  is_featured,
  published_at,
  author_id,
  created_at,
  updated_at
) VALUES (
  'a3f8c2e1-9b4d-4f6a-8c1e-summer2026teaser',
  'Summer 2026 Designs — Coming Soon',
  'تصاميم صيف 2026 — قريباً',
  'Lighter layers. Bolder colour. Gulf heat, reimagined. Your next favourite outfit is warming up backstage.',
  'طبقات أخف. ألوان أجرأ. حرارة الخليج بروح جديدة. زيّك المفضّل القادم يستعد خلف الستار.',
  'The runway is calling — and Lolipants is answering.

Summer 2026 is almost here: breathable abayas that move with the breeze, crisp thobes cut for long golden afternoons, and occasion pieces that turn every gathering into a moment.

We''re putting the finishing stitches on the collection now. Soon you''ll browse, customise, and order straight from the app.

Turn on notifications and watch this feed — the drop lands before the heat peaks.',
  'الموضة تهمس — ولوليبانتس تردّ.

صيف 2026 على الأبواب: عباءات خفيفة تمشي مع النسيم، وثوبات أنيقة لأيام الخليج الذهبية الطويلة، وقطع مناسبات تحوّل كل لقاء إلى لحظة.

نضع اللمسات الأخيرة على المجموعة الآن. قريباً ستتصفّح، تخصّص، وتطلب مباشرة من التطبيق.

فعّل الإشعارات وتابع هذا القسم — الإصدار يصل قبل أن يبلغ الحرّ ذروته.',
  NULL,
  1,
  1,
  datetime('now'),
  'MDjgxi4QSRdQfcayZ32PPJGavlhkTM8f',
  datetime('now'),
  datetime('now')
);
