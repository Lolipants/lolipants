const fs = require('fs');
const path = require('path');

function walk(dir, out = []) {
  for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, ent.name);
    if (ent.isDirectory()) walk(p, out);
    else if (p.endsWith('.dart')) out.push(p);
  }
  return out;
}

const pairRe =
  /'(\$\{AppStrings\.(\w+)\}) \/ (\$\{AppStrings\.(\w+)\})'/g;
const pairRe2 =
  /"(\$\{AppStrings\.(\w+)\}) \/ (\$\{AppStrings\.(\w+)\})"/g;

function migrateFile(file) {
  let s = fs.readFileSync(file, 'utf8');
  const orig = s;
  let changed = false;

  const replacer = (m, _full, enKey, _arPart, arKey) => {
    if (arKey !== enKey + 'Ar') return m;
    changed = true;
    return `localizedFromContext(context, AppStrings.${enKey}, AppStrings.${arKey})`;
  };

  s = s.replace(pairRe, replacer);
  s = s.replace(pairRe2, replacer);

  // const Text( localized... ) -> Text( localized... )
  if (changed) {
    s = s.replace(
      /const Text\(localizedFromContext/g,
      'Text(localizedFromContext',
    );
    s = s.replace(
      /const Text\(\s*\n\s*localizedFromContext/g,
      'Text(\n          localizedFromContext',
    );
    if (!s.includes('app_localization.dart')) {
      const importLine =
        "import 'package:lolipants/core/l10n/app_localization.dart';\n";
      const lastImport = s.lastIndexOf("import 'package:");
      if (lastImport >= 0) {
        const end = s.indexOf('\n', lastImport);
        s = s.slice(0, end + 1) + importLine + s.slice(end + 1);
      }
    }
    fs.writeFileSync(file, s);
  }
  return changed;
}

const root = 'lib';
const files = walk(root);
let n = 0;
for (const f of files) {
  if (migrateFile(f)) {
    console.log('updated', f);
    n++;
  }
}
console.log('total', n);
