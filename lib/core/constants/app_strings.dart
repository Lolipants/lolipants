import 'dart:ui' show Locale;

/// Bilingual user-facing copy (English + Arabic) for Phase 1–2 screens.
class AppStrings {
  AppStrings._();

  /// Application name in English.
  static const String appName = 'Lolipants';

  /// Application name in Arabic.
  static const String appNameAr = 'لوليبانتس';

  /// Splash / login greeting (English).
  static const String welcomeBack = 'Welcome back';

  /// Splash / login greeting (Arabic).
  static const String welcomeBackAr = 'مرحباً بعودتك';

  /// Phase 1 foundation screen title (English).
  static const String designFoundationTitle = 'Design foundation';

  /// Phase 1 foundation screen title (Arabic).
  static const String designFoundationTitleAr = 'أساس التصميم';

  /// Phase 1 foundation subtitle (English).
  static const String designFoundationSubtitle =
      'Shared components and theme preview';

  /// Phase 1 foundation subtitle (Arabic).
  static const String designFoundationSubtitleAr =
      'معاينة المكوّنات والسمة المشتركة';

  /// Bottom nav: Home (English).
  static const String navHome = 'Home';

  /// Bottom nav: Home (Arabic).
  static const String navHomeAr = 'الرئيسية';

  /// Bottom nav: Browse (English).
  static const String navBrowse = 'Browse';

  /// Bottom nav: Browse (Arabic).
  static const String navBrowseAr = 'تصفح';

  /// Bottom nav: Orders (English).
  static const String navOrders = 'Orders';

  /// Bottom nav: Orders (Arabic).
  static const String navOrdersAr = 'الطلبات';

  /// Bottom nav: Profile (English).
  static const String navProfile = 'Profile';

  /// Bottom nav: Profile (Arabic).
  static const String navProfileAr = 'الملف';

  /// Email field label (English).
  static const String email = 'Email';

  /// Email field label (Arabic).
  static const String emailAr = 'البريد الإلكتروني';

  /// Password field label (English).
  static const String password = 'Password';

  /// Password field label (Arabic).
  static const String passwordAr = 'كلمة المرور';

  /// Full name field label (English).
  static const String fullName = 'Full name';

  /// Full name field label (Arabic).
  static const String fullNameAr = 'الاسم الكامل';

  /// Primary button sample (English).
  static const String tryPrimary = 'Try primary';

  /// Primary button sample (Arabic).
  static const String tryPrimaryAr = 'جرّب الأساسي';

  /// Secondary button sample (English).
  static const String trySecondary = 'Secondary';

  /// Secondary button sample (Arabic).
  static const String trySecondaryAr = 'ثانوي';

  /// Destructive button sample (English).
  static const String tryDestructive = 'Destructive';

  /// Destructive button sample (Arabic).
  static const String tryDestructiveAr = 'حذف';

  /// Generic validation: required field (English).
  static const String errorRequired = 'This field is required';

  /// Generic validation: required field (Arabic).
  static const String errorRequiredAr = 'هذا الحقل مطلوب';

  /// Create account screen title (English).
  static const String createAccount = 'Create account';

  /// Create account screen title (Arabic).
  static const String createAccountAr = 'إنشاء حساب';

  /// Log in CTA (English).
  static const String logIn = 'Log in';

  /// Log in CTA (Arabic).
  static const String logInAr = 'تسجيل الدخول';

  /// Sign up CTA (English).
  static const String signUp = 'Sign up';

  /// Sign up CTA (Arabic).
  static const String signUpAr = 'إنشاء حساب';

  /// Submit forgot-password form (English).
  static const String sendResetLink = 'Send reset link';

  /// Submit forgot-password form (Arabic).
  static const String sendResetLinkAr = 'إرسال رابط الاستعادة';

  /// Forgot password link (English).
  static const String forgotPassword = 'Forgot password?';

  /// Forgot password link (Arabic).
  static const String forgotPasswordAr = 'نسيت كلمة المرور؟';

  /// Onboarding slide 1 title (English).
  static const String onboardingDesignTitle = 'Design your own fashion';

  /// Onboarding slide 1 title (Arabic).
  static const String onboardingDesignTitleAr = 'صمم أزياءك الخاصة';

  /// Onboarding slide 2 title (English).
  static const String onboardingHeritageTitle = 'Inspired by your culture';

  /// Onboarding slide 2 title (Arabic).
  static const String onboardingHeritageTitleAr = 'مستوحى من ثقافتك';

  /// Onboarding slide 3 title (English).
  static const String onboardingOrderTitle = 'Made by expert tailors';

  /// Onboarding slide 3 title (Arabic).
  static const String onboardingOrderTitleAr = 'مصنوع من قِبل خياطين خبراء';

  /// Tagline under brand (English).
  static const String taglineWearYourHeritage = 'wear your heritage';

  /// Tagline under brand (Arabic).
  static const String taglineWearYourHeritageAr = 'ارتدِ إرثك';

  /// Latin logotype line.
  static const String brandLatin = 'LOLIPANTS';

  /// Good evening greeting (English).
  static const String goodEvening = 'Good evening';

  /// Good evening greeting (Arabic).
  static const String goodEveningAr = 'مساء الخير';

  /// Hero eyebrow (English).
  static const String heroAiDesigner = 'AI DESIGNER';

  /// Hero eyebrow (Arabic).
  static const String heroAiDesignerAr = 'مصمم ذكي';

  /// Hero title (English).
  static const String heroDreamOutfit = 'Describe your dream outfit';

  /// Hero title (Arabic).
  static const String heroDreamOutfitAr = 'صف زيّك المثالي';

  /// Hero CTA (English).
  static const String heroTryNow = 'Try now →';

  /// Category pill: All (English).
  static const String categoryAll = 'All';

  /// Category pill: Men (English).
  static const String categoryMen = 'Men';

  /// Category pill: Men (Arabic).
  static const String categoryMenAr = 'رجال';

  /// Category pill: Women (English).
  static const String categoryWomen = 'Women';

  /// Category pill: Women (Arabic).
  static const String categoryWomenAr = 'نساء';

  /// Category pill: Kids (English).
  static const String categoryKids = 'Kids';

  /// Category pill: Kids (Arabic).
  static const String categoryKidsAr = 'أطفال';

  /// Category pill: Wedding (English).
  static const String categoryWedding = 'Wedding';

  /// Category pill: Accessories (English).
  static const String categoryAccessories = 'Accessories';

  /// Section header (English).
  static const String sectionTraditionalStyles = 'Traditional styles';

  /// Section header (Arabic).
  static const String sectionTraditionalStylesAr = 'الأزياء التقليدية';

  /// Home designs strip (English): Gulf, modern, casual mix.
  static const String sectionFeaturedDesigns = 'Featured designs';

  /// Home designs strip (Arabic).
  static const String sectionFeaturedDesignsAr = 'تصاميم مميزة';

  /// See all link (English).
  static const String seeAll = 'See all';

  /// See all link (Arabic).
  static const String seeAllAr = 'عرض الكل';

  /// Style card: Qatari Thobe (English).
  static const String styleQatariThobe = 'Qatari Thobe';

  /// Style card: Saudi Bisht (English).
  static const String styleSaudiBisht = 'Saudi Bisht';

  /// Style card: UAE Kandura (English).
  static const String styleUaeKandura = 'UAE Kandura';

  /// Style card: Omani Dishdasha (English).
  static const String styleOmaniDishdasha = 'Omani Dishdasha';

  /// Origin label sample (English).
  static const String originGulf = 'Gulf';

  /// Browse screen header (English).
  static const String browseHeader = 'Browse designs';

  /// Browse screen header (Arabic).
  static const String browseHeaderAr = 'تصفح التصاميم';

  /// Orders empty title (English).
  static const String ordersEmpty = 'No orders yet';

  /// Orders empty title (Arabic).
  static const String ordersEmptyAr = 'لا توجد طلبات بعد';

  /// Community header (English).
  static const String communityHeader = 'Community';

  /// Community header (Arabic).
  static const String communityHeaderAr = 'المجتمع';

  /// Profile log out (English).
  static const String logOut = 'Log out';

  /// Profile log out (Arabic).
  static const String logOutAr = 'تسجيل الخروج';

  /// Check email after reset (English).
  static const String checkYourEmail = 'Check your email';

  /// Check email after reset (Arabic).
  static const String checkYourEmailAr = 'تحقق من بريدك الإلكتروني';

  /// Forgot password submit success (English).
  static const String backToLogin = 'Back to login';

  /// Forgot password submit success (Arabic).
  static const String backToLoginAr = 'العودة لتسجيل الدخول';

  /// Bottom nav: Community (English).
  static const String navCommunity = 'Community';

  /// Bottom nav: Community (Arabic).
  static const String navCommunityAr = 'المجتمع';

  /// Music player slot label (English).
  static const String musicPlayerLabel = 'Music player';

  /// Expanded player: empty queue title (English).
  static const String musicNoTracksYet = 'No music yet';

  /// Expanded player: empty queue body (English).
  static const String musicEmptyQueueBody =
      'Choose MP3 or other audio files stored on this device. '
      'Your selection is remembered for next time.';

  /// Expanded player: pick local audio files (English).
  static const String musicChooseFiles = 'Choose files';

  /// Expanded player: no current track (English).
  static const String musicNoTrackLoaded = 'No track loaded.';

  /// Expanded player: add more tracks (English).
  static const String musicAddMusic = 'Add music';

  /// Confirm password field (English).
  static const String confirmPassword = 'Confirm password';

  /// Confirm password field (Arabic).
  static const String confirmPasswordAr = 'تأكيد كلمة المرور';

  /// Skip control (English).
  static const String skip = 'Skip';

  /// Skip control (Arabic).
  static const String skipAr = 'تخطي';

  /// Onboarding final CTA (English).
  static const String getStarted = 'Get started';

  /// Onboarding final CTA (Arabic).
  static const String getStartedAr = 'ابدأ';

  /// Good morning greeting (English).
  static const String goodMorning = 'Good morning';

  /// Good morning greeting (Arabic).
  static const String goodMorningAr = 'صباح الخير';

  /// Good afternoon greeting (English).
  static const String goodAfternoon = 'Good afternoon';

  /// Good afternoon greeting (Arabic).
  static const String goodAfternoonAr = 'مساء الخير';

  /// Short tagline (English).
  static const String tagline = 'Enjoy designing your fashion';

  /// Short tagline (Arabic).
  static const String taglineAr = 'استمتع بتصميم أزيائك';

  /// Home: explore all browse (English).
  static const String homeExploreAll = 'Explore all';

  /// Home featured subtitle for the shopper's gender lane (English).
  static String homeFeaturedSubtitleForGender(String? gender) {
    switch (gender) {
      case 'men':
        return "Men's picks for you";
      case 'women':
        return "Women's picks for you";
      default:
        return 'Curated for you';
    }
  }

  /// Home: shop by gender header (English).
  static const String homeShopByGender = 'Shop by category';

  /// Home: shop by gender header (Arabic).
  static const String homeShopByGenderAr = 'تسوّق حسب الفئة';

  /// Home category: Men (English).
  static const String homeCategoryMen = 'Male';

  /// Home category: Men (Arabic).
  static const String homeCategoryMenAr = 'رجال';

  /// Home category: Women (English).
  static const String homeCategoryWomen = 'Female';

  /// Home category: Women (Arabic).
  static const String homeCategoryWomenAr = 'نساء';

  /// Home category: Kids (English).
  static const String homeCategoryKids = 'Kids';

  /// Home category: Kids (Arabic).
  static const String homeCategoryKidsAr = 'أطفال';

  /// Home traditional lane title (English).
  static const String homeTraditionalTitle = 'Traditional fashion';

  /// Home traditional lane title (Arabic).
  static const String homeTraditionalTitleAr = 'الأزياء التقليدية';

  /// Home traditional lane subtitle (English).
  static const String homeTraditionalSubtitle =
      'Choose your country and region to start designing';

  /// Home traditional lane subtitle (Arabic).
  static const String homeTraditionalSubtitleAr =
      'اختر بلدك ومنطقتك لبدء التصميم';

  /// Home accessories lane title (English).
  static const String homeAccessoriesTitle = 'Accessories';

  /// Home accessories lane title (Arabic).
  static const String homeAccessoriesTitleAr = 'إكسسوارات';

  /// Home accessories lane subtitle (English).
  static const String homeAccessoriesSubtitle =
      'Complete your look with scarves, bags, and more';

  /// Home accessories lane subtitle (Arabic).
  static const String homeAccessoriesSubtitleAr =
      'أكمل إطلالتك بالأوشحة والحقائب والمزيد';

  /// Accessories browse: load failure (English).
  static const String accessoriesLoadError = 'Could not load accessories.';

  /// Accessories browse: empty category (English).
  static const String accessoriesEmptyCategory =
      'No accessories in this category yet.';

  /// Accessories filter chip: all (English).
  static const String accessoryFilterAll = 'All';

  /// Accessories filter chip: scarves (English).
  static const String accessoryFilterScarves = 'Scarves';

  /// Accessories filter chip: bags (English).
  static const String accessoryFilterBags = 'Bags';

  /// Accessories filter chip: jewellery (English).
  static const String accessoryFilterJewellery = 'Jewellery';

  /// Accessories filter chip: other (English).
  static const String accessoryFilterOther = 'Other';

  /// Accessory detail route: missing item (English).
  static const String accessoryNotFound = 'Accessory not found';

  /// Home casual / T-shirt lane title (English).
  static const String homeCasualTitle = 'T-shirts & casual';

  /// Home casual / T-shirt lane title (Arabic).
  static const String homeCasualTitleAr = 'قمصان وكاجوال';

  /// Home casual lane subtitle (English).
  static const String homeCasualSubtitle =
      'Add your own text or photo on T-shirts and casual wear';

  /// Home casual lane subtitle (Arabic).
  static const String homeCasualSubtitleAr =
      'أضف نصك أو صورتك على القمصان والملابس الكاجوال';

  /// Home wizard step 1 title (English).
  static const String homeFlowStepGender = 'Who are you designing for?';

  /// Home wizard step 1 title (Arabic).
  static const String homeFlowStepGenderAr = 'لمن تصمّم اليوم؟';

  /// Home wizard step 2 title (English).
  static const String homeFlowStepStyle = 'Choose your style';

  /// Home wizard step 2 title (Arabic).
  static const String homeFlowStepStyleAr = 'اختر أسلوبك';

  /// Home wizard step 3 title (English).
  static const String homeFlowStepService = 'How would you like to create it?';

  /// Home wizard step 3 title (Arabic).
  static const String homeFlowStepServiceAr = 'كيف تريد إنشاء قطعتك؟';

  /// Home style: Modern (English).
  static const String homeFlowStyleModern = 'Modern';

  /// Home style: Modern (Arabic).
  static const String homeFlowStyleModernAr = 'عصري';

  /// Home style: Wedding (English).
  static const String homeFlowStyleWedding = 'Wedding';

  /// Home style: Wedding (Arabic).
  static const String homeFlowStyleWeddingAr = 'عرس';

  /// Wedding style hint for women only (English).
  static const String homeFlowWeddingWomenOnly =
      'Wedding styles are available for women';

  /// Wedding style hint for women only (Arabic).
  static const String homeFlowWeddingWomenOnlyAr =
      'أزياء العرس متاحة للنساء فقط';

  /// Design with yourself card title (English).
  static const String homeFlowDesignYourself = 'Design it yourself';

  /// Design with yourself card title (Arabic).
  static const String homeFlowDesignYourselfAr = 'صمّمها بنفسك';

  /// Design with yourself card body (English).
  static const String homeFlowDesignYourselfBody =
      'Pick fabrics, colours, and details on the mannequin';

  /// Design with yourself card body (Arabic).
  static const String homeFlowDesignYourselfBodyAr =
      'اختر الأقمشة والألوان والتفاصيل على المانيكان';

  /// Finish product card title (English).
  static const String homeFlowFinishProduct = 'Finished product';

  /// Finish product card title (Arabic).
  static const String homeFlowFinishProductAr = 'منتج جاهز';

  /// Finish product card body (English).
  static const String homeFlowFinishProductBody =
      'Choose from our ready-made catalogue designs';

  /// Finish product card body (Arabic).
  static const String homeFlowFinishProductBodyAr =
      'اختر من تصاميم الكتالوج الجاهزة';

  /// Home flow primary CTA (English).
  static const String homeFlowStartDesigning = 'Start designing';

  /// Home flow primary CTA (Arabic).
  static const String homeFlowStartDesigningAr = 'ابدأ التصميم';

  /// Home flow measurements note (English).
  static const String homeFlowMeasurementsNote =
      'You will add your measurements before we tailor your order';

  /// Home flow measurements note (Arabic).
  static const String homeFlowMeasurementsNoteAr =
      'ستضيف مقاساتك قبل أن نبدأ بتفصيل طلبك';

  /// Wedding service step title (English).
  static const String homeFlowStepWeddingFulfillment =
      'How would you like to get your dress?';

  /// Wedding service step title (Arabic).
  static const String homeFlowStepWeddingFulfillmentAr =
      'كيف تريد الحصول على فستانك؟';

  /// Wedding rent choice body (English).
  static const String homeFlowWeddingRentBody =
      'Rent for your event and return the dress after';

  /// Wedding rent choice body (Arabic).
  static const String homeFlowWeddingRentBodyAr =
      'استأجري الفستان لمناسبتك وأعيديه بعدها';

  /// Wedding buy choice body (English).
  static const String homeFlowWeddingBuyBody =
      'Purchase and keep the dress forever';

  /// Wedding buy choice body (Arabic).
  static const String homeFlowWeddingBuyBodyAr =
      'اشترِي الفستان واحتفظي به';

  /// Wedding confirm CTA (English).
  static const String homeFlowBrowseDresses = 'Browse dresses';

  /// Wedding confirm CTA (Arabic).
  static const String homeFlowBrowseDressesAr = 'تصفح الفساتين';

  /// Wedding confirm note (English).
  static const String homeFlowWeddingMeasurementsNote =
      'You will pick a dress, then add your measurements before checkout';

  /// Wedding confirm note (Arabic).
  static const String homeFlowWeddingMeasurementsNoteAr =
      'ستختارين فستاناً ثم تضيفين مقاساتك قبل إتمام الطلب';

  /// Sign-up gender label (English).
  static const String signupGenderLabel = 'I design for';

  /// Sign-up gender label (Arabic).
  static const String signupGenderLabelAr = 'أصمم لـ';

  /// Sign-up profile photo hint (English).
  static const String signupPhotoHint = 'Profile photo (optional)';

  /// Sign-up profile photo hint (Arabic).
  static const String signupPhotoHintAr = 'صورة الملف (اختياري)';

  /// Sign-up gender required error (English).
  static const String signupGenderRequired = 'Please choose a category';

  /// AI designer gender prompt title (English).
  static const String designGenderDialogTitle = 'Who are you designing for?';

  /// AI designer gender prompt body (English).
  static const String designGenderDialogBody =
      'Choose women or men so we can pick the right mannequin and styles.';

  /// AI designer gender prompt body (Arabic).
  static const String designGenderDialogBodyAr =
      'اختر نساء أو رجال لاختيار المانيكان والأنماط المناسبة.';

  /// Accessories: design T-shirt CTA (English).
  static const String accessoriesTshirtCta = 'Design a T-shirt with text or photo';

  /// Accessories: design T-shirt CTA (Arabic).
  static const String accessoriesTshirtCtaAr =
      'صمّم قميصاً بنصك أو صورتك';

  /// Coming soon snack (English).
  static const String comingSoon = 'Coming soon';

  /// Coming soon snack (Arabic).
  static const String comingSoonAr = 'قريباً';

  /// Coming Phase 3 snack (English).
  static const String comingPhase3 = 'Coming in Phase 3';

  /// Coming Phase 4 snack (English).
  static const String comingPhase4 = 'Coming in Phase 4';

  /// Already have account lead-in (English).
  static const String alreadyHaveAccount = 'Already have an account? ';

  /// Already have account lead-in (Arabic).
  static const String alreadyHaveAccountAr = 'لديك حساب بالفعل؟ ';

  /// No account lead-in (English).
  static const String dontHaveAccount = "Don't have an account? ";

  /// No account lead-in (Arabic).
  static const String dontHaveAccountAr = 'ليس لديك حساب؟ ';

  /// Create account primary button combined label.
  static const String createAccountCta = 'Create account';

  /// Log in primary button combined label.
  static const String logInCta = 'Log in';

  /// Forgot password screen title (English).
  static const String resetPasswordTitle = 'Reset password';

  /// Forgot password screen title (Arabic).
  static const String resetPasswordTitleAr = 'إعادة تعيين كلمة المرور';

  /// Inbox confirmation title (English).
  static const String checkYourInbox = 'Check your inbox';

  /// Inbox confirmation title (Arabic).
  static const String checkYourInboxAr = 'تحقق من بريدك الإلكتروني';

  /// Reset email sent body prefix (English).
  static const String resetEmailSentPrefix = "We've sent a reset link to ";

  /// Back to log in secondary CTA (English).
  static const String backToLogIn = 'Back to log in';

  /// Back to log in secondary CTA (Arabic).
  static const String backToLogInAr = 'العودة لتسجيل الدخول';

  /// Orders filter pill (English).
  static const String filter = 'Filter';

  /// Browse subtitle (English).
  static const String chooseYourRegion =
      'Gulf, Levant, Maghreb, modern, casual';

  /// Featured eyebrow (English).
  static const String featuredEyebrow = 'Featured · مميز';

  /// Featured body (English).
  static const String featuredBody =
      'Flat-lay designs from Gulf classics to modern and casual basics.';

  /// Featured row caption (English).
  static const String featuredCollection = 'Gulf collection · 2026';

  /// Log out dialog title (English).
  static const String logOutConfirmTitle = 'Log out?';

  /// Log out dialog title (Arabic).
  static const String logOutConfirmTitleAr = 'تسجيل الخروج؟';

  /// Cancel action (English).
  static const String cancel = 'Cancel';

  /// Cancel action (Arabic).
  static const String cancelAr = 'إلغاء';

  /// Confirm action (English).
  static const String confirm = 'Confirm';

  /// Confirm action (Arabic).
  static const String confirmAr = 'تأكيد';

  /// Profile tile: My designs (English).
  static const String myDesigns = 'My designs';

  /// Profile tile: My designs (Arabic).
  static const String myDesignsAr = 'تصاميمي';

  /// Profile tile: Measurements (English).
  static const String myMeasurements = 'My measurements';

  /// Profile tile: Measurements (Arabic).
  static const String myMeasurementsAr = 'مقاساتي';

  /// Profile tile: Notifications (English).
  static const String notifications = 'Notifications';

  /// Profile tile: Notifications (Arabic).
  static const String notificationsAr = 'الإشعارات';

  /// Profile tile: Settings (English).
  static const String settings = 'Settings';

  /// Profile tile: Settings (Arabic).
  static const String settingsAr = 'الإعدادات';

  /// Validation: invalid email (English).
  static const String errorInvalidEmail = 'Enter a valid email address';

  /// Validation: password too short (English).
  static const String errorPasswordShort =
      'Password must be at least 8 characters';

  /// Validation: password too short (Arabic).
  static const String errorPasswordShortAr =
      'يجب أن تكون كلمة المرور ٨ أحرف على الأقل';

  /// Validation: password needs digit (English).
  static const String errorPasswordDigit = 'Password must include a number';

  /// Validation: passwords mismatch (English).
  static const String errorPasswordMismatch = 'Passwords do not match';

  /// Validation: name too short (English).
  static const String errorNameShort = 'Name must be at least 2 characters';

  /// Generic auth failure (English).
  static const String errorAuthGeneric =
      'Something went wrong. Please try again.';

  /// Generic auth failure (Arabic).
  static const String errorAuthGenericAr =
      'حدث خطأ ما. يرجى المحاولة مرة أخرى.';

  /// Sign-in: wrong email or password (English).
  static const String errorInvalidCredentials =
      'Email or password is incorrect.';

  /// Sign-in: wrong email or password (Arabic).
  static const String errorInvalidCredentialsAr =
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  /// Authenticated action not allowed (English).
  static const String errorForbidden = 'You do not have permission to do that.';

  /// Network: no connection / host unreachable (English).
  static const String errorNetworkUnreachable =
      'Could not reach the server. Check your internet connection and try '
      'again.';

  /// Network: no connection / host unreachable (Arabic).
  static const String errorNetworkUnreachableAr =
      'تعذّر الوصول إلى الخادم. تحقق من اتصال الإنترنت وحاول مرة أخرى.';

  /// Network: request timed out (English).
  static const String errorNetworkTimeout =
      'The request timed out. Check your connection and try again.';

  /// Network: request timed out (Arabic).
  static const String errorNetworkTimeoutAr =
      'انتهت مهلة الطلب. تحقق من الاتصال وحاول مرة أخرى.';

  /// HTTP 502 (English).
  static const String errorHttpBadGateway =
      'Could not reach the authentication service. Try again in a moment.';

  /// HTTP 502 (Arabic).
  static const String errorHttpBadGatewayAr =
      'تعذّر الوصول إلى خدمة المصادقة. حاول بعد قليل.';

  /// HTTP 503 (English).
  static const String errorHttpServiceUnavailable =
      'Sign-in is temporarily unavailable. Please try again shortly.';

  /// HTTP 503 (Arabic).
  static const String errorHttpServiceUnavailableAr =
      'تسجيل الدخول غير متاح مؤقتاً. يرجى المحاولة بعد قليل.';

  /// HTTP 504 (English).
  static const String errorHttpGatewayTimeout =
      'The server took too long to respond. Please try again.';

  /// HTTP 504 (Arabic).
  static const String errorHttpGatewayTimeoutAr =
      'استغرق الخادم وقتاً طويلاً للرد. يرجى المحاولة مرة أخرى.';

  /// HTTP 5xx generic (English).
  static const String errorHttpServerError =
      'Something went wrong on our side. Please try again later.';

  /// HTTP 5xx generic (Arabic).
  static const String errorHttpServerErrorAr =
      'حدث خطأ من جانبنا. يرجى المحاولة لاحقاً.';

  /// `.env` missing `BETTER_AUTH_BASE_URL` (English).
  static const String errorAuthBaseUrlMissing =
      'Sign-in is not configured: add BETTER_AUTH_BASE_URL to your .env '
      'file (see .env.example).';

  /// `.env` missing `BETTER_AUTH_BASE_URL` (Arabic).
  static const String errorAuthBaseUrlMissingAr =
      'تسجيل الدخول غير مُعدّ: أضف BETTER_AUTH_BASE_URL إلى ملف .env '
      '(انظر .env.example).';

  /// `.env` missing `GOOGLE_SERVER_CLIENT_ID` (English).
  static const String errorGoogleServerClientIdMissing =
      'Google sign-in is not configured: add GOOGLE_SERVER_CLIENT_ID to your '
      '.env (your Google Web OAuth client ID; must match GOOGLE_CLIENT_ID on '
      'the auth worker). See server/better-auth-worker/GOOGLE_OAUTH_SETUP.md.';

  /// `.env` missing `GOOGLE_SERVER_CLIENT_ID` (Arabic).
  static const String errorGoogleServerClientIdMissingAr =
      'تسجيل الدخول عبر Google غير مُعدّ: أضف GOOGLE_SERVER_CLIENT_ID إلى '
      'ملف .env (معرّف عميل Google OAuth؛ يجب أن يطابق GOOGLE_CLIENT_ID على '
      'عامل المصادقة).';

  /// Onboarding slide 1 body (English).
  static const String onboardingSlide1Body =
      'Create custom garments on a realistic mannequin';

  /// Onboarding slide 2 body (English).
  static const String onboardingSlide2Body =
      'Traditional Gulf styles, reimagined';

  /// Onboarding slide 3 body (English).
  static const String onboardingSlide3Body =
      'Order and track your garment from stitch to door';

  // --- Partner with Lolipants (role request flow) ---

  /// Partner flow app bar (English).
  static const String partnerTitleEn = 'Partner with Lolipants';

  /// Partner flow app bar (Arabic).
  static const String partnerTitleAr = 'كن شريكاً مع Lolipants';

  /// Partner static header subtitle (English).
  static const String partnerHeaderSubtitleEn =
      'Tailors and delivery partners help us fulfil custom orders. Apply here '
      'and our team will review your details.';

  /// Partner static header subtitle (Arabic).
  static const String partnerHeaderSubtitleAr =
      'يساعدنا الخياطون وشركاء التوصيل في تنفيذ الطلبات المخصصة. قدّم طلبك '
      'وسيراجع فريقنا بياناتك.';

  /// While loading role request history (English).
  static const String partnerLoadingRequests =
      'Loading your previous requests…';

  /// Partner history load failure (English).
  static const String partnerCouldNotLoadRequests = 'Could not load requests.';

  /// Partner history network error (English).
  static const String partnerNetworkError =
      'Network issue. Check your connection and try again.';

  /// Partner history auth error (English).
  static const String partnerSessionExpiredError =
      'Session expired. Sign in again to continue.';

  /// Partner application submit failure (English).
  static const String partnerRequestFailed = 'Request failed.';

  /// Partner application network snackbar (English).
  static const String partnerNetworkErrorShort = 'Network issue.';

  /// Partner application auth snackbar (English).
  static const String partnerSessionIssueShort = 'Session issue.';

  /// Partner review step role label prefix (English).
  static const String partnerReviewRolePrefix = 'Role';

  /// Partner request history status: pending (English).
  static const String partnerStatusPending = 'Pending';

  /// Partner request history status: approved (English).
  static const String partnerStatusApproved = 'Approved';

  /// Partner request history status: rejected (English).
  static const String partnerStatusRejected = 'Rejected';

  /// Retry after load failure (English).
  static const String partnerRetry = 'Retry';

  /// `.env` missing `API_BASE_URL` (English).
  static const String errorApiBaseUrlMissing =
      'The app cannot reach the API: add API_BASE_URL to your .env in the '
      'project root (see .env.example), then restart the app.';

  /// API_BASE_URL points at Better Auth by mistake (English).
  static const String errorApiBaseUrlSameAsAuth =
      'API_BASE_URL must be your lolipants-api worker URL (orders, community, '
      'partner requests). It cannot be the same as BETTER_AUTH_BASE_URL. See '
      '.env.example.';

  /// HTTP 404 on partner / API — often wrong base URL (English).
  static const String partnerError404Hint =
      'This usually means API_BASE_URL is not your lolipants-api server—for '
      'example it was set to the Better Auth worker by mistake. Fix .env and '
      'restart the app.';

  /// Partner welcome step title (English).
  static const String partnerWelcomeTitle = 'How it works';

  /// Partner welcome step body (English).
  static const String partnerWelcomeBody =
      'Choose whether you sew garments in our network or handle deliveries. '
      'We review every application. Typical review time is a few business '
      'days; we will contact you if we need more information.';

  /// Partner welcome step title (Arabic).
  static const String partnerWelcomeTitleAr = 'كيف يعمل';

  /// Partner welcome step body (Arabic).
  static const String partnerWelcomeBodyAr =
      'اختر إن كنت تخيط ضمن شبكتنا أو تتولى التوصيل. نراجع كل طلب. قد يستغرق '
      'المراجعة عدة أيام عمل؛ سنتواصل معك إن احتجنا لمزيد من التفاصيل.';

  /// Partner step: choose path (English).
  static const String partnerChoosePathTitle = 'Choose your path';

  /// Partner step: choose path (Arabic).
  static const String partnerChoosePathTitleAr = 'اختر مسارك';

  /// Tailor path card title (English).
  static const String partnerRoleTailorTitle = 'Tailor partner';

  /// Tailor path card bullets (English).
  static const String partnerRoleTailorBullets =
      '• Work with customer orders in the app\n'
      '• Update tailoring status as you progress\n'
      '• Coordinate with our operations team';

  /// Delivery path card title (English).
  static const String partnerRoleDeliveryTitle = 'Delivery partner';

  /// Delivery path card bullets (English).
  static const String partnerRoleDeliveryBullets =
      '• Pick up and drop off garments\n'
      '• Cover the areas you confirm with us\n'
      '• Follow safe handling guidelines';

  /// Partner details step title (English).
  static const String partnerDetailsTitle = 'Tell us about you';

  /// Partner details step title (Arabic).
  static const String partnerDetailsTitleAr = 'أخبرنا عنك';

  /// Tailor: city / region label (English).
  static const String partnerFieldCityRegion = 'City or region served';

  /// Tailor: years experience label (English).
  static const String partnerFieldYearsExperience = 'Years of experience';

  /// Tailor: workshop name label (English).
  static const String partnerFieldWorkshopName = 'Workshop or studio name '
      '(optional)';

  /// Tailor: portfolio URL label (English).
  static const String partnerFieldPortfolioUrl = 'Portfolio or website '
      '(optional)';

  /// Tailor: specialties label (English).
  static const String partnerFieldSpecialties =
      'Specialties (e.g. bridal, abaya, alterations)';

  /// Delivery: vehicle label (English).
  static const String partnerFieldVehicle = 'Vehicle type';

  /// Delivery: coverage label (English).
  static const String partnerFieldCoverage = 'Coverage areas / zones';

  /// Delivery: availability label (English).
  static const String partnerFieldAvailability =
      'Availability notes (optional)';

  /// Review step title (English).
  static const String partnerReviewTitle = 'Review and submit';

  /// Review step title (Arabic).
  static const String partnerReviewTitleAr = 'راجع وأرسل';

  /// Optional note on review step (English).
  static const String partnerReviewNoteLabel = 'Anything else? (optional)';

  /// Wizard: back (English).
  static const String partnerWizardBack = 'Back';

  /// Wizard: next (English).
  static const String partnerWizardNext = 'Next';

  /// Partner details validation (English).
  static const String partnerDetailsValidation =
      'Please fill in the required fields before continuing.';

  /// Wizard: submit application (English).
  static const String partnerWizardSubmit = 'Submit application';

  /// Done step title (English).
  static const String partnerDoneTitle = 'Application sent';

  /// Done step body (English).
  static const String partnerDoneBody =
      'Thank you. Our team will review your application and reach out if we '
      'need more details.';

  /// Done: back to profile (English).
  static const String partnerDoneBackToProfile = 'Back to profile';

  /// Pending request banner (English).
  static const String partnerPendingBanner =
      'You already have a pending request. We will notify you when it is '
      'reviewed.';

  /// Previous requests section (English).
  static const String partnerPreviousRequests = 'Previous requests';

  /// Empty history (English).
  static const String partnerNoRequestsYet = 'No requests yet.';

  /// Post-approval hint (English).
  static const String partnerPostApprovalHint =
      'If your request is approved, sign out and sign back in so the app opens '
      'the correct home for your new role.';

  /// 409 duplicate pending (English).
  static const String partnerErrorPendingExists =
      'You already have a pending application. Please wait for our team to '
      'review it.';

  /// AI designer label pair (English, short).
  static const String aiDesigner = 'AI Designer';

  /// Describe outfit (English).
  static const String describeOutfit = 'Describe your dream outfit';

  /// Try now CTA (English).
  static const String tryNow = 'Try now →';

  /// Start designing CTA (English).
  static const String startDesigning = 'Start designing';

  /// Start designing CTA (Arabic).
  static const String startDesigningAr = 'ابدأ التصميم';

  /// Global design FAB caption (English).
  static const String fabDesign = 'Design';

  /// Global design FAB caption (Arabic).
  static const String fabDesignAr = 'تصميم';

  /// My orders header (English).
  static const String myOrders = 'My orders';

  /// My orders header (Arabic).
  static const String myOrdersAr = 'طلباتي';

  /// Traditional styles header pair (already have sectionTraditionalStyles).

  /// Track order CTA (English).
  static const String trackOrder = 'Track order';

  /// In progress tag (English).
  static const String inProgress = 'In progress';

  /// Order prefix (English).
  static const String orderPrefix = 'Order #';

  /// Design row label (English).
  static const String designLabel = 'Design';

  /// Tailor row label (English).
  static const String tailorLabel = 'Tailor';

  /// Wedding pill Arabic.
  static const String categoryWeddingAr = 'عرس';

  /// Accessories pill Arabic.
  static const String categoryAccessoriesAr = 'إكسسوارات';

  /// Country: Qatar (English).
  static const String countryQatar = 'Qatar';

  /// Country: Saudi (English).
  static const String countrySaudi = 'Saudi Arabia';

  /// Country: UAE (English).
  static const String countryUae = 'UAE';

  /// Country: Oman (English).
  static const String countryOman = 'Oman';

  /// ISO-style country codes for badges.
  static const String countryCodeQa = 'QA';
  static const String countryCodeSa = 'SA';
  static const String countryCodeAe = 'AE';
  static const String countryCodeOm = 'OM';

  /// Demo tailor meta line (English).
  static const String tailorStripMeta = 'Doha · 4.9 ★';

  /// Garment keywords per country card.
  static const String countryGarmentsQa = 'Thobe · Bisht · Abaya';
  static const String countryGarmentsSa = 'Thobe · Bisht · Kaftan';
  static const String countryGarmentsAe = 'Kandura · Abaya';
  static const String countryGarmentsOm = 'Dishdasha · Kumma';

  /// Phase 3A editor shell strings.
  static const String chooseMannequin =
      'Choose your mannequin / اختر المانيكان';

  /// Mannequin selector app bar (English).
  static const String chooseMannequinEn = 'Choose your mannequin';

  /// Mannequin selector: gallery picker (English).
  static const String mannequinChooseFromGallery = 'Choose from gallery';

  /// Mannequin selector: camera picker (English).
  static const String mannequinTakePhoto = 'Take a photo';

  /// Mannequin selector: upload custom body reference (English).
  static const String mannequinUploadPhotoCta =
      'Upload your photo (AI body reference)';

  /// Mannequin selector: custom photo selected hint (English).
  static const String mannequinCustomPhotoHint =
      'Custom photo selected — used for AI output.';

  static const String startDesigningCta = 'Start designing / ابدأ التصميم';
  static const String editorTitle = 'Design editor / محرر التصميم';
  static const String editorSave = 'Save / حفظ';
  static const String editorSaved = 'Design saved / تم الحفظ';
  static const String editorExitConfirm =
      'Exit without saving? / الخروج بدون حفظ؟';
  static const String editorTabDesigns = 'Designs';
  static const String editorTabBuild = 'Build';
  static const String editorTabBuildAr = 'صمّم';
  static const String editorTabWedding = 'Wedding';
  static const String editorTabWeddingAr = 'عرس';
  static const String weddingFilterAll = 'All';
  static const String weddingFilterBridal = 'Bridal';
  static const String weddingFilterBridesmaids = 'Bridesmaids';
  static const String weddingRent = 'Rent';
  static const String weddingBuy = 'Buy';
  static const String weddingRentalDays = 'Rental days';
  static const String weddingSelectDressHint =
      'Select a dress from the catalogue below';
  static const String weddingCatalogEmpty = 'No dresses available yet';
  static const String weddingCatalogError = 'Could not load wedding dresses';
  static const String weddingRentDress = 'Rent dress';
  static const String weddingBuyDress = 'Buy dress';
  static const String weddingDepositDisclaimer =
      'Insurance deposit is refundable when the dress is returned in good condition.';
  static const String weddingOrderSummaryTitle = 'Wedding order';
  static const String editorBuildSummaryTitle = 'Your design';
  static const String editorBuildPickTemplate = 'Choose a template';
  static const String editorBuildTemplate = 'Garment template';
  static const String editorBuildSelectSlot = 'Pick a part';
  static const String editorBuildChangeStyle = 'Change style';
  static const String editorBuildTabColor = 'Color';
  static const String editorBuildTabColorAr = 'اللون';
  static const String editorBuildColorAiHint =
      'Primary colour applies to all garment layers. Accent applies to trim and overlay panels. AI refined look uses the same colours.';
  static const String editorBuildColorPrimary =
      'Garment colour / لون القماش';
  static const String editorBuildHeroEmpty =
      'Pick a template and options to preview on your mannequin.';
  static const String editorBuildReset = 'Reset build / إعادة ضبط';
  static const String editorBuildResetHint =
      'Choose a template above to add garment parts, or keep mannequin only.';
  static const String editorStyleCatalogMode = 'Design catalog';
  static const String editorTabFabric = 'Fabric';
  static const String editorAddText = 'Add text / أضف نصاً';
  static const String editorAddImage = 'Add image / أضف صورة';
  static const String editorTabPattern = 'Pattern';
  static const String editorTabEmbroidery = 'Embroidery';
  static const String editorTabText = 'Text';
  static const String editorTabAi = 'AI';

  /// Hero: flat catalogue source vs on-model AI render.
  static const String editorHeroCompose = 'Flat design / التصميم المسطح';
  static const String editorHeroAiLook = 'On model / على المانيكان';
  static const String editorStudioPromptTitle =
      'Describe how to change it / صف كيف تريد تعديله';
  static const String editorStudioPromptSubtitle =
      'We combine your pick, your words, and our style guide for the preview.';
  static const String editorHeroAiOutputEmpty =
      'Generate to see this design on a model / اضغط إنشاء لعرض التصميم على المانيكان';
  static const String editorGenerateLook = 'Generate look';
  static const String editorAiRenderQuota =
      'AI renders left this week: {remaining}/{limit}';
  static const String editorAiRenderQuotaEmpty =
      'No AI renders left this week. Try again after your quota resets.';
  static const String editorLookGenerating = 'Creating preview…';
  static const String editorLookDisclaimer =
      'Preview is AI-generated and illustrative only.';
  static const String editorSketchOptional =
      'Optional silhouette sketch for AI / رسم اختياري';
  static const String editorSketchClear = 'Remove sketch';

  static const String editorExit = 'Exit';
  static const String editorOrder = 'Order';
  static const String editorMoreMenu = 'More';
  static const String editorSaveDesignTitle = 'Save design';
  static const String editorDesignNameHint = 'Name shown in My designs';
  static const String editorDesignNameRequired = 'Design name is required.';
  static const String editorCurrentDesign = 'Current design';
  static const String editorLookGeneratedSnack =
      'Look generated — switch to the AI preview';
  static const String editorLookGeneratedPreview =
      'Look generated. Check preview above.';
  static const String editorShareImage = 'Share image';
  static const String editorSaveImage = 'Save image';
  static const String editorShareToCommunity = 'Share to community';
  static const String editorPublishEarn = 'Publish & earn';
  static const String editorPublishShowcaseSubtitle =
      'List on orderable Showcase';
  static const String editorCapturePreviewFailed =
      'Could not capture design preview.';
  static const String editorShareImageCaption = 'My Lolipants design';
  static const String editorSavedImageToPath = 'Saved to {path}';
  static const String editorSaveBeforePublish =
      'Save the design before publishing.';
  static const String editorDone = 'Done';
  static const String editorTextTypeHint = 'Type your text';
  static const String editorTextAddToDesign = 'Add to design';
  static const String editorTextLayers = 'Layers';
  static const String editorTextFont = 'Font';
  static const String editorTextSizePrefix = 'Size';
  static const String editorTextRotationPrefix = 'Rotation';
  static const String editorTextColour = 'Colour';
  static const String editorTextDragHint =
      'Drag the text on the garment to reposition';
  static const String editorTextRemove = 'Remove text';
  static const String editorPrintOnGarment = 'Print on garment';
  static const String editorUploadImage = 'Upload image';
  static const String editorUploadSketch = 'Upload sketch';
  static const String editorPrintPlacementChest = 'Chest';
  static const String editorPrintPlacementBack = 'Back';
  static const String editorPrintPlacementFullFront = 'Full front';
  static const String editorPrintOffsetHorizontal = 'Horizontal offset';
  static const String editorPrintOffsetVertical = 'Vertical offset';
  static const String editorPrintSizePercent = 'Size';
  static const String editorApplyToDesign = 'Apply to design';
  static const String editorAccessoriesUnavailable =
      'Accessories are not available in this build.';
  static const String editorAddAccessories = 'Add accessories';
  static const String editorAccessoriesSubtitle =
      'Optional items included with your garment order.';
  static const String editorAccessoriesLoadError = 'Could not load accessories.';
  static const String editorAccessoriesEmpty = 'No add-on accessories available.';
  static const String editorStyleYourPiece = 'Style your piece';
  static const String editorStyleColourHint =
      'Choose a colour — changes apply to your design right away.';
  static const String editorMoreColours = 'More colours…';
  static const String editorQualityTier = 'Quality tier';
  static const String editorQualityStandard = 'Standard';
  static const String editorQualityPremium = 'Premium';
  static const String editorQualitySuitGrade = 'Suit grade';
  static const String editorCustomColour = 'Custom colour';
  static const String editorTapToFineTune = 'Tap to fine-tune';
  static const String editorBuildCatalogError = 'Could not load build catalogue.';
  static const String editorDesignCatalogError =
      'Could not load design catalogue.';
  static const String editorNoOptionsForCombination =
      'No options available for this combination.';
  static const String editorBackToParts = 'Back to parts';
  static const String editorEnhanceWithAi = 'Enhance with AI';
  static const String editorAiRequestFailed = 'AI request failed';
  static const String editorAiApplyFailed = 'Could not apply AI suggestion.';
  static const String editorShareCommunityPrefillNew =
      'Check out my new {garmentType} design.';
  static const String editorShareCommunityPrefillNamed =
      'Just designed {name}.';

  /// Phase 3C sizing title.
  static const String sizingOptions = 'Sizing options / خيارات القياس';
  static const String sizingQuestion =
      'How would you like to be measured? / كيف تريد أخذ مقاساتك؟';
  static const String sizingAiOption = 'AI measurement / قياس ذكي';
  static const String sizingManualOption = 'Enter manually / إدخال يدوي';
  static const String sizingWorkshopOption = 'Visit workshop / زيارة الورشة';
  static const String sizingAiSubtitle = 'Use your camera for instant sizing';
  static const String sizingManualSubtitle = 'Type in your measurements';
  static const String sizingWorkshopSubtitle = 'Book workshop or home visit';
  static const String sizingUseSaved =
      'Use saved measurements / استخدم المقاسات المحفوظة';

  /// Phase 3C AI measurement strings.
  static const String aiMeasurementTitle = 'AI measurement / قياس ذكي';
  static const String aiMeasurementInstructions = 'Instructions / التعليمات';
  static const String aiMeasurementStep1 = '1. Stand 2 metres from the camera';
  static const String aiMeasurementStep2 = '2. Wear fitted clothing';
  static const String aiMeasurementStep3 =
      '3. Stand straight with arms slightly out';
  static const String aiMeasurementStep4 =
      "4. We'll calculate your measurements automatically";

  /// Arabic: [aiMeasurementStep4].
  static const String aiMeasurementStep4Ar =
      '٤. سنحسب مقاساتك تلقائياً';
  static const String aiMeasurementStartScan = 'Start scan / بدء المسح';
  static const String aiMeasurementCameraScan = 'Camera scan / مسح الكاميرا';
  static const String aiMeasurementAlignHint =
      'Align your full body with the silhouette before scanning. '
      '/ حاذِ جسمك بالكامل مع المخطط قبل المسح.';
  static const String aiMeasurementAnalyse = 'Analyse / تحليل';
  static const String aiMeasurementEstimated =
      'Estimated measurements / المقاسات التقديرية';
  static const String aiMeasurementVerifyHint =
      'These are estimates - please verify before ordering. '
      '/ هذه تقديرات - يرجى التحقق قبل الطلب.';
  static const String aiMeasurementSave = 'Save measurements / حفظ المقاسات';
  static const String aiMeasurementManualFallback =
      'Enter manually instead / إدخال يدوي بدلاً من ذلك';
  static const String aiMeasurementCameraPermissionDenied =
      'Camera permission denied. Please allow camera access.';
  static const String aiMeasurementNoCamera =
      'No camera available on this device. / لا توجد كاميرا متاحة.';
  static const String aiMeasurementCameraInitFailed =
      'Could not initialize camera. / تعذر تهيئة الكاميرا.';
  static const String aiMeasurementCameraNotReady =
      'Camera is not ready yet. Please wait a moment. / الكاميرا غير جاهزة بعد.';
  static const String aiMeasurementEstimateFailed =
      'Could not estimate measurements.';
  static const String aiMeasurementCaptureFailed =
      'Camera capture failed. Please try again. / فشل التقاط الصورة.';
  static const String aiMeasurementSaveFailed = 'Could not save measurements.';
  static const String aiMeasurementSaved =
      'Measurements saved / تم حفظ المقاسات';
  static const String aiMeasurementAnalysing = 'Analysing…';

  /// Phase 3C manual entry strings.
  static const String manualMeasurementsTitle =
      'Enter your measurements / أدخل مقاساتك';
  static const String manualMeasurementsSubtitle =
      'All measurements in centimetres / جميع المقاسات بالسنتيمتر';
  static const String manualSave = 'Save / حفظ';
  static const String manualErrorAtLeastOne =
      'Enter at least one measurement. / أدخل قياسًا واحدًا على الأقل.';
  static const String manualErrorMax300 =
      'Measurements must be 300cm or less. / يجب أن تكون ٣٠٠ سم أو أقل.';
  static const String manualSaveFailed =
      'Could not save measurements. / تعذر حفظ المقاسات.';
  static const String manualSaved = 'Measurements saved. / تم حفظ المقاسات.';

  /// Phase 3C workshop booking strings.
  static const String workshopTitle = 'Book a sizing visit / احجز موعد قياس';
  static const String workshopVisitOption = 'Visit workshop / زيارة الورشة';
  static const String workshopHomeOption = 'We come to you / نأتي إليك';
  static const String workshopAddressLabel = 'Address / العنوان';
  static const String workshopCityLabel = 'City / المدينة';
  static const String workshopDirectionsLabel =
      'Additional directions / إرشادات إضافية';
  static const String workshopVisitAddress =
      'Workshop visit at Lolipants Atelier, Doha';
  static const String workshopPickDate = 'Pick date / اختر التاريخ';
  static const String workshopConfirm = 'Confirm booking / تأكيد الحجز';
  static const String workshopDateRequired =
      'Please pick a date. / يرجى اختيار التاريخ.';
  static const String workshopAddressRequired =
      'Address is required for home visit. / العنوان مطلوب للزيارة المنزلية.';
  static const String workshopConfirmFailed =
      'Could not confirm booking. / تعذر تأكيد الحجز.';
  static const String workshopConfirmedPrefix = 'Booking confirmed:';
  static const String workshopConfirmedArPrefix = 'تم تأكيد الحجز:';

  /// Phase 3C my measurements strings.
  static const String myMeasurementsSummaryTitle = 'My measurements / مقاساتي';
  static const String measurementUnknown = 'Unknown';
  static const String measurementChest = 'Chest';
  static const String measurementWaist = 'Waist';
  static const String measurementHips = 'Hips';
  static const String measurementShoulderWidth = 'Shoulder width';
  static const String measurementHeight = 'Height';
  static const String measurementArmLength = 'Arm length';
  static const String measurementPreferredSize = 'Preferred size';
  static const String measurementUnitCm = 'cm';
  static const String myMeasurementsLastUpdatedPrefix = 'Last updated:';
  static const String myMeasurementsLastUpdatedAr = 'آخر تحديث';
  static const String myMeasurementsEdit = 'Edit measurements / تعديل المقاسات';
  static const String myMeasurementsRescan =
      'Re-scan with AI / إعادة المسح بالذكاء الاصطناعي';
  static const String myMeasurementsEmpty =
      'No measurements saved yet / لا توجد مقاسات محفوظة بعد';
  static const String myMeasurementsTakeNow = 'Take measurements / قياس الآن';
  static const String sizingOptionsTooltip = 'Sizing options';

  /// Phase 3C AI prompt bar strings.
  static const String aiPromptLabel = 'Describe your idea... / صف فكرتك...';
  static const String aiGenerating =
      'Generating design... / جاري توليد التصميم...';
  static const String aiCreateFailed =
      "Couldn't generate design. Try again. / تعذّر إنشاء التصميم. حاول مرة أخرى.";
  static const String aiApply = 'Apply to design / تطبيق';
  static const String aiTryAgain = 'Try again / حاول مرة أخرى';
  static const String aiDraftCreated =
      'AI draft created in My Designs / تم إنشاء مسودة بالذكاء الاصطناعي';

  /// After applying AI suggestion to live editor mannequin.
  static const String aiAppliedToDesign =
      'Applied to design / تم التطبيق على التصميم';

  // --- Settings hub (Profile → Settings) ---

  /// Settings screen title (English).
  static const String settingsScreenTitle = 'Settings';

  /// Settings screen title (Arabic).
  static const String settingsScreenTitleAr = 'الإعدادات';

  /// Section: General (English).
  static const String settingsSectionGeneral = 'General';

  /// Section: General (Arabic).
  static const String settingsSectionGeneralAr = 'عام';

  /// Section: Appearance (English).
  static const String settingsSectionAppearance = 'Appearance';

  /// Section: Appearance (Arabic).
  static const String settingsSectionAppearanceAr = 'المظهر';

  /// Section: Notifications (English).
  static const String settingsSectionNotifications = 'Notifications';

  /// Section: Notifications (Arabic).
  static const String settingsSectionNotificationsAr = 'الإشعارات';

  /// Section: Media (English).
  static const String settingsSectionMedia = 'Media';

  /// Section: Media (Arabic).
  static const String settingsSectionMediaAr = 'الوسائط';

  /// Section: Privacy & legal (English).
  static const String settingsSectionPrivacy = 'Privacy & legal';

  /// Section: Privacy & legal (Arabic).
  static const String settingsSectionPrivacyAr = 'الخصوصية والقانون';

  /// Section: Support (English).
  static const String settingsSectionSupport = 'Support';

  /// Section: Support (Arabic).
  static const String settingsSectionSupportAr = 'الدعم';

  /// Section: Account (English).
  static const String settingsSectionAccount = 'Account';

  /// Section: Account (Arabic).
  static const String settingsSectionAccountAr = 'الحساب';

  /// Section: About (English).
  static const String settingsSectionAbout = 'About';

  /// Section: About (Arabic).
  static const String settingsSectionAboutAr = 'حول التطبيق';

  /// Language row label (English).
  static const String settingsLanguageLabel = 'Language';

  /// Language row label (Arabic).
  static const String settingsLanguageLabelAr = 'اللغة';

  /// Text size label (English).
  static const String settingsTextSizeLabel = 'Text size';

  /// Text size label (Arabic).
  static const String settingsTextSizeLabelAr = 'حجم النص';

  /// Text size: compact (English).
  static const String settingsTextSizeCompact = 'Compact';

  /// Text size: compact (Arabic).
  static const String settingsTextSizeCompactAr = 'مدمج';

  /// Text size: default (English).
  static const String settingsTextSizeNormal = 'Default';

  /// Text size: default (Arabic).
  static const String settingsTextSizeNormalAr = 'افتراضي';

  /// Text size: comfortable (English).
  static const String settingsTextSizeComfortable = 'Comfortable';

  /// Text size: comfortable (Arabic).
  static const String settingsTextSizeComfortableAr = 'مريح';

  /// Text size: large (English).
  static const String settingsTextSizeLarge = 'Large';

  /// Text size: large (Arabic).
  static const String settingsTextSizeLargeAr = 'كبير';

  /// Reduce motion switch (English).
  static const String settingsReduceMotionTitle = 'Reduce motion';

  /// Reduce motion switch (Arabic).
  static const String settingsReduceMotionTitleAr = 'تقليل الحركة';

  /// Reduce motion subtitle (English).
  static const String settingsReduceMotionSubtitle =
      'Less animation in the interface.';

  /// Reduce motion subtitle (Arabic).
  static const String settingsReduceMotionSubtitleAr = 'حركة أقل في الواجهة.';

  /// Push master toggle title (English).
  static const String settingsPushTitle = 'Push notifications';

  /// Push master toggle title (Arabic).
  static const String settingsPushTitleAr = 'إشعارات الدفع';

  /// Push master toggle subtitle (English).
  static const String settingsPushSubtitle =
      'Order updates, delivery status, and important alerts.';

  /// Push master toggle subtitle (Arabic).
  static const String settingsPushSubtitleAr =
      'تحديثات الطلب والتوصيل والتنبيهات المهمة.';

  /// Push unavailable: OneSignal not configured (English).
  static const String settingsPushUnavailable =
      'Push is not configured in this build.';

  /// Push unavailable (Arabic).
  static const String settingsPushUnavailableAr =
      'الإشعارات غير مفعّلة في هذا الإصدار.';

  /// Permission denied snack (English).
  static const String settingsPushPermissionDenied =
      'Notification permission was not granted.';

  /// Permission denied snack (Arabic).
  static const String settingsPushPermissionDeniedAr =
      'لم يُمنح إذن الإشعارات.';

  /// Shared permission dialog actions.
  static const String permissionNotNow = 'Not now';
  static const String permissionContinue = 'Continue';
  static const String permissionOpenSettings = 'Open Settings';

  static const String permissionCameraTitle = 'Use your camera?';
  static const String permissionCameraMessage =
      'Lolipants needs camera access for AI measurements, delivery proof '
      'photos, and custom mannequin photos.';
  static const String permissionCameraDeniedTitle = 'Camera access off';
  static const String permissionCameraDeniedMessage =
      'Enable camera access in Settings to use this feature.';

  static const String permissionPhotosTitle = 'Access your photos?';
  static const String permissionPhotosMessage =
      'Lolipants needs photo library access to add prints, profile pictures, '
      'and community images.';
  static const String permissionPhotosDeniedTitle = 'Photo access off';
  static const String permissionPhotosDeniedMessage =
      'Enable photo library access in Settings to choose images.';

  static const String permissionLocationTitle = 'Use your location?';
  static const String permissionLocationMessage =
      'Your location helps us assign the nearest tailor and calculate '
      'accurate delivery pricing.';
  static const String permissionLocationDeniedTitle = 'Location access off';
  static const String permissionLocationDeniedMessage =
      'Enable location access in Settings for the best tailor match.';

  static const String permissionNotificationsTitle = 'Enable notifications?';
  static const String permissionNotificationsMessage =
      'Get order updates, delivery alerts, and important messages about '
      'your designs.';
  static const String permissionNotificationsDeniedTitle =
      'Notifications off';
  static const String permissionNotificationsDeniedMessage =
      'Enable notifications in Settings to receive order and delivery updates.';

  static const String permissionAudioTitle = 'Access your music files?';
  static const String permissionAudioMessage =
      'Lolipants needs access to audio files on your device for the in-app '
      'music player.';
  static const String permissionAudioDeniedTitle = 'Storage access off';
  static const String permissionAudioDeniedMessage =
      'Enable storage or audio access in Settings to import tracks.';

  /// Third-party AI disclosure title (English).
  static const String aiConsentTitle = 'Share data with AI partners?';

  /// Third-party AI disclosure body (English).
  static const String aiConsentMessage =
      'Some Lolipants features send data to third-party AI providers '
      '(Google Gemini and OpenAI) to generate design suggestions, on-model '
      'previews, and body measurement estimates.\n\n'
      'Data that may be sent includes: text prompts you enter, design preview '
      'images, garment type and colour choices, configurator selections, '
      'optional gender preference, and camera photos you choose for AI '
      'measurements.\n\n'
      'We send this data only when you use an AI feature. You can withdraw '
      'consent anytime in Settings → Privacy & legal. See our Privacy Policy '
      'for how these providers handle your data.';

  /// Decline third-party AI sharing (English).
  static const String aiConsentDecline = 'Not now';

  /// Agree to third-party AI sharing (English).
  static const String aiConsentAgree = 'Agree and continue';

  /// Settings: revoke AI consent title (English).
  static const String settingsAiConsentTitle = 'Third-party AI sharing';

  /// Settings: revoke AI consent subtitle when enabled (English).
  static const String settingsAiConsentEnabledSubtitle =
      'Allowed — tap to withdraw consent';

  /// Settings: revoke AI consent subtitle when disabled (English).
  static const String settingsAiConsentDisabledSubtitle =
      'Not allowed — you will be asked again before AI features run';

  /// Snackbar after revoking AI consent (English).
  static const String settingsAiConsentRevoked =
      'AI sharing consent withdrawn';

  /// Privacy policy link (English).
  static const String settingsPrivacyPolicy = 'Privacy policy';

  /// Privacy policy link (Arabic).
  static const String settingsPrivacyPolicyAr = 'سياسة الخصوصية';

  /// Terms link (English).
  static const String settingsTermsOfService = 'Terms of service';

  /// Terms link (Arabic).
  static const String settingsTermsOfServiceAr = 'شروط الخدمة';

  /// Open-source licenses tile (English).
  static const String settingsOpenSourceLicenses = 'Open-source licenses';

  /// Open-source licenses tile (Arabic).
  static const String settingsOpenSourceLicensesAr = 'تراخيص البرمجيات';

  /// Help center tile (English).
  static const String settingsHelpCenter = 'Help center';

  /// Help center tile (Arabic).
  static const String settingsHelpCenterAr = 'مركز المساعدة';

  /// FAQ tile (English).
  static const String settingsFaq = 'FAQ';

  /// FAQ tile (Arabic).
  static const String settingsFaqAr = 'الأسئلة الشائعة';

  /// Contact support tile (English).
  static const String settingsContactSupport = 'Contact support';

  /// Contact support tile (Arabic).
  static const String settingsContactSupportAr = 'تواصل مع الدعم';

  /// App version row title (English).
  static const String settingsAppVersion = 'App version';

  /// App version row title (Arabic).
  static const String settingsAppVersionAr = 'إصدار التطبيق';

  /// Version loading placeholder (English).
  static const String settingsVersionLoading = 'Loading…';

  /// Version loading placeholder (Arabic).
  static const String settingsVersionLoadingAr = 'جاري التحميل…';

  /// API base debug label (English).
  static const String settingsApiBaseDebug = 'API base (debug)';

  /// API base debug label (Arabic).
  static const String settingsApiBaseDebugAr = 'عنوان API (تصحيح)';

  /// Clear music queue tile (English).
  static const String settingsClearMusicQueue = 'Clear music queue';

  /// Clear music queue tile (Arabic).
  static const String settingsClearMusicQueueAr = 'مسح قائمة الموسيقى';

  /// Clear music queue subtitle (English).
  static const String settingsClearMusicQueueSubtitle =
      'Remove saved tracks from this device.';

  /// Clear music queue subtitle (Arabic).
  static const String settingsClearMusicQueueSubtitleAr =
      'إزالة المسارات المحفوظة من هذا الجهاز.';

  /// Clear music confirm title (English).
  static const String settingsClearMusicConfirmTitle = 'Clear music queue?';

  /// Clear music confirm title (Arabic).
  static const String settingsClearMusicConfirmTitleAr = 'مسح قائمة الموسيقى؟';

  /// Clear music confirm body (English).
  static const String settingsClearMusicConfirmBody =
      'Saved tracks will be removed from the app.';

  /// Clear music confirm body (Arabic).
  static const String settingsClearMusicConfirmBodyAr =
      'ستُزال المسارات المحفوظة من التطبيق.';

  /// After clearing music queue (English).
  static const String settingsMusicQueueCleared = 'Music queue cleared.';

  /// After clearing music queue (Arabic).
  static const String settingsMusicQueueClearedAr = 'تم مسح قائمة الموسيقى.';

  /// Edit profile shortcut (English).
  static const String settingsEditProfile = 'Edit profile';

  /// Edit profile shortcut (Arabic).
  static const String settingsEditProfileAr = 'تعديل الملف';

  /// Sign out from settings (English).
  static const String settingsSignOut = 'Sign out';

  /// Sign out from settings (Arabic).
  static const String settingsSignOutAr = 'تسجيل الخروج';

  /// Delete account button (English).
  static const String settingsDeleteAccount = 'Delete account';

  /// Delete account button (Arabic).
  static const String settingsDeleteAccountAr = 'حذف الحساب';

  /// Deleting account progress (English).
  static const String settingsDeletingAccount = 'Deleting…';

  /// Deleting account progress (Arabic).
  static const String settingsDeletingAccountAr = 'جاري الحذف…';

  /// Delete account failed snack (English).
  static const String settingsDeleteAccountFailed = 'Could not delete account.';

  /// Delete account failed snack (Arabic).
  static const String settingsDeleteAccountFailedAr = 'تعذر حذف الحساب.';

  /// Delete account dialog title (English).
  static const String settingsDeleteDialogTitle = 'Delete account?';

  /// Delete account dialog title (Arabic).
  static const String settingsDeleteDialogTitleAr = 'حذف الحساب؟';

  /// Delete account dialog body (English).
  static const String settingsDeleteDialogBody =
      'This removes your profile, designs, and measurements. Active orders '
      'continue to completion. This cannot be undone.';

  /// Delete account dialog body (Arabic).
  static const String settingsDeleteDialogBodyAr =
      'سيؤدي ذلك إلى إزالة ملفك وتصاميمك ومقاساتك. الطلبات النشطة تُستكمل. '
      'لا يمكن التراجع.';

  /// Delete account dialog confirm (English).
  static const String settingsDeleteDialogConfirm = 'Delete';

  /// Delete account dialog confirm (Arabic).
  static const String settingsDeleteDialogConfirmAr = 'حذف';

  /// Default help center URL.
  static const String settingsDefaultHelpUrl =
      'https://loli-pants.com/help';

  /// Default FAQ URL.
  static const String settingsDefaultFaqUrl = 'https://loli-pants.com/help';

  /// Default mailto for support.
  static const String settingsDefaultSupportMailto =
      'mailto:support@lolipants.com';

  /// Default privacy policy URL.
  static const String settingsDefaultPrivacyUrl =
      'https://lolipants.com/privacy';

  /// Default terms URL.
  static const String settingsDefaultTermsUrl = 'https://lolipants.com/terms';
  // --- Arabic (pass 2: multiline / missed) ---

  /// Arabic: [chooseYourRegion].
  static const String chooseYourRegionAr = 'الخليج، الشام، المغرب العربي، عصري، كاجوال';

  /// Arabic: [featuredBody].
  static const String featuredBodyAr = 'تصاميم مسطّحة من الكلاسيكيات الخليجية إلى الأساسيات العصرية والكاجوال.';

  /// Arabic: [onboardingSlide1Body].
  static const String onboardingSlide1BodyAr = 'صمّم ملابس مخصصة على مانيكان واقعي';

  /// Arabic: [onboardingSlide2Body].
  static const String onboardingSlide2BodyAr = 'أزياء خليجية تقليدية بروح عصرية';

  /// Arabic: [onboardingSlide3Body].
  static const String onboardingSlide3BodyAr = 'اطلب وتابع قطعتك من الخياطة إلى بابك';

  /// Arabic: [partnerLoadingRequests].
  static const String partnerLoadingRequestsAr = 'جارٍ تحميل طلباتك السابقة…';

  /// Arabic: [partnerError404Hint].
  static const String partnerError404HintAr = 'غالباً يعني أن API_BASE_URL ليس خادم lolipants-api—راجع ملف .env وأعد تشغيل التطبيق.';

  /// Arabic: [partnerRoleTailorBullets].
  static const String partnerRoleTailorBulletsAr =
      '• العمل على طلبات العملاء في التطبيق\n• تحديث حالة الخياطة أثناء التقدم\n• التنسيق مع فريق العمليات';

  /// Arabic: [partnerRoleDeliveryBullets].
  static const String partnerRoleDeliveryBulletsAr =
      '• استلام وتسليم الملابس\n• تغطية المناطق المتفق عليها\n• اتباع إرشادات التعامل الآمن';

  /// Arabic: [partnerFieldSpecialties].
  static const String partnerFieldSpecialtiesAr = 'التخصصات (مثل عرائس، عبايات، تعديلات)';

  /// Arabic: [partnerFieldAvailability].
  static const String partnerFieldAvailabilityAr = 'ملاحظات التوفر (اختياري)';

  /// Arabic: [partnerDetailsValidation].
  static const String partnerDetailsValidationAr = 'يرجى تعبئة الحقول المطلوبة قبل المتابعة.';

  /// Arabic: [partnerDoneBody].
  static const String partnerDoneBodyAr = 'شكراً لك. سيراجع فريقنا طلبك ويتواصل معك إن احتجنا لمزيد من التفاصيل.';

  /// Arabic: [partnerPendingBanner].
  static const String partnerPendingBannerAr = 'لديك طلب قيد المراجعة. سنُخبرك عند الانتهاء.';

  /// Arabic: [partnerPostApprovalHint].
  static const String partnerPostApprovalHintAr = 'إذا وُوفق على طلبك، سجّل الخروج ثم ادخل مجدداً لفتح الصفحة المناسبة لدورك.';

  /// Arabic: [partnerErrorPendingExists].
  static const String partnerErrorPendingExistsAr = 'لديك طلب قيد المراجعة بالفعل. يرجى انتظار مراجعة الفريق.';

  /// Arabic: [weddingSelectDressHint].
  static const String weddingSelectDressHintAr = 'اختر فستاناً من الكتالوج أدناه';

  /// Arabic: [weddingDepositDisclaimer].
  static const String weddingDepositDisclaimerAr = 'التأمين قابل للاسترداد عند إعادة الفستان بحالة جيدة.';

  /// Arabic: [editorBuildColorAiHint].
  static const String editorBuildColorAiHintAr = 'اللون الأساسي يُطبَّق على كل طبقات القطعة. لون التمييز للحواف واللوحات. المعاينة بالذكاء الاصطناعي تستخدم نفس الألوان.';

  /// Arabic: [editorBuildHeroEmpty].
  static const String editorBuildHeroEmptyAr = 'اختر قالباً وخيارات لمعاينة المانيكان.';

  /// Arabic: [editorBuildResetHint].
  static const String editorBuildResetHintAr = 'اختر قالباً أعلاه لإضافة أجزاء القطعة، أو أبقِ المانيكان فقط.';

  /// Arabic: [editorStudioPromptSubtitle].
  static const String editorStudioPromptSubtitleAr = 'نجمع اختيارك وكلماتك ودليل الأسلوب للمعاينة.';

  /// Arabic: [editorAiRenderQuota].
  static const String editorAiRenderQuotaAr = 'معاينات الذكاء الاصطناعي المتبقية هذا الأسبوع: {remaining}/{limit}';

  /// Arabic: [editorAiRenderQuotaEmpty].
  static const String editorAiRenderQuotaEmptyAr = 'لا توجد معاينات متبقية هذا الأسبوع. حاول بعد إعادة ضبط الحصة.';

  /// Arabic: [editorLookDisclaimer].
  static const String editorLookDisclaimerAr = 'المعاينة مُنشأة بالذكاء الاصطناعي وللتوضيح فقط.';

  /// Arabic: [aiMeasurementStep3].
  static const String aiMeasurementStep3Ar = 'راجع المقاسات المقدّرة وعدّلها إن لزم';

  /// Arabic: [aiMeasurementCameraPermissionDenied].
  static const String aiMeasurementCameraPermissionDeniedAr = 'يلزم إذن الكاميرا للمسح';

  /// Arabic: [aiMeasurementEstimateFailed].
  static const String aiMeasurementEstimateFailedAr = 'تعذّر تقدير المقاسات من الصور';

  /// Arabic: [workshopVisitAddress].
  static const String workshopVisitAddressAr = 'عنوان الورشة';

  /// Arabic: [permissionCameraMessage].
  static const String permissionCameraMessageAr = 'نستخدم الكاميرا لالتقاط صور القياس والتصميم.';

  /// Arabic: [permissionCameraDeniedMessage].
  static const String permissionCameraDeniedMessageAr = 'فعّل الكاميرا من إعدادات الجهاز لمتابعة المسح.';

  /// Arabic: [permissionPhotosMessage].
  static const String permissionPhotosMessageAr = 'نستخدم الصور لاختيار صور من المعرض.';

  /// Arabic: [permissionPhotosDeniedMessage].
  static const String permissionPhotosDeniedMessageAr = 'فعّل الوصول إلى الصور من إعدادات الجهاز.';

  /// Arabic: [permissionLocationMessage].
  static const String permissionLocationMessageAr = 'الموقع يساعدنا في إيجاد خياطين وورش قريبة.';

  /// Arabic: [permissionLocationDeniedMessage].
  static const String permissionLocationDeniedMessageAr = 'فعّل الموقع من إعدادات الجهاز للمتابعة.';

  /// Arabic: [permissionNotificationsMessage].
  static const String permissionNotificationsMessageAr = 'الإشعارات تُبقيك على اطلاع بحالة طلبك.';

  /// Arabic: [permissionNotificationsDeniedTitle].
  static const String permissionNotificationsDeniedTitleAr = 'الإشعارات معطّلة';

  /// Arabic: [permissionNotificationsDeniedMessage].
  static const String permissionNotificationsDeniedMessageAr = 'فعّل الإشعارات من إعدادات الجهاز لمتابعة الطلب.';

  /// Arabic: [permissionAudioMessage].
  static const String permissionAudioMessageAr = 'الميكروفون يساعد في الأوامر الصوتية.';

  /// Arabic: [permissionAudioDeniedMessage].
  static const String permissionAudioDeniedMessageAr = 'فعّل الميكروفون من إعدادات الجهاز للمتابعة.';

  /// Arabic: [aiConsentTitle].
  static const String aiConsentTitleAr = 'مشاركة البيانات مع شركاء الذكاء الاصطناعي؟';

  /// Arabic: [aiConsentMessage].
  static const String aiConsentMessageAr =
      'بعض ميزات لوليبانتس ترسل بيانات إلى مزودي ذكاء اصطناعي تابعين لجهات خارجية '
      '(Google Gemini وOpenAI) لإنشاء اقتراحات تصميم ومعاينات على المانيكان '
      'وتقديرات قياس الجسم.\n\n'
      'قد تشمل البيانات المرسلة: النصوص التي تدخلها، صور معاينة التصميم، نوع '
      'الثوب والألوان، اختيارات المُكوِّن، تفضيل الجنس الاختياري، وصور الكاميرا '
      'التي تختارها للقياس بالذكاء الاصطناعي.\n\n'
      'نرسل هذه البيانات فقط عند استخدام ميزة ذكاء اصطناعي. يمكنك سحب الموافقة '
      'في أي وقت من الإعدادات → الخصوصية والقانون. راجع سياسة الخصوصية لمعرفة '
      'كيف يتعامل هؤلاء المزودون مع بياناتك.';

  /// Arabic: [aiConsentDecline].
  static const String aiConsentDeclineAr = 'ليس الآن';

  /// Arabic: [aiConsentAgree].
  static const String aiConsentAgreeAr = 'أوافق وأتابع';

  /// Arabic: [settingsAiConsentTitle].
  static const String settingsAiConsentTitleAr = 'مشاركة البيانات مع ذكاء اصطناعي خارجي';

  /// Arabic: [settingsAiConsentEnabledSubtitle].
  static const String settingsAiConsentEnabledSubtitleAr =
      'مسموح — اضغط لسحب الموافقة';

  /// Arabic: [settingsAiConsentDisabledSubtitle].
  static const String settingsAiConsentDisabledSubtitleAr =
      'غير مسموح — سيُطلب منك التأكيد قبل تشغيل ميزات الذكاء الاصطناعي';

  /// Arabic: [settingsAiConsentRevoked].
  static const String settingsAiConsentRevokedAr = 'تم سحب موافقة مشاركة الذكاء الاصطناعي';


  // ---------------------------------------------------------------------------
  // Arabic counterparts for strings that previously had English only
  // ---------------------------------------------------------------------------

  /// Picks [ar] when [locale] language is Arabic, otherwise [en].
  static String localized(Locale locale, String en, String ar) {
    return locale.languageCode == 'ar' ? ar : en;
  }

  /// Picks EN or AR half from `"English / عربي"` or `"Featured · مميز"`.
  static String pickEmbedded(Locale locale, String combined) {
    for (final sep in [' / ', ' · ']) {
      final i = combined.indexOf(sep);
      if (i >= 0) {
        return localized(
          locale,
          combined.substring(0, i).trim(),
          combined.substring(i + sep.length).trim(),
        );
      }
    }
    return combined;
  }

  /// Featured strip subtitle (Arabic) by profile gender.
  static String homeFeaturedSubtitleForGenderAr(String? gender) {
    switch (gender) {
      case 'men':
        return 'مختارات رجالية لك';
      case 'women':
        return 'مختارات نسائية لك';
      default:
        return 'مختارات مُختارة لك';
    }
  }

  /// Featured strip subtitle for [locale] and profile gender.
  static String homeFeaturedSubtitle(Locale locale, String? gender) {
    return localized(
      locale,
      homeFeaturedSubtitleForGender(gender),
      homeFeaturedSubtitleForGenderAr(gender),
    );
  }

  /// Arabic: [brandLatin].
  static const String brandLatinAr = 'LOLIPANTS';

  /// Arabic: [heroTryNow].
  static const String heroTryNowAr = 'جرّب الآن ←';

  /// Arabic: [categoryAll].
  static const String categoryAllAr = 'الكل';

  /// Arabic: [styleQatariThobe].
  static const String styleQatariThobeAr = 'ثوب قطري';

  /// Arabic: [styleSaudiBisht].
  static const String styleSaudiBishtAr = 'بشت سعودي';

  /// Arabic: [styleUaeKandura].
  static const String styleUaeKanduraAr = 'كندورة إماراتية';

  /// Arabic: [styleOmaniDishdasha].
  static const String styleOmaniDishdashaAr = 'دشداشة عمانية';

  /// Arabic: [originGulf].
  static const String originGulfAr = 'الخليج';

  /// Arabic: [musicPlayerLabel].
  static const String musicPlayerLabelAr = 'مشغّل الموسيقى';

  /// Arabic: [musicNoTracksYet].
  static const String musicNoTracksYetAr = 'لا توجد موسيقى بعد';

  /// Arabic: [musicEmptyQueueBody].
  static const String musicEmptyQueueBodyAr =
      'اختر ملفات MP3 أو صوتاً أخرى مخزّنة على هذا الجهاز. '
      'سيُتذكّر اختيارك في المرة القادمة.';

  /// Arabic: [musicChooseFiles].
  static const String musicChooseFilesAr = 'اختر ملفات';

  /// Arabic: [musicNoTrackLoaded].
  static const String musicNoTrackLoadedAr = 'لم يُحمَّل أي مقطع.';

  /// Arabic: [musicAddMusic].
  static const String musicAddMusicAr = 'أضف موسيقى';

  /// Arabic: [accessoriesLoadError].
  static const String accessoriesLoadErrorAr = 'تعذّر تحميل الإكسسوارات.';

  /// Arabic: [accessoriesEmptyCategory].
  static const String accessoriesEmptyCategoryAr =
      'لا توجد إكسسوارات في هذه الفئة بعد.';

  /// Arabic: [accessoryFilterAll].
  static const String accessoryFilterAllAr = 'الكل';

  /// Arabic: [accessoryFilterScarves].
  static const String accessoryFilterScarvesAr = 'أوشحة';

  /// Arabic: [accessoryFilterBags].
  static const String accessoryFilterBagsAr = 'حقائب';

  /// Arabic: [accessoryFilterJewellery].
  static const String accessoryFilterJewelleryAr = 'مجوهرات';

  /// Arabic: [accessoryFilterOther].
  static const String accessoryFilterOtherAr = 'أخرى';

  /// Arabic: [accessoryNotFound].
  static const String accessoryNotFoundAr = 'لم يُعثر على الإكسسوار';

  /// Arabic: [errorApiBaseUrlMissing].
  static const String errorApiBaseUrlMissingAr =
      'لا يمكن للتطبيق الوصول إلى واجهة البرمجة: أضف API_BASE_URL إلى ملف .env '
      'في جذر المشروع (راجع .env.example)، ثم أعد تشغيل التطبيق.';

  /// Arabic: [errorApiBaseUrlSameAsAuth].
  static const String errorApiBaseUrlSameAsAuthAr =
      'يجب أن يشير API_BASE_URL إلى عنوان عامل lolipants-api (الطلبات، المجتمع، '
      'طلبات الشراكة). لا يمكن أن يكون نفس BETTER_AUTH_BASE_URL. راجع .env.example.';

  /// Arabic: [partnerCouldNotLoadRequests].
  static const String partnerCouldNotLoadRequestsAr = 'تعذّر تحميل الطلبات.';

  /// Arabic: [partnerNetworkError].
  static const String partnerNetworkErrorAr =
      'مشكلة في الشبكة. تحقق من اتصالك وحاول مجدداً.';

  /// Arabic: [partnerSessionExpiredError].
  static const String partnerSessionExpiredErrorAr =
      'انتهت الجلسة. سجّل الدخول مجدداً للمتابعة.';

  /// Arabic: [partnerRequestFailed].
  static const String partnerRequestFailedAr = 'فشل إرسال الطلب.';

  /// Arabic: [partnerNetworkErrorShort].
  static const String partnerNetworkErrorShortAr = 'مشكلة في الشبكة.';

  /// Arabic: [partnerSessionIssueShort].
  static const String partnerSessionIssueShortAr = 'مشكلة في الجلسة.';

  /// Arabic: [partnerReviewRolePrefix].
  static const String partnerReviewRolePrefixAr = 'الدور';

  /// Arabic: [partnerStatusPending].
  static const String partnerStatusPendingAr = 'قيد المراجعة';

  /// Arabic: [partnerStatusApproved].
  static const String partnerStatusApprovedAr = 'مقبول';

  /// Arabic: [partnerStatusRejected].
  static const String partnerStatusRejectedAr = 'مرفوض';

  /// Arabic: [chooseMannequinEn].
  static const String chooseMannequinAr = 'اختر المانيكان';

  /// Arabic: [mannequinChooseFromGallery].
  static const String mannequinChooseFromGalleryAr = 'اختر من المعرض';

  /// Arabic: [mannequinTakePhoto].
  static const String mannequinTakePhotoAr = 'التقط صورة';

  /// Arabic: [mannequinUploadPhotoCta].
  static const String mannequinUploadPhotoCtaAr =
      'ارفع صورتك (مرجع جسم للذكاء الاصطناعي)';

  /// Arabic: [mannequinCustomPhotoHint].
  static const String mannequinCustomPhotoHintAr =
      'تم اختيار صورة مخصصة — تُستخدم لمخرجات الذكاء الاصطناعي.';

  /// Arabic: [homeExploreAll].
  static const String homeExploreAllAr = 'استكشف الكل';

  /// Arabic: [signupGenderRequired].
  static const String signupGenderRequiredAr = 'يرجى اختيار الجنس';

  /// Arabic: [designGenderDialogTitle].
  static const String designGenderDialogTitleAr = 'لمن تصمّم اليوم؟';

  /// Arabic: [comingPhase3].
  static const String comingPhase3Ar = 'قريباً — المرحلة ٣';

  /// Arabic: [comingPhase4].
  static const String comingPhase4Ar = 'قريباً — المرحلة ٤';

  /// Arabic: [createAccountCta].
  static const String createAccountCtaAr = 'إنشاء حساب';

  /// Arabic: [logInCta].
  static const String logInCtaAr = 'تسجيل الدخول';

  /// Arabic: [resetEmailSentPrefix].
  static const String resetEmailSentPrefixAr = 'أرسلنا رابط إعادة التعيين إلى';

  /// Arabic: [filter].
  static const String filterAr = 'تصفية';

  /// Arabic: [featuredEyebrow].
  static const String featuredEyebrowAr = 'مختارات';

  /// Arabic: [featuredCollection].
  static const String featuredCollectionAr = 'المجموعة المميزة';

  /// Arabic: [errorInvalidEmail].
  static const String errorInvalidEmailAr = 'أدخل بريداً إلكترونياً صالحاً';

  /// Arabic: [errorPasswordDigit].
  static const String errorPasswordDigitAr = 'يجب أن تتضمن كلمة المرور رقماً';

  /// Arabic: [errorPasswordMismatch].
  static const String errorPasswordMismatchAr = 'كلمتا المرور غير متطابقتين';

  /// Arabic: [errorNameShort].
  static const String errorNameShortAr = 'يجب أن يكون الاسم حرفين على الأقل';

  /// Arabic: [errorForbidden].
  static const String errorForbiddenAr = 'ليس لديك صلاحية لتنفيذ هذا الإجراء';

  /// Arabic: [partnerTitleEn].
  static const String partnerTitleEnAr = 'كن شريكاً مع Lolipants';

  /// Arabic: [partnerRetry].
  static const String partnerRetryAr = 'إعادة المحاولة';

  /// Arabic: [partnerRoleTailorTitle].
  static const String partnerRoleTailorTitleAr = 'شريك خياطة';

  /// Arabic: [partnerRoleDeliveryTitle].
  static const String partnerRoleDeliveryTitleAr = 'شريك توصيل';

  /// Arabic: [partnerFieldCityRegion].
  static const String partnerFieldCityRegionAr = 'المدينة أو المنطقة التي تخدمها';

  /// Arabic: [partnerFieldYearsExperience].
  static const String partnerFieldYearsExperienceAr = 'سنوات الخبرة';

  /// Arabic: [partnerFieldWorkshopName].
  static const String partnerFieldWorkshopNameAr = 'اسم الورشة أو الاستوديو (اختياري)';

  /// Arabic: [partnerFieldPortfolioUrl].
  static const String partnerFieldPortfolioUrlAr = 'معرض أعمال أو موقع (اختياري)';

  /// Arabic: [partnerFieldVehicle].
  static const String partnerFieldVehicleAr = 'نوع المركبة';

  /// Arabic: [partnerFieldCoverage].
  static const String partnerFieldCoverageAr = 'مناطق / نطاقات التغطية';

  /// Arabic: [partnerReviewNoteLabel].
  static const String partnerReviewNoteLabelAr = 'ملاحظات إضافية؟ (اختياري)';

  /// Arabic: [partnerWizardBack].
  static const String partnerWizardBackAr = 'رجوع';

  /// Arabic: [partnerWizardNext].
  static const String partnerWizardNextAr = 'التالي';

  /// Arabic: [partnerWizardSubmit].
  static const String partnerWizardSubmitAr = 'إرسال الطلب';

  /// Arabic: [partnerDoneTitle].
  static const String partnerDoneTitleAr = 'تم إرسال الطلب';

  /// Arabic: [partnerDoneBackToProfile].
  static const String partnerDoneBackToProfileAr = 'العودة إلى الملف الشخصي';

  /// Arabic: [partnerPreviousRequests].
  static const String partnerPreviousRequestsAr = 'الطلبات السابقة';

  /// Arabic: [partnerNoRequestsYet].
  static const String partnerNoRequestsYetAr = 'لا توجد طلبات بعد.';

  /// Arabic: [aiDesigner].
  static const String aiDesignerAr = 'مصمّم بالذكاء الاصطناعي';

  /// Arabic: [describeOutfit].
  static const String describeOutfitAr = 'صف زيّك المثالي';

  /// Arabic: [tryNow].
  static const String tryNowAr = 'جرّب الآن ←';

  /// Arabic: [trackOrder].
  static const String trackOrderAr = 'تتبع الطلب';

  /// Arabic: [inProgress].
  static const String inProgressAr = 'قيد التنفيذ';

  /// Arabic: [orderPrefix].
  static const String orderPrefixAr = 'طلب';

  /// Arabic: [designLabel].
  static const String designLabelAr = 'التصميم';

  /// Arabic: [tailorLabel].
  static const String tailorLabelAr = 'الخياط';

  /// Arabic: [countryQatar].
  static const String countryQatarAr = 'قطر';

  /// Arabic: [countrySaudi].
  static const String countrySaudiAr = 'السعودية';

  /// Arabic: [countryUae].
  static const String countryUaeAr = 'الإمارات';

  /// Arabic: [countryOman].
  static const String countryOmanAr = 'عُمان';

  /// Arabic: [countryCodeQa].
  static const String countryCodeQaAr = 'QA';

  /// Arabic: [countryCodeSa].
  static const String countryCodeSaAr = 'SA';

  /// Arabic: [countryCodeAe].
  static const String countryCodeAeAr = 'AE';

  /// Arabic: [countryCodeOm].
  static const String countryCodeOmAr = 'OM';

  /// Arabic: [tailorStripMeta].
  static const String tailorStripMetaAr = 'خياطون معتمدون في منطقتك';

  /// Arabic: [countryGarmentsQa].
  static const String countryGarmentsQaAr = 'أزياء قطرية';

  /// Arabic: [countryGarmentsSa].
  static const String countryGarmentsSaAr = 'أزياء سعودية';

  /// Arabic: [countryGarmentsAe].
  static const String countryGarmentsAeAr = 'أزياء إماراتية';

  /// Arabic: [countryGarmentsOm].
  static const String countryGarmentsOmAr = 'أزياء عُمانية';

  /// Arabic: [startDesigningCta].
  static const String startDesigningCtaAr = 'ابدأ التصميم';

  /// Arabic: [editorTitle].
  static const String editorTitleAr = 'المحرّر';

  /// Arabic: [editorSave].
  static const String editorSaveAr = 'حفظ';

  /// Arabic: [editorSaved].
  static const String editorSavedAr = 'تم الحفظ';

  /// Arabic: [editorTabDesigns].
  static const String editorTabDesignsAr = 'التصاميم';

  /// Arabic: [weddingFilterAll].
  static const String weddingFilterAllAr = 'الكل';

  /// Arabic: [weddingFilterBridal].
  static const String weddingFilterBridalAr = 'عروس';

  /// Arabic: [weddingFilterBridesmaids].
  static const String weddingFilterBridesmaidsAr = 'وصيفات';

  /// Arabic: [weddingRent].
  static const String weddingRentAr = 'إيجار';

  /// Arabic: [weddingBuy].
  static const String weddingBuyAr = 'شراء';

  /// Arabic: [weddingRentalDays].
  static const String weddingRentalDaysAr = 'أيام الإيجار';

  /// Arabic: [weddingCatalogEmpty].
  static const String weddingCatalogEmptyAr = 'لا توجد فساتين في هذا التصنيف بعد.';

  /// Arabic: [weddingCatalogError].
  static const String weddingCatalogErrorAr = 'تعذّر تحميل كتالوج الأعراس.';

  /// Arabic: [weddingRentDress].
  static const String weddingRentDressAr = 'استئجار الفستان';

  /// Arabic: [weddingBuyDress].
  static const String weddingBuyDressAr = 'شراء الفستان';

  /// Arabic: [weddingOrderSummaryTitle].
  static const String weddingOrderSummaryTitleAr = 'ملخص الطلب';

  /// Arabic: [editorBuildSummaryTitle].
  static const String editorBuildSummaryTitleAr = 'ملخص التصميم';

  /// Arabic: [editorBuildPickTemplate].
  static const String editorBuildPickTemplateAr = 'اختر قالباً';

  /// Arabic: [editorBuildTemplate].
  static const String editorBuildTemplateAr = 'القالب';

  /// Arabic: [editorBuildSelectSlot].
  static const String editorBuildSelectSlotAr = 'اختر القطعة';

  /// Arabic: [editorBuildChangeStyle].
  static const String editorBuildChangeStyleAr = 'تغيير النمط';

  /// Arabic: [editorBuildReset].
  static const String editorBuildResetAr = 'إعادة ضبط';

  /// Arabic: [editorStyleCatalogMode].
  static const String editorStyleCatalogModeAr = 'من الكتالوج';

  /// Arabic: [editorTabFabric].
  static const String editorTabFabricAr = 'القماش';

  /// Arabic: [editorAddText].
  static const String editorAddTextAr = 'إضافة نص';

  /// Arabic: [editorAddImage].
  static const String editorAddImageAr = 'إضافة صورة';

  /// Arabic: [editorTabPattern].
  static const String editorTabPatternAr = 'النقش';

  /// Arabic: [editorTabEmbroidery].
  static const String editorTabEmbroideryAr = 'التطريز';

  /// Arabic: [editorTabText].
  static const String editorTabTextAr = 'النص';

  /// Arabic: [editorTabAi].
  static const String editorTabAiAr = 'ذكاء اصطناعي';

  /// Arabic: [editorHeroCompose].
  static const String editorHeroComposeAr = 'كوّن إطلالتك';

  /// Arabic: [editorHeroAiLook].
  static const String editorHeroAiLookAr = 'إطلالة بالذكاء الاصطناعي';

  /// Arabic: [editorGenerateLook].
  static const String editorGenerateLookAr = 'إنشاء إطلالة';

  /// Arabic: [editorLookGenerating].
  static const String editorLookGeneratingAr = 'جارٍ إنشاء الإطلالة…';

  /// Arabic: [editorSketchClear].
  static const String editorSketchClearAr = 'مسح الرسم';

  /// Arabic: [sizingOptions].
  static const String sizingOptionsAr = 'خيارات المقاسات';

  /// Arabic: [sizingAiOption].
  static const String sizingAiOptionAr = 'قياس بالذكاء الاصطناعي';

  /// Arabic: [sizingManualOption].
  static const String sizingManualOptionAr = 'إدخال يدوي';

  /// Arabic: [sizingWorkshopOption].
  static const String sizingWorkshopOptionAr = 'زيارة ورشة';

  /// Arabic: [sizingAiSubtitle].
  static const String sizingAiSubtitleAr = 'التقط صوراً ونحسب مقاساتك';

  /// Arabic: [sizingManualSubtitle].
  static const String sizingManualSubtitleAr = 'أدخل المقاسات بنفسك';

  /// Arabic: [sizingWorkshopSubtitle].
  static const String sizingWorkshopSubtitleAr = 'احجز موعداً في ورشة شريكة';

  /// Arabic: [aiMeasurementTitle].
  static const String aiMeasurementTitleAr = 'قياس بالذكاء الاصطناعي';

  /// Arabic: [aiMeasurementInstructions].
  static const String aiMeasurementInstructionsAr = 'اتبع الخطوات للحصول على مقاسات دقيقة';

  /// Arabic: [aiMeasurementStep1].
  static const String aiMeasurementStep1Ar = 'قف بشكل مستقيم أمام الكاميرا';

  /// Arabic: [aiMeasurementStep2].
  static const String aiMeasurementStep2Ar = 'التقط صوراً من الأمام والجانب';

  /// Arabic: [aiMeasurementStartScan].
  static const String aiMeasurementStartScanAr = 'بدء المسح';

  /// Arabic: [aiMeasurementCameraScan].
  static const String aiMeasurementCameraScanAr = 'مسح بالكاميرا';

  /// Arabic: [aiMeasurementAnalyse].
  static const String aiMeasurementAnalyseAr = 'تحليل الصور';

  /// Arabic: [aiMeasurementSave].
  static const String aiMeasurementSaveAr = 'حفظ المقاسات';

  /// Arabic: [aiMeasurementSaveFailed].
  static const String aiMeasurementSaveFailedAr = 'تعذّر حفظ المقاسات';

  /// Arabic: [aiMeasurementAnalysing].
  static const String aiMeasurementAnalysingAr = 'جارٍ التحليل…';

  /// Arabic: [manualSave].
  static const String manualSaveAr = 'حفظ';

  /// Arabic: [manualSaved].
  static const String manualSavedAr = 'تم حفظ المقاسات';

  /// Arabic: [workshopTitle].
  static const String workshopTitleAr = 'زيارة الورشة';

  /// Arabic: [workshopVisitOption].
  static const String workshopVisitOptionAr = 'زيارة الورشة';

  /// Arabic: [workshopHomeOption].
  static const String workshopHomeOptionAr = 'قياس منزلي';

  /// Arabic: [workshopAddressLabel].
  static const String workshopAddressLabelAr = 'العنوان';

  /// Arabic: [workshopCityLabel].
  static const String workshopCityLabelAr = 'المدينة';

  /// Arabic: [workshopPickDate].
  static const String workshopPickDateAr = 'اختر التاريخ';

  /// Arabic: [workshopConfirm].
  static const String workshopConfirmAr = 'تأكيد الموعد';

  /// Arabic: [workshopConfirmedPrefix].
  static const String workshopConfirmedPrefixAr = 'تم تأكيد موعدك في';

  /// Arabic: [workshopConfirmedArPrefix].
  static const String workshopConfirmedArPrefixAr = 'تم تأكيد موعدك في';

  /// Arabic: [myMeasurementsSummaryTitle].
  static const String myMeasurementsSummaryTitleAr = 'ملخص مقاساتي';

  /// Arabic: [measurementUnknown].
  static const String measurementUnknownAr = 'غير محدد';

  /// Arabic: [measurementChest].
  static const String measurementChestAr = 'الصدر';

  /// Arabic: [measurementWaist].
  static const String measurementWaistAr = 'الخصر';

  /// Arabic: [measurementHips].
  static const String measurementHipsAr = 'الورك';

  /// Arabic: [measurementShoulderWidth].
  static const String measurementShoulderWidthAr = 'عرض الكتف';

  /// Arabic: [measurementHeight].
  static const String measurementHeightAr = 'الطول';

  /// Arabic: [measurementArmLength].
  static const String measurementArmLengthAr = 'طول الذراع';

  /// Arabic: [measurementPreferredSize].
  static const String measurementPreferredSizeAr = 'المقاس المفضل';

  /// Arabic: [measurementUnitCm].
  static const String measurementUnitCmAr = 'سم';

  /// Arabic: [myMeasurementsLastUpdatedPrefix].
  static const String myMeasurementsLastUpdatedPrefixAr = 'آخر تحديث:';

  /// Arabic: [myMeasurementsEdit].
  static const String myMeasurementsEditAr = 'تعديل';

  /// Arabic: [myMeasurementsTakeNow].
  static const String myMeasurementsTakeNowAr = 'خذ مقاساتك الآن';

  /// Arabic: [sizingOptionsTooltip].
  static const String sizingOptionsTooltipAr = 'اختر طريقة أخذ المقاسات';

  /// Arabic: [aiPromptLabel].
  static const String aiPromptLabelAr = 'صف الإطلالة التي تريدها';

  /// Arabic: [aiGenerating].
  static const String aiGeneratingAr = 'جاري توليد التصميم...';

  /// Arabic: [aiAppliedToDesign].
  static const String aiAppliedToDesignAr = 'تم التطبيق على التصميم';

  /// Arabic: [aiDraftCreated].
  static const String aiDraftCreatedAr =
      'تم إنشاء مسودة بالذكاء الاصطناعي في تصاميمي';

  /// Arabic: [aiApply].
  static const String aiApplyAr = 'تطبيق';

  /// Arabic: [aiTryAgain].
  static const String aiTryAgainAr = 'حاول مرة أخرى';

  /// Arabic: [permissionNotNow].
  static const String permissionNotNowAr = 'ليس الآن';

  /// Arabic: [permissionContinue].
  static const String permissionContinueAr = 'متابعة';

  /// Arabic: [permissionOpenSettings].
  static const String permissionOpenSettingsAr = 'فتح الإعدادات';

  /// Arabic: [permissionCameraTitle].
  static const String permissionCameraTitleAr = 'الكاميرا مطلوبة لالتقاط الصور والقياس';

  /// Arabic: [permissionCameraDeniedTitle].
  static const String permissionCameraDeniedTitleAr = 'تم رفض إذن الكاميرا';

  /// Arabic: [permissionPhotosTitle].
  static const String permissionPhotosTitleAr = 'الصور مطلوبة لاختيار صور من المعرض';

  /// Arabic: [permissionPhotosDeniedTitle].
  static const String permissionPhotosDeniedTitleAr = 'تم رفض إذن الصور';

  /// Arabic: [permissionLocationTitle].
  static const String permissionLocationTitleAr = 'الموقع يساعدنا في إيجاد خياطين قريبين';

  /// Arabic: [permissionLocationDeniedTitle].
  static const String permissionLocationDeniedTitleAr = 'تم رفض إذن الموقع';

  /// Arabic: [permissionNotificationsTitle].
  static const String permissionNotificationsTitleAr = 'الإشعارات تُبقيك على اطلاع بطلبك';

  /// Arabic: [permissionAudioTitle].
  static const String permissionAudioTitleAr = 'الميكروفون مطلوب للأوامر الصوتية';

  /// Arabic: [permissionAudioDeniedTitle].
  static const String permissionAudioDeniedTitleAr = 'تم رفض إذن الميكروفون';

  /// Arabic: [editorExitConfirm].
  static const String editorExitConfirmAr = 'الخروج بدون حفظ؟';

  /// Arabic: [editorBuildColorPrimary].
  static const String editorBuildColorPrimaryAr = 'لون القماش';

  /// Arabic: [editorSketchOptional].
  static const String editorSketchOptionalAr = 'رسم اختياري للذكاء الاصطناعي';

  /// Arabic: [editorExit].
  static const String editorExitAr = 'خروج';

  /// Arabic: [editorOrder].
  static const String editorOrderAr = 'اطلب';

  /// Arabic: [editorMoreMenu].
  static const String editorMoreMenuAr = 'المزيد';

  /// Arabic: [editorSaveDesignTitle].
  static const String editorSaveDesignTitleAr = 'حفظ التصميم';

  /// Arabic: [editorDesignNameHint].
  static const String editorDesignNameHintAr = 'الاسم المعروض في تصاميمي';

  /// Arabic: [editorDesignNameRequired].
  static const String editorDesignNameRequiredAr = 'اسم التصميم مطلوب.';

  /// Arabic: [editorCurrentDesign].
  static const String editorCurrentDesignAr = 'التصميم الحالي';

  /// Arabic: [editorLookGeneratedSnack].
  static const String editorLookGeneratedSnackAr =
      'تم إنشاء الإطلالة — انتقل إلى معاينة الذكاء الاصطناعي';

  /// Arabic: [editorLookGeneratedPreview].
  static const String editorLookGeneratedPreviewAr =
      'تم إنشاء الإطلالة. راجع المعاينة أعلاه.';

  /// Arabic: [editorShareImage].
  static const String editorShareImageAr = 'مشاركة الصورة';

  /// Arabic: [editorSaveImage].
  static const String editorSaveImageAr = 'حفظ الصورة';

  /// Arabic: [editorShareToCommunity].
  static const String editorShareToCommunityAr = 'مشاركة في المجتمع';

  /// Arabic: [editorPublishEarn].
  static const String editorPublishEarnAr = 'انشر واربح';

  /// Arabic: [editorPublishShowcaseSubtitle].
  static const String editorPublishShowcaseSubtitleAr =
      'أدرج في المعرض القابل للطلب';

  /// Arabic: [editorCapturePreviewFailed].
  static const String editorCapturePreviewFailedAr =
      'تعذّر التقاط معاينة التصميم.';

  /// Arabic: [editorShareImageCaption].
  static const String editorShareImageCaptionAr = 'تصميمي في لوليبانتس';

  /// Arabic: [editorSavedImageToPath].
  static const String editorSavedImageToPathAr = 'تم الحفظ في {path}';

  /// Arabic: [editorSaveBeforePublish].
  static const String editorSaveBeforePublishAr =
      'احفظ التصميم قبل النشر.';

  /// Arabic: [editorDone].
  static const String editorDoneAr = 'تم';

  /// Arabic: [editorTextTypeHint].
  static const String editorTextTypeHintAr = 'اكتب نصك';

  /// Arabic: [editorTextAddToDesign].
  static const String editorTextAddToDesignAr = 'أضف إلى التصميم';

  /// Arabic: [editorTextLayers].
  static const String editorTextLayersAr = 'الطبقات';

  /// Arabic: [editorTextFont].
  static const String editorTextFontAr = 'الخط';

  /// Arabic: [editorTextSizePrefix].
  static const String editorTextSizePrefixAr = 'الحجم';

  /// Arabic: [editorTextRotationPrefix].
  static const String editorTextRotationPrefixAr = 'الدوران';

  /// Arabic: [editorTextColour].
  static const String editorTextColourAr = 'اللون';

  /// Arabic: [editorTextDragHint].
  static const String editorTextDragHintAr =
      'اسحب النص على الملبس لتغيير موضعه';

  /// Arabic: [editorTextRemove].
  static const String editorTextRemoveAr = 'حذف النص';

  /// Arabic: [editorPrintOnGarment].
  static const String editorPrintOnGarmentAr = 'طباعة على الملبس';

  /// Arabic: [editorUploadImage].
  static const String editorUploadImageAr = 'ارفع صورة';

  /// Arabic: [editorUploadSketch].
  static const String editorUploadSketchAr = 'ارفع السكتش';

  /// Arabic: [editorPrintPlacementChest].
  static const String editorPrintPlacementChestAr = 'الصدر';

  /// Arabic: [editorPrintPlacementBack].
  static const String editorPrintPlacementBackAr = 'الظهر';

  /// Arabic: [editorPrintPlacementFullFront].
  static const String editorPrintPlacementFullFrontAr = 'الواجهة كاملة';

  /// Arabic: [editorPrintOffsetHorizontal].
  static const String editorPrintOffsetHorizontalAr = 'إزاحة أفقية';

  /// Arabic: [editorPrintOffsetVertical].
  static const String editorPrintOffsetVerticalAr = 'إزاحة عمودية';

  /// Arabic: [editorPrintSizePercent].
  static const String editorPrintSizePercentAr = 'الحجم';

  /// Arabic: [editorApplyToDesign].
  static const String editorApplyToDesignAr = 'تطبيق على التصميم';

  /// Arabic: [editorAccessoriesUnavailable].
  static const String editorAccessoriesUnavailableAr =
      'الإكسسوارات غير متاحة في هذا الإصدار.';

  /// Arabic: [editorAddAccessories].
  static const String editorAddAccessoriesAr = 'إضافة إكسسوارات';

  /// Arabic: [editorAccessoriesSubtitle].
  static const String editorAccessoriesSubtitleAr =
      'عناصر اختيارية تُضمّن مع طلب الملبس.';

  /// Arabic: [editorAccessoriesLoadError].
  static const String editorAccessoriesLoadErrorAr =
      'تعذّر تحميل الإكسسوارات.';

  /// Arabic: [editorAccessoriesEmpty].
  static const String editorAccessoriesEmptyAr =
      'لا توجد إكسسوارات إضافية متاحة.';

  /// Arabic: [editorStyleYourPiece].
  static const String editorStyleYourPieceAr = 'صمّم قطعتك';

  /// Arabic: [editorStyleColourHint].
  static const String editorStyleColourHintAr =
      'اختر لوناً — التغييرات تُطبَّق على تصميمك فوراً.';

  /// Arabic: [editorMoreColours].
  static const String editorMoreColoursAr = 'المزيد من الألوان…';

  /// Arabic: [editorQualityTier].
  static const String editorQualityTierAr = 'درجة الجودة';

  /// Arabic: [editorQualityStandard].
  static const String editorQualityStandardAr = 'قياسي';

  /// Arabic: [editorQualityPremium].
  static const String editorQualityPremiumAr = 'مميز';

  /// Arabic: [editorQualitySuitGrade].
  static const String editorQualitySuitGradeAr = 'درجة البدلة';

  /// Arabic: [editorCustomColour].
  static const String editorCustomColourAr = 'لون مخصص';

  /// Arabic: [editorTapToFineTune].
  static const String editorTapToFineTuneAr = 'اضغط للضبط الدقيق';

  /// Arabic: [editorBuildCatalogError].
  static const String editorBuildCatalogErrorAr =
      'تعذّر تحميل كتالوج البناء.';

  /// Arabic: [editorDesignCatalogError].
  static const String editorDesignCatalogErrorAr =
      'تعذّر تحميل كتالوج التصاميم.';

  /// Arabic: [editorNoOptionsForCombination].
  static const String editorNoOptionsForCombinationAr =
      'لا توجد خيارات متاحة لهذا التركيب.';

  /// Arabic: [editorBackToParts].
  static const String editorBackToPartsAr = 'العودة إلى الأجزاء';

  /// Arabic: [editorEnhanceWithAi].
  static const String editorEnhanceWithAiAr = 'تحسين بالذكاء الاصطناعي';

  /// Arabic: [editorAiRequestFailed].
  static const String editorAiRequestFailedAr = 'فشل طلب الذكاء الاصطناعي';

  /// Arabic: [editorAiApplyFailed].
  static const String editorAiApplyFailedAr =
      'تعذّر تطبيق اقتراح الذكاء الاصطناعي.';

  /// Arabic: [editorShareCommunityPrefillNew].
  static const String editorShareCommunityPrefillNewAr =
      'شاهدوا تصميمي الجديد لـ {garmentType}.';

  /// Arabic: [editorShareCommunityPrefillNamed].
  static const String editorShareCommunityPrefillNamedAr =
      'صمّمتُ للتو {name}.';

  /// Arabic: [aiCreateFailed].
  static const String aiCreateFailedAr =
      'تعذّر إنشاء التصميم. حاول مرة أخرى.';

}
