-- Showcase fabric swatches (assets/images/fabrics/1.jpeg … 10.jpeg).
-- Run `pnpm upload:catalog-assets` so AI refine can fetch swatches from R2.

INSERT OR IGNORE INTO fabric_options (
  id, name, name_ar, quality, garment_type, is_available, swatch_url
) VALUES
  (
    'showcase_floral_blue_vintage',
    'Blue vintage floral',
    'زهور كلاسيكية زرقاء',
    'standard',
    'all',
    1,
    'assets/images/fabrics/1.jpeg'
  ),
  (
    'showcase_floral_grey_stipple',
    'Grey stipple floral',
    'زهور رمادية منقطة',
    'standard',
    'all',
    1,
    'assets/images/fabrics/2.jpeg'
  ),
  (
    'showcase_floral_dark_cottage',
    'Dark cottage floral',
    'زهور داكنة ريفية',
    'standard',
    'all',
    1,
    'assets/images/fabrics/3.jpeg'
  ),
  (
    'showcase_floral_brown_ditsy',
    'Brown ditsy floral',
    'زهور بنية صغيرة',
    'standard',
    'all',
    1,
    'assets/images/fabrics/4.jpeg'
  ),
  (
    'showcase_floral_black_garden',
    'Black garden floral',
    'زهور سوداء',
    'standard',
    'all',
    1,
    'assets/images/fabrics/5.jpeg'
  ),
  (
    'showcase_floral_olive_sketch',
    'Olive sketch floral',
    'زهور زيتونية مرسومة',
    'standard',
    'all',
    1,
    'assets/images/fabrics/6.jpeg'
  ),
  (
    'showcase_floral_blue_ditsy',
    'Blue ditsy floral',
    'زهور زرقاء صغيرة',
    'standard',
    'all',
    1,
    'assets/images/fabrics/7.jpeg'
  ),
  (
    'showcase_floral_sage_botanical',
    'Sage botanical',
    'نباتات رمادية خضراء',
    'standard',
    'all',
    1,
    'assets/images/fabrics/8.jpeg'
  ),
  (
    'showcase_floral_cream_mixed',
    'Cream mixed floral',
    'زهور كريمية متعددة',
    'standard',
    'all',
    1,
    'assets/images/fabrics/9.jpeg'
  ),
  (
    'showcase_floral_mauve_dainty',
    'Mauve dainty floral',
    'زهور بنفسجية ناعمة',
    'standard',
    'all',
    1,
    'assets/images/fabrics/10.jpeg'
  );
