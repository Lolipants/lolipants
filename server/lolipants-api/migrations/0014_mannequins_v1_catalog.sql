-- v1 mannequin catalogue: four bundled bodies only (see assets/images/mannequins).

UPDATE mannequin_options SET is_active = 0;

INSERT INTO mannequin_options (id, label_en, label_ar, is_active, sort_order, preview_url)
VALUES
  (
    'petite_female',
    'Petite (Female)',
    'نسائي قصير',
    1,
    0,
    'assets/images/mannequins/petite_female.png'
  ),
  (
    'standard_female',
    'Standard (Female)',
    'نسائي قياسي',
    1,
    1,
    'assets/images/mannequins/standard_female.png'
  ),
  (
    'standard_male',
    'Standard (Male)',
    'رجالي قياسي',
    1,
    2,
    'assets/images/mannequins/standard_male.png'
  ),
  (
    'slim_male',
    'Slim (Male)',
    'رجالي نحيف',
    1,
    3,
    'assets/images/mannequins/slim_male.png'
  )
ON CONFLICT(id) DO UPDATE SET
  label_en = excluded.label_en,
  label_ar = excluded.label_ar,
  is_active = excluded.is_active,
  sort_order = excluded.sort_order,
  preview_url = excluded.preview_url;
