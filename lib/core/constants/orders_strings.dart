import 'dart:ui' show Locale;

import 'package:lolipants/core/l10n/app_localization.dart';

/// Localized copy for checkout, payment, and order detail flows.
class OrdersStrings {
  OrdersStrings._();

  static String l(Locale locale, String en, String ar) =>
      localizedFromLocale(locale, en, ar);

  static const String back = 'Back';
  static const String backAr = 'رجوع';

  static const String retry = 'Retry';
  static const String retryAr = 'إعادة المحاولة';

  static const String cancel = 'Cancel';
  static const String cancelAr = 'إلغاء';

  static const String yes = 'Yes';
  static const String yesAr = 'نعم';

  static const String no = 'No';
  static const String noAr = 'لا';

  static const String total = 'Total';
  static const String totalAr = 'الإجمالي';

  static const String address = 'Address';
  static const String addressAr = 'العنوان';

  static const String city = 'City';
  static const String cityAr = 'المدينة';

  static const String payment = 'Payment';
  static const String paymentAr = 'الدفع';

  static const String fabric = 'Fabric';
  static const String fabricAr = 'القماش';

  static const String garment = 'Garment';
  static const String garmentAr = 'الملبس';

  static const String pattern = 'Pattern';
  static const String patternAr = 'النقش';

  static const String primaryColour = 'Primary colour';
  static const String primaryColourAr = 'اللون الأساسي';

  static const String accessories = 'Accessories';
  static const String accessoriesAr = 'الإكسسوارات';

  static const String delivery = 'Delivery';
  static const String deliveryAr = 'التوصيل';

  static const String item = 'Item';
  static const String itemAr = 'القطعة';

  static const String messages = 'Messages';
  static const String messagesAr = 'الرسائل';

  // Order summary
  static const String orderSummaryTitle = 'Order summary';
  static const String orderSummaryTitleAr = 'ملخص الطلب';

  static const String backToEditor = 'Back to editor';
  static const String backToEditorAr = 'العودة للمحرر';

  static const String sizingStatus = 'Sizing status';
  static const String sizingStatusAr = 'حالة المقاسات';

  static const String updateSizing = 'Update sizing';
  static const String updateSizingAr = 'تحديث المقاسات';

  // Size confirmation
  static const String confirmSizeTitle = 'Confirm size';
  static const String confirmSizeTitleAr = 'تأكيد المقاس';

  static const String looksGoodContinue = 'Looks good · continue';
  static const String looksGoodContinueAr = 'يبدو جيداً · متابعة';

  static const String changeMeasurements = 'Change measurements';
  static const String changeMeasurementsAr = 'تغيير المقاسات';

  static const String goToSizing = 'Go to sizing';
  static const String goToSizingAr = 'الذهاب للمقاسات';

  // Order confirmation
  static const String orderConfirmed = 'Order confirmed';
  static const String orderConfirmedAr = 'تم تأكيد الطلب';

  static const String trackOrder = 'Track order';
  static const String trackOrderAr = 'تتبع الطلب';

  static const String continueDesigning = 'Continue designing';
  static const String continueDesigningAr = 'متابعة التصميم';

  // Order detail
  static const String cancelOrderTitle = 'Cancel this order?';
  static const String cancelOrderTitleAr = 'إلغاء هذا الطلب؟';

  static const String cancelOrderBody =
      'This will mark the order as cancelled.';
  static const String cancelOrderBodyAr = 'سيتم وضع الطلب كملغى.';

  static const String orderCancelled = 'Order cancelled';
  static const String orderCancelledAr = 'تم إلغاء الطلب';

  static const String statusUpdates = 'Status updates';
  static const String statusUpdatesAr = 'تحديثات الحالة';

  static const String deliveryPartner = 'Delivery partner';
  static const String deliveryPartnerAr = 'شريك التوصيل';

  static const String cancelOrder = 'Cancel order';
  static const String cancelOrderAr = 'إلغاء الطلب';

  static String couldNotLoadOrder(Locale locale) => l(
        locale,
        'Could not load this order.',
        'تعذّر تحميل هذا الطلب.',
      );

  // Quote review
  static const String compareTailorsTitle = 'Compare tailors & prices';
  static const String compareTailorsTitleAr = 'قارن الخياطين والأسعار';

  static const String chooseYourTailor = 'Choose your tailor';
  static const String chooseYourTailorAr = 'اختر خياطك';

  static const String changeDelivery = 'Change delivery';
  static const String changeDeliveryAr = 'تغيير التوصيل';

  static const String noQuotesAvailable = 'No quotes available';
  static const String noQuotesAvailableAr = 'لا توجد عروض متاحة';

  static const String negotiatePrice = 'Negotiate price';
  static const String negotiatePriceAr = 'تفاوض السعر';

  static const String yourOfferQar = 'Your offer (QAR)';
  static const String yourOfferQarAr = 'عرضك (ر.ق)';

  static const String noteToTailor = 'Note to tailor (optional)';
  static const String noteToTailorAr = 'ملاحظة للخياط (اختياري)';

  static const String sendToTailor = 'Send to tailor';
  static const String sendToTailorAr = 'إرسال للخياط';

  static String offerMinQar(String floor, Locale locale) => l(
        locale,
        'Offer must be at least $floor QAR',
        'يجب أن يكون العرض $floor ر.ق على الأقل',
      );

  static const String offerSent = 'Offer sent to tailor';
  static const String offerSentAr = 'تم إرسال العرض للخياط';

  static const String payAgreedPrice = 'Pay agreed price';
  static const String payAgreedPriceAr = 'ادفع السعر المتفق عليه';

  static const String reviewCounterOffer = 'Review counter offer';
  static const String reviewCounterOfferAr = 'مراجعة العرض المضاد';

  static const String priceNegotiationTitle = 'Price negotiation';
  static const String priceNegotiationTitleAr = 'تفاوض السعر';

  static const String notFound = 'Not found';
  static const String notFoundAr = 'غير موجود';

  static const String message = 'Message';
  static const String messageAr = 'رسالة';

  // Payment
  static const String checkoutExpired =
      'Checkout session expired. Please restart.';
  static const String checkoutExpiredAr =
      'انتهت جلسة الدفع. يرجى البدء من جديد.';

  static const String payWithCard = 'Pay with card';
  static const String payWithCardAr = 'الدفع بالبطاقة';

  static const String baseGarment = 'Base garment';
  static const String baseGarmentAr = 'القطعة الأساسية';

  static String deliveryCityLine(String city, Locale locale) => l(
        locale,
        'Delivery ($city)',
        'التوصيل ($city)',
      );

  static const String completeTapPayment = 'Complete Tap payment';
  static const String completeTapPaymentAr = 'إكمال الدفع عبر تاب';

  static const String confirmToken = 'Confirm token';
  static const String confirmTokenAr = 'تأكيد الرمز';

  // Delivery details
  static const String deliveryDetailsTitle = 'Delivery details';
  static const String deliveryDetailsTitleAr = 'تفاصيل التوصيل';

  static const String checkoutExpiredRestart =
      'Checkout session expired. Restart.';
  static const String checkoutExpiredRestartAr =
      'انتهت جلسة الدفع. أعد البدء.';

  static const String detectingLocation =
      'Still detecting your location. Wait a moment.';
  static const String detectingLocationAr =
      'لا يزال يتم تحديد موقعك. انتظر لحظة.';

  static const String refresh = 'Refresh';
  static const String refreshAr = 'تحديث';

  // Accessory / wedding
  static const String accessoryOrderTitle = 'Accessory order';
  static const String accessoryOrderTitleAr = 'طلب إكسسوار';

  static const String noAccessorySelected = 'No accessory selected.';
  static const String noAccessorySelectedAr = 'لم يتم اختيار إكسسوار.';

  static const String continueToDelivery = 'Continue to delivery';
  static const String continueToDeliveryAr = 'متابعة للتوصيل';

  static const String accessoryQuoteTitle = 'Accessory quote';
  static const String accessoryQuoteTitleAr = 'عرض الإكسسوار';

  static const String noQuoteAvailable = 'No quote available.';
  static const String noQuoteAvailableAr = 'لا يوجد عرض متاح.';

  static const String continueToPayment = 'Continue to payment';
  static const String continueToPaymentAr = 'متابعة للدفع';

  static const String weddingQuoteTitle = 'Wedding quote';
  static const String weddingQuoteTitleAr = 'عرض العرس';

  static const String insuranceDeposit = 'Insurance deposit';
  static const String insuranceDepositAr = 'تأمين العرض';

  static const String noWeddingDressSelected = 'No wedding dress selected.';
  static const String noWeddingDressSelectedAr = 'لم يتم اختيار فستان عرس.';

  static String couldNotCancelOrder(Locale locale) => l(
        locale,
        'Could not cancel order',
        'تعذّر إلغاء الطلب.',
      );

  static String placedOn(String date, Locale locale) => l(
        locale,
        'Placed $date',
        'تاريخ الطلب $date',
      );

  // Payment flow
  static const String processing = 'Processing...';
  static const String processingAr = 'جاري المعالجة...';

  static const String pricingUnavailable = 'Pricing unavailable';
  static const String pricingUnavailableAr = 'التسعير غير متاح';

  static String payAmount(String total, String currency, Locale locale) => l(
        locale,
        'Pay $total $currency',
        'ادفع $total $currency',
      );

  static String totalLine(String total, String currency, Locale locale) => l(
        locale,
        'Total: $total $currency',
        'الإجمالي: $total $currency',
      );

  static const String fetchingPrice = 'Fetching price...';
  static const String fetchingPriceAr = 'جاري جلب السعر...';

  static const String hide = 'Hide';
  static const String hideAr = 'إخفاء';

  static const String details = 'Details';
  static const String detailsAr = 'التفاصيل';

  static String tailorColon(String name, Locale locale) => l(
        locale,
        'Tailor: $name',
        'الخياط: $name',
      );

  static String tailorShopLine(
    String tailor,
    String? shop,
    Locale locale,
  ) =>
      l(
        locale,
        shop != null && shop.isNotEmpty ? '$tailor · $shop' : tailor,
        shop != null && shop.isNotEmpty ? '$tailor · $shop' : tailor,
      );

  static const String demoPaymentModeActive =
      'Demo payment mode is active. No real card will be charged in this build.';
  static const String demoPaymentModeActiveAr =
      'وضع الدفع التجريبي مفعّل. لن تُخصم بطاقة حقيقية في هذا الإصدار.';

  static const String cardPaymentManualMode =
      'Card payments: this build collects a Tap-compatible token manually '
      '(no Tap Flutter SDK). Your card details never touch our servers.';
  static const String cardPaymentManualModeAr =
      'الدفع بالبطاقة: يجمع هذا الإصدار رمز تاب يدوياً (بدون حزمة تاب). '
      'بيانات بطاقتك لا تصل إلى خوادمنا.';

  static const String tapTokenDescription =
      'Paste the Tap token generated by the card widget/session. '
      'The app sends only this token to Lolipants API for capture.';
  static const String tapTokenDescriptionAr =
      'الصق رمز تاب من جلسة البطاقة. يرسل التطبيق هذا الرمز فقط إلى واجهة لوليبانتس.';

  static const String tapToken = 'Tap token';
  static const String tapTokenAr = 'رمز تاب';

  static const String tapTokenHint = 'tok_xxx or src_xxx';
  static const String tapTokenHintAr = 'tok_xxx أو src_xxx';

  static const String pricingExpiredGoBack =
      'Pricing expired. Go back and refresh your quote.';
  static const String pricingExpiredGoBackAr =
      'انتهت صلاحية التسعير. ارجع وحدّث عرضك.';

  static const String couldNotCreateOrder = 'Could not create order.';
  static const String couldNotCreateOrderAr = 'تعذّر إنشاء الطلب.';

  static const String orderCreationNoPayload =
      'Order creation returned no payload.';
  static const String orderCreationNoPayloadAr =
      'لم يُرجع إنشاء الطلب أي بيانات.';

  static const String couldNotStartPayment = 'Could not start payment.';
  static const String couldNotStartPaymentAr = 'تعذّر بدء الدفع.';

  static const String paymentIntentNoPayload =
      'Payment intent returned no payload.';
  static const String paymentIntentNoPayloadAr =
      'لم يُرجع نية الدفع أي بيانات.';

  static const String paymentCancelled = 'Payment was cancelled.';
  static const String paymentCancelledAr = 'تم إلغاء الدفع.';

  static const String paymentNotCaptured = 'Payment could not be captured.';
  static const String paymentNotCapturedAr = 'تعذّر تحصيل الدفع.';

  static const String saveDesignBeforeOrder =
      'Please save the design before ordering.';
  static const String saveDesignBeforeOrderAr =
      'يرجى حفظ التصميم قبل الطلب.';

  static String includesRefundableDeposit(
    String amount,
    String currency,
    Locale locale,
  ) =>
      l(
        locale,
        'Includes $amount $currency refundable deposit',
        'يشمل تأميناً قابلاً للاسترداد بقيمة $amount $currency',
      );

  // Wedding / sizing checkout
  static const String continueToSizing = 'Continue to sizing';
  static const String continueToSizingAr = 'متابعة للمقاسات';

  static const String addMeasurementsFirst = 'Add measurements first';
  static const String addMeasurementsFirstAr = 'أضف المقاسات أولاً';

  static const String addMeasurements = 'Add measurements';
  static const String addMeasurementsAr = 'أضف المقاسات';

  static const String currentDesign = 'Current design';
  static const String currentDesignAr = 'التصميم الحالي';

  static const String yourDesign = 'your design';
  static const String yourDesignAr = 'تصميمك';

  static String weWillFitUsingMeasurements(String name, Locale locale) => l(
        locale,
        'We will fit $name using these measurements.',
        'سنفصّل $name باستخدام هذه المقاسات.',
      );

  static String weWillTailorUsingMeasurements(String name, Locale locale) => l(
        locale,
        'We will tailor $name using these measurements.',
        'سنخيط $name باستخدام هذه المقاسات.',
      );

  static const String measurementsNeededForOrder =
      'We still need your body measurements to tailor this order.';
  static const String measurementsNeededForOrderAr =
      'ما زلنا نحتاج مقاسات جسمك لخياطة هذا الطلب.';

  // Delivery details
  static const String detectingLocationEllipsis = 'Detecting your location…';
  static const String detectingLocationEllipsisAr = 'جاري تحديد موقعك…';

  static const String preparingLocation = 'Preparing location…';
  static const String preparingLocationAr = 'جاري تجهيز الموقع…';

  static const String deliveryPrompt = 'Where should we deliver your order?';
  static const String deliveryPromptAr = 'أين نوصّل طلبك؟';

  static const String deliveryLocationHint =
      'We use your location automatically to assign the nearest tailor.';
  static const String deliveryLocationHintAr =
      'نستخدم موقعك تلقائياً لتعيين أقرب خياط.';

  static const String streetAddress = 'Street address';
  static const String streetAddressAr = 'عنوان الشارع';

  static const String required = 'Required';
  static const String requiredAr = 'مطلوب';

  static const String phone = 'Phone';
  static const String phoneAr = 'الهاتف';

  static const String enterReachablePhone = 'Enter a reachable phone';
  static const String enterReachablePhoneAr = 'أدخل رقماً يمكن الوصول إليه';

  static const String deliveryNotesOptional = 'Delivery notes (optional)';
  static const String deliveryNotesOptionalAr = 'ملاحظات التوصيل (اختياري)';

  static const String getPriceAndTailor = 'Get price & tailor';
  static const String getPriceAndTailorAr = 'احصل على السعر والخياط';

  static const String deliveryDetailsMissing =
      'Delivery details missing. Go back and try again.';
  static const String deliveryDetailsMissingAr =
      'تفاصيل التوصيل ناقصة. ارجع وحاول مرة أخرى.';

  static const String noTailorNearLocation =
      'No tailor available near this location.';
  static const String noTailorNearLocationAr =
      'لا يوجد خياط قريب من هذا الموقع.';

  // Order summary
  static const String priceAfterDeliveryHint =
      'Your price is calculated after you enter a delivery location. '
      'We assign the nearest tailor and use their rates.';
  static const String priceAfterDeliveryHintAr =
      'يُحسب سعرك بعد إدخال موقع التوصيل. نعيّن أقرب خياط ونستخدم أسعاره.';

  static const String checkingMeasurements =
      'Checking your latest measurements...';
  static const String checkingMeasurementsAr =
      'جاري التحقق من أحدث مقاساتك...';

  static const String measurementsFoundCheckoutEnabled =
      'Measurements found. Checkout is enabled.';
  static const String measurementsFoundCheckoutEnabledAr =
      'وُجدت المقاسات. يمكنك إتمام الطلب.';

  static const String measurementsMissingCompleteSizing =
      'Measurements are missing. Complete sizing before ordering.';
  static const String measurementsMissingCompleteSizingAr =
      'المقاسات ناقصة. أكمل القياس قبل الطلب.';

  static String measurementsSummaryLine(
    String chest,
    String waist,
    String height,
    Locale locale,
  ) =>
      l(
        locale,
        'Chest: $chest cm, Waist: $waist cm, Height: $height cm',
        'الصدر: $chest سم، الخصر: $waist سم، الطول: $height سم',
      );

  static const String saveDesignBeforeOrderFromEditor =
      'Please save this design first, then order it from the editor.';
  static const String saveDesignBeforeOrderFromEditorAr =
      'يرجى حفظ هذا التصميم أولاً، ثم اطلبه من المحرر.';

  // Quote review / negotiation
  static const String continueAtListOrNegotiate =
      'Continue at list price or negotiate with a tailor.';
  static const String continueAtListOrNegotiateAr =
      'تابع بالسعر المعلن أو فاوض خياطاً.';

  static const String acceptCounterBeforePay =
      'Accept the counter offer before paying, or choose another tailor.';
  static const String acceptCounterBeforePayAr =
      'اقبل العرض المضاد قبل الدفع، أو اختر خياطاً آخر.';

  static const String paymentUnavailablePendingOffer =
      'Payment is unavailable while your price offer is pending.';
  static const String paymentUnavailablePendingOfferAr =
      'الدفع غير متاح بينما عرض السعر قيد الانتظار.';

  static const String viewNegotiation = 'View negotiation';
  static const String viewNegotiationAr = 'عرض التفاوض';

  static String listPriceMinOffer(
    String total,
    String floor,
    Locale locale,
  ) =>
      l(
        locale,
        'List price: $total QAR • min offer $floor QAR',
        'السعر المعلن: $total ر.ق • الحد الأدنى للعرض $floor ر.ق',
      );

  static const String couldNotSendOffer = 'Could not send offer.';
  static const String couldNotSendOfferAr = 'تعذّر إرسال العرض.';

  static const String base = 'Base';
  static const String baseAr = 'الأساس';

  static String kmFromWorkshop(String km, Locale locale) => l(
        locale,
        '~$km km from workshop',
        '~$km كم من الورشة',
      );

  static const String couldNotLoadNegotiation = 'Could not load negotiation.';
  static const String couldNotLoadNegotiationAr = 'تعذّر تحميل التفاوض.';

  static const String priceAgreedContinuePayment =
      'Price agreed — continue to payment from here or Profile → Price negotiations';
  static const String priceAgreedContinuePaymentAr =
      'تم الاتفاق على السعر — تابع للدفع من هنا أو الملف → تفاوض الأسعار';

  static String listToCurrentOffer(
    String listTotal,
    String offeredTotal,
    String currency,
    Locale locale,
  ) =>
      l(
        locale,
        'List $listTotal $currency → Current offer $offeredTotal $currency',
        'السعر $listTotal $currency ← العرض الحالي $offeredTotal $currency',
      );

  static String acceptCounter(
    String total,
    String currency,
    Locale locale,
  ) =>
      l(
        locale,
        'Accept counter ($total $currency)',
        'قبول العرض المضاد ($total $currency)',
      );

  // Wedding quote
  static const String rentalSubtotal = 'Rental subtotal';
  static const String rentalSubtotalAr = 'إجمالي الإيجار';

  static const String dressPrice = 'Dress price';
  static const String dressPriceAr = 'سعر الفستان';

  // Order confirmation
  static String orderReference(String id, Locale locale) => l(
        locale,
        'Reference: $id',
        'المرجع: $id',
      );

  static const String demoPaymentNoCharge =
      'Demo payment mode: no real charge was captured.';
  static const String demoPaymentNoChargeAr =
      'وضع الدفع التجريبي: لم يُخصم مبلغ حقيقي.';
}
