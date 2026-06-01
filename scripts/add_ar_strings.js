const fs = require('fs');
const path = 'lib/core/constants/app_strings.dart';

const t = {
  brandLatin: 'LOLIPANTS',
  heroTryNow: 'جرّب الآن ←',
  categoryAll: 'الكل',
  styleQatariThobe: 'ثوب قطري',
  styleSaudiBisht: 'بشت سعودي',
  styleUaeKandura: 'كندورة إماراتية',
  styleOmaniDishdasha: 'دشداشة عمانية',
  originGulf: 'الخليج',
  musicPlayerLabel: 'مشغّل الموسيقى',
  homeExploreAll: 'استكشف الكل',
  signupGenderRequired: 'يرجى اختيار الجنس',
  designGenderDialogTitle: 'لمن تصمّم اليوم؟',
  accessoriesTshirtCta: 'ابدأ بتصميم تيشيرت',
  comingPhase3: 'قريباً — المرحلة ٣',
  comingPhase4: 'قريباً — المرحلة ٤',
  createAccountCta: 'إنشاء حساب',
  logInCta: 'تسجيل الدخول',
  resetEmailSentPrefix: 'أرسلنا رابط إعادة التعيين إلى',
  filter: 'تصفية',
  featuredEyebrow: 'مختارات',
  featuredCollection: 'المجموعة المميزة',
  errorInvalidEmail: 'أدخل بريداً إلكترونياً صالحاً',
  errorPasswordShort: 'يجب أن تكون كلمة المرور ٨ أحرف على الأقل',
  errorPasswordDigit: 'يجب أن تتضمن كلمة المرور رقماً',
  errorPasswordMismatch: 'كلمتا المرور غير متطابقتين',
  errorNameShort: 'يجب أن يكون الاسم حرفين على الأقل',
  errorForbidden: 'ليس لديك صلاحية لتنفيذ هذا الإجراء',
  errorAuthGeneric: 'حدث خطأ ما. يرجى المحاولة مرة أخرى.',
  errorInvalidCredentials: 'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
  partnerTitleEn: 'كن شريكاً مع Lolipants',
  partnerRetry: 'إعادة المحاولة',
  partnerRoleTailorTitle: 'شريك خياطة',
  partnerRoleDeliveryTitle: 'شريك توصيل',
  partnerFieldCityRegion: 'المدينة أو المنطقة التي تخدمها',
  partnerFieldYearsExperience: 'سنوات الخبرة',
  partnerFieldWorkshopName: 'اسم الورشة أو الاستوديو (اختياري)',
  partnerFieldVehicle: 'نوع المركبة',
  partnerFieldCoverage: 'مناطق / نطاقات التغطية',
  partnerReviewNoteLabel: 'ملاحظات إضافية؟ (اختياري)',
  partnerWizardBack: 'رجوع',
  partnerWizardNext: 'التالي',
  partnerWizardSubmit: 'إرسال الطلب',
  partnerDoneTitle: 'تم إرسال الطلب',
  partnerDoneBackToProfile: 'العودة إلى الملف الشخصي',
  partnerPreviousRequests: 'الطلبات السابقة',
  partnerNoRequestsYet: 'لا توجد طلبات بعد.',
  aiDesigner: 'مصمّم بالذكاء الاصطناعي',
  describeOutfit: 'صف زيّك المثالي',
  tryNow: 'جرّب الآن ←',
  trackOrder: 'تتبع الطلب',
  inProgress: 'قيد التنفيذ',
  orderPrefix: 'طلب',
  designLabel: 'التصميم',
  tailorLabel: 'الخياط',
  countryQatar: 'قطر',
  countrySaudi: 'السعودية',
  countryUae: 'الإمارات',
  countryOman: 'عُمان',
  countryCodeQa: 'QA',
  countryCodeSa: 'SA',
  countryCodeAe: 'AE',
  countryCodeOm: 'OM',
  tailorStripMeta: 'خياطون معتمدون في منطقتك',
  countryGarmentsQa: 'أزياء قطرية',
  countryGarmentsSa: 'أزياء سعودية',
  countryGarmentsAe: 'أزياء إماراتية',
  countryGarmentsOm: 'أزياء عُمانية',
  startDesigningCta: 'ابدأ التصميم',
  editorTitle: 'المحرّر',
  editorSave: 'حفظ',
  editorSaved: 'تم الحفظ',
  editorTabDesigns: 'التصاميم',
  weddingFilterAll: 'الكل',
  weddingFilterBridal: 'عروس',
  weddingFilterBridesmaids: 'وصيفات',
  weddingRent: 'إيجار',
  weddingBuy: 'شراء',
  weddingRentalDays: 'أيام الإيجار',
  weddingCatalogEmpty: 'لا توجد فساتين في هذا التصنيف بعد.',
  weddingCatalogError: 'تعذّر تحميل كتالوج الأعراس.',
  weddingRentDress: 'استئجار الفستان',
  weddingBuyDress: 'شراء الفستان',
  weddingOrderSummaryTitle: 'ملخص الطلب',
  editorBuildSummaryTitle: 'ملخص التصميم',
  editorBuildPickTemplate: 'اختر قالباً',
  editorBuildTemplate: 'القالب',
  editorBuildSelectSlot: 'اختر القطعة',
  editorBuildChangeStyle: 'تغيير النمط',
  editorBuildReset: 'إعادة ضبط',
  editorStyleCatalogMode: 'من الكتالوج',
  editorTabFabric: 'القماش',
  editorAddText: 'إضافة نص',
  editorAddImage: 'إضافة صورة',
  editorTabPattern: 'النقش',
  editorTabEmbroidery: 'التطريز',
  editorTabText: 'النص',
  editorTabAi: 'ذكاء اصطناعي',
  editorHeroCompose: 'كوّن إطلالتك',
  editorHeroAiLook: 'إطلالة بالذكاء الاصطناعي',
  editorGenerateLook: 'إنشاء إطلالة',
  editorLookGenerating: 'جارٍ إنشاء الإطلالة…',
  editorSketchClear: 'مسح الرسم',
  sizingOptions: 'خيارات المقاسات',
  sizingAiOption: 'قياس بالذكاء الاصطناعي',
  sizingManualOption: 'إدخال يدوي',
  sizingWorkshopOption: 'زيارة ورشة',
  sizingAiSubtitle: 'التقط صوراً ونحسب مقاساتك',
  sizingManualSubtitle: 'أدخل المقاسات بنفسك',
  sizingWorkshopSubtitle: 'احجز موعداً في ورشة شريكة',
  aiMeasurementTitle: 'قياس بالذكاء الاصطناعي',
  aiMeasurementInstructions: 'اتبع الخطوات للحصول على مقاسات دقيقة',
  aiMeasurementStep1: 'قف بشكل مستقيم أمام الكاميرا',
  aiMeasurementStep2: 'التقط صوراً من الأمام والجانب',
  aiMeasurementStartScan: 'بدء المسح',
  aiMeasurementCameraScan: 'مسح بالكاميرا',
  aiMeasurementAnalyse: 'تحليل الصور',
  aiMeasurementSave: 'حفظ المقاسات',
  aiMeasurementSaveFailed: 'تعذّر حفظ المقاسات',
  aiMeasurementAnalysing: 'جارٍ التحليل…',
  manualSave: 'حفظ',
  manualSaved: 'تم حفظ المقاسات',
  workshopTitle: 'زيارة الورشة',
  workshopVisitOption: 'زيارة الورشة',
  workshopHomeOption: 'قياس منزلي',
  workshopAddressLabel: 'العنوان',
  workshopCityLabel: 'المدينة',
  workshopPickDate: 'اختر التاريخ',
  workshopConfirm: 'تأكيد الموعد',
  workshopConfirmedPrefix: 'تم تأكيد موعدك في',
  workshopConfirmedArPrefix: 'تم تأكيد موعدك في',
  myMeasurementsSummaryTitle: 'ملخص مقاساتي',
  measurementUnknown: 'غير محدد',
  measurementChest: 'الصدر',
  measurementWaist: 'الخصر',
  measurementHips: 'الورك',
  measurementShoulderWidth: 'عرض الكتف',
  measurementHeight: 'الطول',
  measurementArmLength: 'طول الذراع',
  measurementPreferredSize: 'المقاس المفضل',
  measurementUnitCm: 'سم',
  myMeasurementsLastUpdatedPrefix: 'آخر تحديث:',
  myMeasurementsEdit: 'تعديل',
  myMeasurementsTakeNow: 'خذ مقاساتك الآن',
  sizingOptionsTooltip: 'اختر طريقة أخذ المقاسات',
  aiPromptLabel: 'صف الإطلالة التي تريدها',
  aiApply: 'تطبيق',
  aiTryAgain: 'حاول مرة أخرى',
  permissionNotNow: 'ليس الآن',
  permissionContinue: 'متابعة',
  permissionOpenSettings: 'فتح الإعدادات',
  permissionCameraTitle: 'الكاميرا مطلوبة لالتقاط الصور والقياس',
  permissionCameraDeniedTitle: 'تم رفض إذن الكاميرا',
  permissionPhotosTitle: 'الصور مطلوبة لاختيار صور من المعرض',
  permissionPhotosDeniedTitle: 'تم رفض إذن الصور',
  permissionLocationTitle: 'الموقع يساعدنا في إيجاد خياطين قريبين',
  permissionLocationDeniedTitle: 'تم رفض إذن الموقع',
  permissionNotificationsTitle: 'الإشعارات تُبقيك على اطلاع بطلبك',
  permissionAudioTitle: 'الميكروفون مطلوب للأوامر الصوتية',
  permissionAudioDeniedTitle: 'تم رفض إذن الميكروفون',
  partnerLoadingRequests: 'جارٍ تحميل طلباتك السابقة…',
  partnerRoleTailorBullets:
    '• العمل على طلبات العملاء في التطبيق\n• تحديث حالة الخياطة أثناء التقدم\n• التنسيق مع فريق العمليات',
  partnerRoleDeliveryBullets:
    '• استلام وتسليم الملابس\n• تغطية المناطق المتفق عليها\n• اتباع إرشادات التعامل الآمن',
  partnerFieldPortfolioUrl: 'معرض أعمال أو موقع (اختياري)',
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
  partnerError404Hint:
    'غالباً يعني أن API_BASE_URL ليس خادم lolipants-api—راجع ملف .env وأعد تشغيل التطبيق.',
  errorApiBaseUrlMissing:
    'لا يمكن للتطبيق الوصول إلى واجهة البرمجة: أضف API_BASE_URL إلى ملف .env في جذر المشروع (انظر .env.example) ثم أعد التشغيل.',
  errorApiBaseUrlSameAsAuth:
    'يجب أن يشير API_BASE_URL إلى عامل lolipants-api ولا يمكن أن يكون نفس BETTER_AUTH_BASE_URL. انظر .env.example.',
  errorNetworkUnreachable:
    'تعذّر الوصول إلى الخادم. تحقق من اتصال الإنترنت وحاول مرة أخرى.',
  errorNetworkTimeout:
    'انتهت مهلة الطلب. تحقق من الاتصال وحاول مرة أخرى.',
  errorHttpBadGateway:
    'تعذّر الوصول إلى خدمة المصادقة. حاول بعد قليل.',
  errorHttpServiceUnavailable: 'الخدمة غير متاحة مؤقتاً. حاول لاحقاً.',
  errorHttpGatewayTimeout: 'انتهت مهلة البوابة. حاول مرة أخرى.',
  errorHttpServerError: 'خطأ في الخادم. حاول لاحقاً.',
  errorGoogleServerClientIdMissing:
    'أضف GOOGLE_SERVER_CLIENT_ID إلى ملف .env (معرّف عميل Google OAuth؛ يجب أن يطابق GOOGLE_CLIENT_ID على عامل المصادقة).',
  onboardingSlide1Body: 'صمّم ملابس مخصصة على مانيكان واقعي',
  onboardingSlide2Body: 'أزياء خليجية تقليدية بروح عصرية',
  onboardingSlide3Body: 'اطلب وتابع قطعتك من الخياطة إلى بابك',
  categoryWedding: 'أعراس',
  categoryAccessories: 'إكسسوارات',
};

const s = fs.readFileSync(path, 'utf8');
const re = /static const String (\w+) = /g;
const names = [];
let m;
while ((m = re.exec(s))) names.push(m[1]);
const arSet = new Set(names.filter((n) => n.endsWith('Ar')));
const missing = names.filter(
  (n) =>
    !n.endsWith('Ar') &&
    !arSet.has(n + 'Ar') &&
    !n.includes('Url') &&
    !n.includes('Path') &&
    !n.includes('Mailto') &&
    n !== 'appName',
);

let block =
  '\n  // ---------------------------------------------------------------------------\n';
block +=
  '  // Arabic counterparts for strings that previously had English only\n';
block +=
  '  // ---------------------------------------------------------------------------\n\n';

block += `  /// Picks [ar] when [locale] language is Arabic, otherwise [en].\n`;
block += `  static String localized(Locale locale, String en, String ar) {\n`;
block += `    return locale.languageCode == 'ar' ? ar : en;\n`;
block += `  }\n\n`;

block += `  /// Featured strip subtitle (Arabic) by profile gender.\n`;
block += `  static String homeFeaturedSubtitleForGenderAr(String? gender) {\n`;
block += `    switch (gender) {\n`;
block += `      case 'men':\n`;
block += `        return 'مختارات رجالية لك';\n`;
block += `      case 'women':\n`;
block += `        return 'مختارات نسائية لك';\n`;
block += `      default:\n`;
block += `        return 'مختارات مُختارة لك';\n`;
block += `    }\n`;
block += `  }\n\n`;

block += `  /// Featured strip subtitle for [locale] and profile gender.\n`;
block += `  static String homeFeaturedSubtitle(Locale locale, String? gender) {\n`;
block += `    return localized(\n`;
block += `      locale,\n`;
block += `      homeFeaturedSubtitleForGender(gender),\n`;
block += `      homeFeaturedSubtitleForGenderAr(gender),\n`;
block += `    );\n`;
block += `  }\n\n`;

const esc = (v) =>
  v.replace(/\\/g, '\\\\').replace(/'/g, "\\'").replace(/\n/g, '\\n');

const skipped = [];
let added = 0;
for (const n of missing) {
  if (!t[n]) {
    skipped.push(n);
    continue;
  }
  block += `  /// Arabic: [${n}].\n`;
  const val = t[n];
  if (val.includes('\n')) {
    block += `  static const String ${n}Ar =\n      '${esc(val)}';\n\n`;
  } else {
    block += `  static const String ${n}Ar = '${esc(val)}';\n\n`;
  }
  added++;
}

console.log('added', added, 'skipped', skipped.length);
if (skipped.length) console.log('skipped:', skipped.join(', '));

let out = s.replace(
  /  static const String settingsDefaultTermsUrl = 'https:\/\/lolipants.com\/terms';\n}/,
  `  static const String settingsDefaultTermsUrl = 'https://lolipants.com/terms';${block}}`,
);
if (!out.includes("import 'dart:ui'")) {
  out = "import 'dart:ui' show Locale;\n\n" + out;
}
fs.writeFileSync(path, out);
