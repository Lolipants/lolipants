const fs = require('fs');
const path = 'lib/core/constants/app_strings.dart';

const t = {
  chooseYourRegion: 'الخليج، الشام، المغرب العربي، عصري، كاجوال',
  featuredBody:
    'تصاميم مسطّحة من الكلاسيكيات الخليجية إلى الأساسيات العصرية والكاجوال.',
  onboardingSlide1Body: 'صمّم ملابس مخصصة على مانيكان واقعي',
  onboardingSlide2Body: 'أزياء خليجية تقليدية بروح عصرية',
  onboardingSlide3Body: 'اطلب وتابع قطعتك من الخياطة إلى بابك',
  partnerLoadingRequests: 'جارٍ تحميل طلباتك السابقة…',
  partnerError404Hint:
    'غالباً يعني أن API_BASE_URL ليس خادم lolipants-api—راجع ملف .env وأعد تشغيل التطبيق.',
  partnerRoleTailorBullets:
    '• العمل على طلبات العملاء في التطبيق\n• تحديث حالة الخياطة أثناء التقدم\n• التنسيق مع فريق العمليات',
  partnerRoleDeliveryBullets:
    '• استلام وتسليم الملابس\n• تغطية المناطق المتفق عليها\n• اتباع إرشادات التعامل الآمن',
  partnerFieldSpecialties: 'التخصصات (مثل عرائس، عبايات، تعديلات)',
  partnerFieldAvailability: 'ملاحظات التوفر (اختياري)',
  partnerDetailsValidation: 'يرجى تعبئة الحقول المطلوبة قبل المتابعة.',
  partnerDoneBody:
    'شكراً لك. سيراجع فريقنا طلبك ويتواصل معك إن احتجنا لمزيد من التفاصيل.',
  partnerPendingBanner:
    'لديك طلب قيد المراجعة. سنُخبرك عند الانتهاء.',
  partnerPostApprovalHint:
    'إذا وُوفق على طلبك، سجّل الخروج ثم ادخل مجدداً لفتح الصفحة المناسبة لدورك.',
  partnerErrorPendingExists:
    'لديك طلب قيد المراجعة بالفعل. يرجى انتظار مراجعة الفريق.',
  chooseMannequin: 'اختر المانيكان',
  editorExitConfirm: 'الخروج بدون حفظ؟',
  weddingSelectDressHint: 'اختر فستاناً من الكتالوج أدناه',
  weddingDepositDisclaimer:
    'التأمين قابل للاسترداد عند إعادة الفستان بحالة جيدة.',
  editorBuildColorAiHint:
    'اللون الأساسي يُطبَّق على كل طبقات القطعة. لون التمييز للحواف واللوحات. المعاينة بالذكاء الاصطناعي تستخدم نفس الألوان.',
  editorBuildColorPrimary: 'لون القماش',
  editorBuildHeroEmpty:
    'اختر قالباً وخيارات لمعاينة المانيكان.',
  editorBuildResetHint:
    'اختر قالباً أعلاه لإضافة أجزاء القطعة، أو أبقِ المانيكان فقط.',
  editorStudioPromptTitle: 'صف كيف تريد تعديله',
  editorStudioPromptSubtitle:
    'نجمع اختيارك وكلماتك ودليل الأسلوب للمعاينة.',
  editorHeroAiOutputEmpty: 'اضغط إنشاء لعرض التصميم على المانيكان',
  editorAiRenderQuota: 'معاينات الذكاء الاصطناعي المتبقية هذا الأسبوع: {remaining}/{limit}',
  editorAiRenderQuotaEmpty:
    'لا توجد معاينات متبقية هذا الأسبوع. حاول بعد إعادة ضبط الحصة.',
  editorLookDisclaimer: 'المعاينة مُنشأة بالذكاء الاصطناعي وللتوضيح فقط.',
  editorSketchOptional: 'رسم اختياري للصورة للذكاء الاصطناعي',
  sizingQuestion: 'كيف تريد أخذ مقاساتك؟',
  sizingUseSaved: 'استخدام مقاساتي المحفوظة',
  aiMeasurementStep3: 'راجع المقاسات المقدّرة وعدّلها إن لزم',
  aiMeasurementAlignHint: 'محاذاة الجسم داخل الإطار',
  aiMeasurementEstimated: 'مقاسات مقدّرة',
  aiMeasurementVerifyHint: 'تحقق قبل الحفظ — يمكنك التعديل يدوياً',
  aiMeasurementManualFallback: 'إدخال المقاسات يدوياً بدلاً من ذلك',
  aiMeasurementCameraPermissionDenied: 'يلزم إذن الكاميرا للمسح',
  aiMeasurementNoCamera: 'لا توجد كاميرا على هذا الجهاز',
  aiMeasurementCameraInitFailed: 'تعذّر تشغيل الكاميرا',
  aiMeasurementCameraNotReady: 'الكاميرا غير جاهزة بعد',
  aiMeasurementEstimateFailed: 'تعذّر تقدير المقاسات من الصور',
  aiMeasurementCaptureFailed: 'تعذّر التقاط الصورة',
  aiMeasurementSaved: 'تم حفظ المقاسات',
  manualMeasurementsTitle: 'المقاسات اليدوية',
  manualMeasurementsSubtitle: 'أدخل القياسات بالسنتيمتر',
  manualErrorAtLeastOne: 'أدخل مقاساً واحداً على الأقل',
  manualErrorMax300: 'القيمة كبيرة جداً — تحقق من الوحدة (سم)',
  manualSaveFailed: 'تعذّر حفظ المقاسات',
  workshopDirectionsLabel: 'تعليمات الوصول',
  workshopVisitAddress: 'عنوان الورشة',
  workshopDateRequired: 'اختر تاريخاً',
  workshopAddressRequired: 'أدخل العنوان',
  workshopConfirmFailed: 'تعذّر تأكيد الموعد',
  myMeasurementsRescan: 'إعادة المسح',
  myMeasurementsEmpty: 'لا توجد مقاسات محفوظة بعد',
  aiGenerating: 'جارٍ الإنشاء…',
  aiDraftCreated: 'تم إنشاء مسودة',
  aiAppliedToDesign: 'تم التطبيق على التصميم',
  permissionCameraMessage:
    'نستخدم الكاميرا لالتقاط صور القياس والتصميم.',
  permissionCameraDeniedMessage:
    'فعّل الكاميرا من إعدادات الجهاز لمتابعة المسح.',
  permissionPhotosMessage: 'نستخدم الصور لاختيار صور من المعرض.',
  permissionPhotosDeniedMessage:
    'فعّل الوصول إلى الصور من إعدادات الجهاز.',
  permissionLocationMessage:
    'الموقع يساعدنا في إيجاد خياطين وورش قريبة.',
  permissionLocationDeniedMessage:
    'فعّل الموقع من إعدادات الجهاز للمتابعة.',
  permissionNotificationsMessage:
    'الإشعارات تُبقيك على اطلاع بحالة طلبك.',
  permissionNotificationsDeniedTitle: 'الإشعارات معطّلة',
  permissionNotificationsDeniedMessage:
    'فعّل الإشعارات من إعدادات الجهاز لمتابعة الطلب.',
  permissionAudioMessage: 'الميكروفون يساعد في الأوامر الصوتية.',
  permissionAudioDeniedMessage:
    'فعّل الميكروفون من إعدادات الجهاز للمتابعة.',
};

const s = fs.readFileSync(path, 'utf8');
const nameRe = /static const String (\w+)\s*=/g;
const names = [...s.matchAll(nameRe)].map((m) => m[1]);
const arSet = new Set(names.filter((n) => n.endsWith('Ar')));

const hasArabic = (enName) => {
  const chunk = s.slice(
    s.indexOf(`static const String ${enName}`),
    s.indexOf(`static const String ${enName}`) + 400,
  );
  return /[\u0600-\u06FF]/.test(chunk.split(';')[0]);
};

const missing = names.filter(
  (n) =>
    !n.endsWith('Ar') &&
    !arSet.has(n + 'Ar') &&
    !n.includes('Url') &&
    !n.includes('Path') &&
    !n.includes('Mailto') &&
    n !== 'appName' &&
    n !== 'partnerHeaderSubtitleEn' &&
    !hasArabic(n),
);

let block = '\n  // --- Arabic (pass 2: multiline / missed) ---\n\n';
const esc = (v) =>
  v.replace(/\\/g, '\\\\').replace(/'/g, "\\'").replace(/\n/g, '\\n');

let added = 0;
const skipped = [];
for (const n of missing) {
  if (!t[n]) {
    skipped.push(n);
    continue;
  }
  const val = t[n];
  block += `  /// Arabic: [${n}].\n`;
  if (val.includes('\n')) {
    block += `  static const String ${n}Ar =\n      '${esc(val)}';\n\n`;
  } else {
    block += `  static const String ${n}Ar = '${esc(val)}';\n\n`;
  }
  added++;
}

console.log('pass2 added', added, 'skipped', skipped.length, skipped);

const out = s.replace(
  /  static const String settingsDefaultTermsUrl = 'https:\/\/lolipants.com\/terms';/,
  (m) => `${m}${block}`,
);
fs.writeFileSync(path, out);
