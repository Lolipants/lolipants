import 'dart:ui' show Locale;

import 'package:lolipants/core/l10n/app_localization.dart';

/// Localized copy for delivery partner flows.
class DeliveryStrings {
  DeliveryStrings._();

  static String l(Locale locale, String en, String ar) =>
      localizedFromLocale(locale, en, ar);

  static const String dashboardTitle = 'Delivery dashboard';
  static const String dashboardTitleAr = 'لوحة التوصيل';

  static const String navQueue = 'Queue';
  static const String navQueueAr = 'قائمة الانتظار';

  static const String navActive = 'Active';
  static const String navActiveAr = 'نشط';

  static const String navHistory = 'History';
  static const String navHistoryAr = 'السجل';

  static const String claim = 'Claim';
  static const String claimAr = 'استلام';

  static const String orderClaimed = 'Order claimed.';
  static const String orderClaimedAr = 'تم استلام الطلب.';

  static String couldNotClaim(Object error, Locale locale) => l(
        locale,
        'Could not claim: $error',
        'تعذّر الاستلام: $error',
      );

  static const String couldNotLoadOrders = 'Could not load orders.';
  static const String couldNotLoadOrdersAr = 'تعذّر تحميل الطلبات.';

  static const String proofPhotoTitle = 'Delivery proof photo';
  static const String proofPhotoTitleAr = 'صورة إثبات التسليم';

  static String deliveryOrderTitle(String id, Locale locale) => l(
        locale,
        'Delivery #$id',
        'توصيل #$id',
      );

  static String couldNotLoadOrder(Object error, Locale locale) => l(
        locale,
        'Could not load order. $error',
        'تعذّر تحميل الطلب. $error',
      );

  static String statusLine(String status, Locale locale) => l(
        locale,
        'Status: $status',
        'الحالة: $status',
      );

  static const String address = 'Address';
  static const String addressAr = 'العنوان';

  static const String city = 'City';
  static const String cityAr = 'المدينة';

  static const String phone = 'Phone';
  static const String phoneAr = 'الهاتف';

  static const String markPickedUp = 'Mark picked up';
  static const String markPickedUpAr = 'تأكيد الاستلام';

  static const String markDeliveredWithPhoto = 'Mark delivered (with photo)';
  static const String markDeliveredWithPhotoAr = 'تأكيد التسليم (مع صورة)';

  static const String useGalleryPhoto = 'Use gallery photo instead';
  static const String useGalleryPhotoAr = 'استخدام صورة من المعرض';

  static String deliveredOn(String date, Locale locale) => l(
        locale,
        'Delivered on $date',
        'تم التسليم في $date',
      );

  static const String back = 'Back';
  static const String backAr = 'رجوع';

  static const String noUnassignedPickups =
      'No unassigned pickups in your area.';
  static const String noUnassignedPickupsAr =
      'لا توجد طلبات غير مسندة في منطقتك.';

  static const String noActiveDeliveries = 'No active deliveries.';
  static const String noActiveDeliveriesAr = 'لا توجد توصيلات نشطة.';

  static const String noDeliveryHistory = 'No delivery history yet.';
  static const String noDeliveryHistoryAr = 'لا يوجد سجل توصيل بعد.';

  static const String queueEmptyMessage =
      'No unassigned pickups. Tailors assign deliveries automatically; this tab is for unclaimed overflow only.';
  static const String queueEmptyMessageAr =
      'لا توجد طلبات غير مسندة. يُسند الخياطون التوصيل تلقائياً؛ هذا التبويب للطلبات غير المستلمة فقط.';

  static const String signOut = 'Sign out';
  static const String signOutAr = 'تسجيل الخروج';

  static const String activeEmptyMessage =
      'No active deliveries. New jobs appear here when a tailor hands off an order to you.';
  static const String activeEmptyMessageAr =
      'لا توجد توصيلات نشطة. تظهر المهام الجديدة هنا عند تسليم الخياط الطلب إليك.';

  static const String historyEmptyMessage =
      'No completed deliveries yet — successful drop-offs show up here.';
  static const String historyEmptyMessageAr =
      'لا يوجد سجل توصيل مكتمل بعد — تظهر التسليمات الناجحة هنا.';

  static const String markedPickedUp = 'Marked picked up';
  static const String markedPickedUpAr = 'تم تأكيد الاستلام';

  static String couldNotUpdate(Object error, Locale locale) => l(
        locale,
        'Could not update: $error',
        'تعذّر التحديث: $error',
      );

  static const String couldNotOpenPhotoLibrary =
      'Could not open the photo library.';
  static const String couldNotOpenPhotoLibraryAr =
      'تعذّر فتح مكتبة الصور.';

  static const String photoWasEmpty = 'Photo was empty. Try another image.';
  static const String photoWasEmptyAr =
      'الصورة فارغة. جرّب صورة أخرى.';

  static const String couldNotReadPhoto = 'Could not read the selected photo.';
  static const String couldNotReadPhotoAr = 'تعذّر قراءة الصورة المحددة.';

  static const String photoUploadFailed = 'Photo upload failed. Try again.';
  static const String photoUploadFailedAr = 'فشل رفع الصورة. حاول مرة أخرى.';

  static String couldNotMarkDelivered(Object error, Locale locale) => l(
        locale,
        'Could not mark delivered: $error',
        'تعذّر تأكيد التسليم: $error',
      );

  static const String deliveryRecorded = 'Delivery recorded';
  static const String deliveryRecordedAr = 'تم تسجيل التسليم';

  static const String couldNotProcessPhoto =
      'Could not process the delivery photo. Please try again.';
  static const String couldNotProcessPhotoAr =
      'تعذّر معالجة صورة التسليم. حاول مرة أخرى.';

  static const String noCameraFound = 'No camera found on this device.';
  static const String noCameraFoundAr = 'لا توجد كاميرا على هذا الجهاز.';

  static String couldNotStartCamera(String type, Locale locale) => l(
        locale,
        'Could not start camera ($type).',
        'تعذّر تشغيل الكاميرا ($type).',
      );

  static const String photoEmptyRetry = 'Photo was empty. Try again.';
  static const String photoEmptyRetryAr = 'الصورة فارغة. حاول مرة أخرى.';

  static const String couldNotTakePhoto = 'Could not take photo. Try again.';
  static const String couldNotTakePhotoAr = 'تعذّر التقاط الصورة. حاول مرة أخرى.';

  static const String capturing = 'Capturing…';
  static const String capturingAr = 'جارٍ الالتقاط…';

  static const String takePhoto = 'Take photo';
  static const String takePhotoAr = 'التقاط صورة';

  static const String photographParcelHint =
      'Photograph the parcel at the customer door.';
  static const String photographParcelHintAr =
      'صوّر الطرد عند باب العميل.';
}
