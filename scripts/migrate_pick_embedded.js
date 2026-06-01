const fs = require('fs');
const path = require('path');

const slashKeys = new Set([
  'chooseMannequin', 'startDesigningCta', 'editorTitle', 'editorSave', 'editorSaved',
  'editorExitConfirm', 'editorBuildColorPrimary', 'editorBuildReset', 'editorAddText',
  'editorAddImage', 'editorHeroCompose', 'editorHeroAiLook', 'editorStudioPromptTitle',
  'editorHeroAiOutputEmpty', 'editorSketchOptional', 'sizingOptions', 'sizingQuestion',
  'sizingAiOption', 'sizingManualOption', 'sizingWorkshopOption', 'sizingUseSaved',
  'aiMeasurementTitle', 'aiMeasurementInstructions', 'aiMeasurementStartScan',
  'aiMeasurementCameraScan', 'aiMeasurementAnalyse', 'aiMeasurementEstimated',
  'aiMeasurementSave', 'aiMeasurementManualFallback', 'aiMeasurementNoCamera',
  'aiMeasurementCameraInitFailed', 'aiMeasurementCameraNotReady', 'aiMeasurementCaptureFailed',
  'aiMeasurementSaved', 'manualMeasurementsTitle', 'manualMeasurementsSubtitle',
  'manualSave', 'manualErrorAtLeastOne', 'manualErrorMax300', 'manualSaveFailed', 'manualSaved',
  'workshopTitle', 'workshopVisitOption', 'workshopHomeOption', 'workshopAddressLabel',
  'workshopCityLabel', 'workshopDirectionsLabel', 'workshopPickDate', 'workshopConfirm',
  'workshopDateRequired', 'workshopAddressRequired', 'workshopConfirmFailed',
  'myMeasurementsSummaryTitle', 'myMeasurementsEdit', 'myMeasurementsRescan',
  'myMeasurementsEmpty', 'myMeasurementsTakeNow', 'aiPromptLabel', 'aiGenerating',
  'aiApply', 'aiTryAgain', 'aiDraftCreated', 'aiAppliedToDesign', 'createAccountCta', 'logInCta',
  'featuredEyebrow',
]);

function walk(dir, out = []) {
  for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, ent.name);
    if (ent.isDirectory() && !p.includes('constants')) walk(p, out);
    else if (p.endsWith('.dart') && !p.includes('app_strings.dart')) out.push(p);
  }
  return out;
}

function migrate(file) {
  let s = fs.readFileSync(file, 'utf8');
  let changed = false;
  for (const key of slashKeys) {
    const re1 = new RegExp(`const Text\\(AppStrings\\.${key}\\)`, 'g');
    const re2 = new RegExp(`Text\\(AppStrings\\.${key}\\)`, 'g');
    const repl = `Text(pickSlashFromContext(context, AppStrings.${key}))`;
    if (re1.test(s)) {
      s = s.replace(new RegExp(`const Text\\(AppStrings\\.${key}\\)`, 'g'), repl);
      changed = true;
    }
    if (re2.test(s)) {
      s = s.replace(new RegExp(`(?<!const )Text\\(AppStrings\\.${key}\\)`, 'g'), repl);
      changed = true;
    }
    const re3 = new RegExp(`title: const Text\\(AppStrings\\.${key}\\)`, 'g');
    if (re3.test(s)) {
      s = s.replace(re3, `title: Text(pickSlashFromContext(context, AppStrings.${key}))`);
      changed = true;
    }
    const re4 = new RegExp(`labelText: '([^']*)'|labelText: AppStrings\\.${key}`);
  }
  if (changed && !s.includes('app_localization.dart')) {
    const idx = s.lastIndexOf("import 'package:");
    const end = s.indexOf('\n', idx);
    s = s.slice(0, end + 1) +
      "import 'package:lolipants/core/l10n/app_localization.dart';\n" +
      s.slice(end + 1);
  }
  if (changed) fs.writeFileSync(file, s);
  return changed;
}

let n = 0;
for (const f of walk('lib')) {
  if (migrate(f)) {
    console.log(f);
    n++;
  }
}
console.log('total', n);
