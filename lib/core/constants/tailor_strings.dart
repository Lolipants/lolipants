import 'dart:ui' show Locale;

import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/tailor/providers/tailor_providers.dart';

/// Localized copy for tailor partner flows.
class TailorStrings {
  TailorStrings._();

  static String l(Locale locale, String en, String ar) =>
      localizedFromLocale(locale, en, ar);

  static const String dashboardTitle = 'Tailor dashboard';
  static const String dashboardTitleAr = 'لوحة الخياطة';

  static const String navIncoming = 'Incoming';
  static const String navIncomingAr = 'واردة';

  static const String navOffers = 'Offers';
  static const String navOffersAr = 'عروض';

  static const String navActive = 'Active';
  static const String navActiveAr = 'نشطة';

  static const String navCompleted = 'Completed';
  static const String navCompletedAr = 'مكتملة';

  static const String navPricing = 'Pricing';
  static const String navPricingAr = 'الأسعار';

  static const String noPriceRequests = 'No price requests';
  static const String noPriceRequestsAr = 'لا توجد طلبات أسعار';

  static const String priceRequestTitle = 'Price request';
  static const String priceRequestTitleAr = 'طلب سعر';

  static const String notFound = 'Not found';
  static const String notFoundAr = 'غير موجود';

  static String messageLine(String role, String body, Locale locale) => l(
        locale,
        '$role: $body',
        '$role: $body',
      );

  static const String acceptOffer = 'Accept offer';
  static const String acceptOfferAr = 'قبول العرض';

  static const String counterOfferQar = 'Counter offer (QAR)';
  static const String counterOfferQarAr = 'عرض مضاد (ر.ق)';

  static const String sendCounter = 'Send counter';
  static const String sendCounterAr = 'إرسال عرض مضاد';

  static const String decline = 'Decline';
  static const String declineAr = 'رفض';

  static const String reply = 'Reply';
  static const String replyAr = 'رد';

  static const String weddingPricingSaved = 'Wedding pricing saved';
  static const String weddingPricingSavedAr = 'تم حفظ أسعار العرس';

  static String weddingPricingError(Object error, Locale locale) => l(
        locale,
        'Wedding pricing: $error',
        'أسعار العرس: $error',
      );

  static const String weddingPricing = 'Wedding pricing';
  static const String weddingPricingAr = 'أسعار العرس';

  static const String saveWeddingPricing = 'Save wedding pricing';
  static const String saveWeddingPricingAr = 'حفظ أسعار العرس';

  static const String update = 'Update';
  static const String updateAr = 'تحديث';

  static String couldNotLoadPricing(Object error, Locale locale) => l(
        locale,
        'Could not load pricing: $error',
        'تعذّر تحميل الأسعار: $error',
      );

  static const String workshopAndPrices = 'Workshop & prices';
  static const String workshopAndPricesAr = 'الورشة والأسعار';

  static String serviceRadius(int km, Locale locale) => l(
        locale,
        'Service radius: $km km',
        'نطاق الخدمة: $km كم',
      );

  static const String acceptingNewOrders = 'Accepting new orders';
  static const String acceptingNewOrdersAr = 'قبول طلبات جديدة';

  static const String savePricing = 'Save pricing';
  static const String savePricingAr = 'حفظ الأسعار';

  static String orderTitle(String id, Locale locale) => l(
        locale,
        'Order $id',
        'طلب $id',
      );

  static const String downloadPrintFile = 'Download print file';
  static const String downloadPrintFileAr = 'تحميل ملف الطباعة';

  static const String downloadSketch = 'Download sketch';
  static const String downloadSketchAr = 'تحميل السكتش';

  static const String acceptThisOrder = 'Accept this order';
  static const String acceptThisOrderAr = 'قبول هذا الطلب';

  static const String declineWithReason = 'Decline with reason';
  static const String declineWithReasonAr = 'رفض مع سبب';

  static const String back = 'Back';
  static const String backAr = 'رجوع';

  static const String declineOrderTitle = 'Decline order';
  static const String declineOrderTitleAr = 'رفض الطلب';

  static const String cancel = 'Cancel';
  static const String cancelAr = 'إلغاء';

  static const String address = 'Address';
  static const String addressAr = 'العنوان';

  static const String city = 'City';
  static const String cityAr = 'المدينة';

  static const String phone = 'Phone';
  static const String phoneAr = 'الهاتف';

  static const String total = 'Total';
  static const String totalAr = 'الإجمالي';

  static const String courier = 'Courier';
  static const String courierAr = 'المندوب';

  static const String payment = 'Payment';
  static const String paymentAr = 'الدفع';

  static String statusLine(String status, Locale locale) => l(
        locale,
        'Status: $status',
        'الحالة: $status',
      );

  static const String signOut = 'Sign out';
  static const String signOutAr = 'تسجيل الخروج';

  static const String couldNotLoadOrders = 'Could not load orders.';
  static const String couldNotLoadOrdersAr = 'تعذّر تحميل الطلبات.';

  static const String pricingSaved = 'Pricing saved';
  static const String pricingSavedAr = 'تم حفظ الأسعار';

  static String couldNotLoadOrderError(Object error, Locale locale) => l(
        locale,
        'Could not load order. $error',
        'تعذّر تحميل الطلب. $error',
      );

  static const String cancelOrder = 'Cancel order';
  static const String cancelOrderAr = 'إلغاء الطلب';

  static const String handOffToDelivery = 'Hand off to delivery';
  static const String handOffToDeliveryAr = 'تسليم للتوصيل';

  static String advanceTo(String status, Locale locale) => l(
        locale,
        'Advance to $status',
        'الانتقال إلى $status',
      );

  static const String orderAlreadyConfirmed = 'Order is already confirmed';
  static const String orderAlreadyConfirmedAr = 'الطلب مؤكد بالفعل';

  static String couldNotAcceptOrder(String err, Locale locale) => l(
        locale,
        'Could not accept order: $err',
        'تعذّر قبول الطلب: $err',
      );

  static String couldNotConfirm(String err, Locale locale) => l(
        locale,
        'Could not confirm: $err',
        'تعذّر التأكيد: $err',
      );

  static const String orderAccepted = 'Order accepted';
  static const String orderAcceptedAr = 'تم قبول الطلب';

  static const String reason = 'Reason';
  static const String reasonAr = 'السبب';

  static String couldNotDecline(String err, Locale locale) => l(
        locale,
        'Could not decline: $err',
        'تعذّر الرفض: $err',
      );

  static const String orderDeclined = 'Order declined';
  static const String orderDeclinedAr = 'تم رفض الطلب';

  static String couldNotAdvance(String err, Locale locale) => l(
        locale,
        'Could not advance: $err',
        'تعذّر تحديث الحالة: $err',
      );

  static String handedOffToCourier(String name, Locale locale) => l(
        locale,
        'Handed off to $name',
        'تم التسليم إلى $name',
      );

  static const String handedOffToDelivery = 'Handed off to delivery';
  static const String handedOffToDeliveryAr = 'تم التسليم للتوصيل';

  static String statusUpdatedTo(String status, Locale locale) => l(
        locale,
        'Status updated to $status',
        'تم تحديث الحالة إلى $status',
      );

  static const String couldNotOpenFileLink = 'Could not open file link.';
  static const String couldNotOpenFileLinkAr = 'تعذّر فتح رابط الملف.';

  static const String enterValidWorkshopCoords =
      'Enter valid workshop latitude and longitude';
  static const String enterValidWorkshopCoordsAr =
      'أدخل خط عرض وطول صحيحين لورشة العمل';

  static const String detectingWorkshopLocation =
      'Detecting workshop location…';
  static const String detectingWorkshopLocationAr =
      'جاري تحديد موقع الورشة…';

  static String workshopPin(double lat, double lng, Locale locale) => l(
        locale,
        'Workshop pin: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
        'موقع الورشة: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
      );

  static const String setWorkshopOnMap =
      'Set your workshop on the map for customer matching';
  static const String setWorkshopOnMapAr =
      'حدد ورشتك على الخريطة لمطابقة العملاء';

  static const String workshopLocation = 'Workshop location';
  static const String workshopLocationAr = 'موقع الورشة';

  static const String shopName = 'Shop name';
  static const String shopNameAr = 'اسم المحل';

  static const String requiresWorkshopCoords =
      'Requires workshop coordinates and at least one price row';
  static const String requiresWorkshopCoordsAr =
      'يتطلب إحداثيات الورشة وصف سعر واحد على الأقل';

  static const String garmentPricesQar = 'Garment prices (QAR)';
  static const String garmentPricesQarAr = 'أسعار الملابس (ر.ق)';

  static const String basePlusFabricFee =
      'Base + fabric fee per garment type and fabric tier.';
  static const String basePlusFabricFeeAr =
      'السعر الأساسي + رسوم القماش لكل نوع ملبس ومستوى قماش.';

  static const String deliveryFeesQar = 'Delivery fees (QAR)';
  static const String deliveryFeesQarAr = 'رسوم التوصيل (ر.ق)';

  static const String base = 'Base';
  static const String baseAr = 'أساسي';

  static const String fabricFee = 'Fabric fee';
  static const String fabricFeeAr = 'رسوم القماش';

  static const String couldNotSavePricing =
      'Could not save pricing. Please try again.';
  static const String couldNotSavePricingAr =
      'تعذّر حفظ الأسعار. يرجى المحاولة مرة أخرى.';

  static const String networkIssueSavingPricing =
      'Network issue while saving pricing. Please retry.';
  static const String networkIssueSavingPricingAr =
      'مشكلة في الشبكة أثناء حفظ الأسعار. يرجى إعادة المحاولة.';

  static const String sessionExpired =
      'Your session has expired. Please sign in again.';
  static const String sessionExpiredAr =
      'انتهت جلستك. يرجى تسجيل الدخول مرة أخرى.';

  static const String couldNotLoadRequests = 'Could not load requests.';
  static const String couldNotLoadRequestsAr = 'تعذّر تحميل الطلبات.';

  static String offerTotal(int total, String currency, Locale locale) => l(
        locale,
        'Offer $total $currency',
        'عرض $total $currency',
      );

  static String listTotalStatus(
    int total,
    String status,
    Locale locale,
  ) =>
      l(
        locale,
        'List $total • $status',
        'القائمة $total • $status',
      );

  static String customerOffer(int total, String currency, Locale locale) => l(
        locale,
        'Customer offer: $total $currency',
        'عرض العميل: $total $currency',
      );

  static String listPrice(int total, String currency, Locale locale) => l(
        locale,
        'List price: $total $currency',
        'سعر القائمة: $total $currency',
      );

  static String noteLine(String note, Locale locale) => l(
        locale,
        'Note: $note',
        'ملاحظة: $note',
      );

  static const String couldNotLoadOrdersRetry =
      'Could not load orders. Pull to retry.';
  static const String couldNotLoadOrdersRetryAr =
      'تعذّر تحميل الطلبات. اسحب للمحاولة مرة أخرى.';

  static const String noIncomingOrders =
      'No incoming orders right now. Pull to refresh.';
  static const String noIncomingOrdersAr =
      'لا توجد طلبات واردة حالياً. اسحب للتحديث.';

  static const String noActiveOrders = 'No orders in progress.';
  static const String noActiveOrdersAr = 'لا توجد طلبات قيد التنفيذ.';

  static const String noCompletedOrders = 'No completed orders yet.';
  static const String noCompletedOrdersAr = 'لا توجد طلبات مكتملة بعد.';

  static const String weddingPricingSubtitle =
      'Rent per day, sale price, and insurance deposit by category.';
  static const String weddingPricingSubtitleAr =
      'إيجار يومي وسعر البيع ووديعة التأمين حسب الفئة.';

  static const String bridalGown = 'Bridal gown';
  static const String bridalGownAr = 'فستان عروس';

  static const String bridesmaid = 'Bridesmaid';
  static const String bridesmaidAr = 'وصيفة عروس';

  static const String rentPerDayQar = 'Rent / day (QAR)';
  static const String rentPerDayQarAr = 'إيجار / يوم (ر.ق)';

  static const String salePriceQar = 'Sale price (QAR)';
  static const String salePriceQarAr = 'سعر البيع (ر.ق)';

  static const String insuranceDepositQar = 'Insurance deposit (QAR)';
  static const String insuranceDepositQarAr = 'وديعة التأمين (ر.ق)';

  static const String couldNotSaveWeddingPricing =
      'Could not save wedding pricing';
  static const String couldNotSaveWeddingPricingAr =
      'تعذّر حفظ أسعار العرس';

  static const String networkIssueSavingWeddingPricing =
      'Network issue while saving wedding pricing.';
  static const String networkIssueSavingWeddingPricingAr =
      'مشكلة في الشبكة أثناء حفظ أسعار العرس.';

  static String emptyMessageForBucket(
    TailorQueueBucket bucket,
    Locale locale,
  ) =>
      switch (bucket) {
        TailorQueueBucket.incoming => l(
            locale,
            noIncomingOrders,
            noIncomingOrdersAr,
          ),
        TailorQueueBucket.active => l(
            locale,
            noActiveOrders,
            noActiveOrdersAr,
          ),
        TailorQueueBucket.completed => l(
            locale,
            noCompletedOrders,
            noCompletedOrdersAr,
          ),
      };
}
