const fs = require('fs');

const file = 'lib/features/profile/screens/settings_screen.dart';
let s = fs.readFileSync(file, 'utf8');

// Replace '${AppStrings.foo} / '\n    '${AppStrings.fooAr}' patterns
s = s.replace(
  /'(\$\{AppStrings\.(\w+)\}) \/ '\s*\n\s*'(\$\{AppStrings\.(\w+)\})'/g,
  (m, _a, enKey, _c, arKey) => {
    if (arKey !== enKey + 'Ar') return m;
    return `localizedFromContext(context, AppStrings.${enKey}, AppStrings.${arKey})`;
  },
);

// Single-line remaining: 'foo / bar' with AppStrings on one line
s = s.replace(
  /'(\$\{AppStrings\.(\w+)\}) \/ (\$\{AppStrings\.(\w+)\})'/g,
  (m, _a, enKey, _c, arKey) => {
    if (arKey !== enKey + 'Ar') return m;
    return `localizedFromContext(context, AppStrings.${enKey}, AppStrings.${arKey})`;
  },
);

s = s.replace(/const Text\(localizedFromContext/g, 'Text(localizedFromContext');
s = s.replace(
  /title: const Text\(\s*\n\s*localizedFromContext/g,
  'title: Text(\n          localizedFromContext',
);

fs.writeFileSync(file, s);
console.log('done');
