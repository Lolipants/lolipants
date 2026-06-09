import 'dart:ui' show Locale;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/permissions/device_permission_prompt.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/constants/delivery_strings.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/delivery/providers/delivery_providers.dart';
import 'package:lolipants/features/delivery/screens/delivery_proof_camera_screen.dart';
import 'package:lolipants/features/editor/providers/designs_providers.dart';
import 'package:lolipants/features/orders/models/order.dart';
import 'package:lolipants/features/orders/models/order_status.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Detail screen for the courier, exposing pick-up and delivered transitions.
class DeliveryOrderDetailScreen extends ConsumerStatefulWidget {
  /// Takes the [orderId] from the path.
  const DeliveryOrderDetailScreen({required this.orderId, super.key});

  /// Order id segment from the URL.
  final String orderId;

  @override
  ConsumerState<DeliveryOrderDetailScreen> createState() =>
      _DeliveryOrderDetailScreenState();
}

class _DeliveryOrderDetailScreenState
    extends ConsumerState<DeliveryOrderDetailScreen> {
  bool _busy = false;
  Order? _orderOverride;
  final ImagePicker _galleryPicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(settingsLocaleProvider);
    final async = ref.watch(deliveryOrderProvider(widget.orderId));
    final displayOrder = _orderOverride ?? async.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          DeliveryStrings.deliveryOrderTitle(widget.orderId, locale),
          style: AppTextStyles.titleMedium,
        ),
      ),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          if (displayOrder != null)
            _content(displayOrder, locale)
          else
            async.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    DeliveryStrings.couldNotLoadOrder(error, locale),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ),
              data: (order) => _content(order, locale),
            ),
        ],
      ),
    );
  }

  Widget _content(Order order, Locale locale) {
    final status = order.status;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.stone,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.designName, style: AppTextStyles.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                DeliveryStrings.statusLine(status.labelFor(locale), locale),
                style: AppTextStyles.labelGold.copyWith(fontSize: 12),
              ),
              const SizedBox(height: AppSpacing.xs),
              _row(
                localizedFromLocale(
                  locale,
                  DeliveryStrings.address,
                  DeliveryStrings.addressAr,
                ),
                order.deliveryAddress ?? '—',
              ),
              _row(
                localizedFromLocale(
                  locale,
                  DeliveryStrings.city,
                  DeliveryStrings.cityAr,
                ),
                order.deliveryCity ?? '—',
              ),
              _row(
                localizedFromLocale(
                  locale,
                  DeliveryStrings.phone,
                  DeliveryStrings.phoneAr,
                ),
                order.deliveryPhone ?? '—',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (status == OrderStatus.readyToShip)
          LolipantsButton(
            label: localizedFromLocale(
              locale,
              DeliveryStrings.markPickedUp,
              DeliveryStrings.markPickedUpAr,
            ),
            loading: _busy,
            onPressed: _busy ? null : _markPickedUp,
          ),
        if (status == OrderStatus.outForDelivery) ...[
          LolipantsButton(
            label: localizedFromLocale(
              locale,
              DeliveryStrings.markDeliveredWithPhoto,
              DeliveryStrings.markDeliveredWithPhotoAr,
            ),
            loading: _busy,
            onPressed: _busy ? null : _captureProofInApp,
          ),
          const SizedBox(height: AppSpacing.sm),
          LolipantsButton(
            label: localizedFromLocale(
              locale,
              DeliveryStrings.useGalleryPhoto,
              DeliveryStrings.useGalleryPhotoAr,
            ),
            variant: LolipantsButtonVariant.secondary,
            loading: _busy,
            onPressed: _busy ? null : _pickProofFromGallery,
          ),
        ],
        if (status == OrderStatus.delivered)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(
              DeliveryStrings.deliveredOn(
                dateFormatYMMMd(locale).format(order.placedAt),
                locale,
              ),
              style: AppTextStyles.bodySmall,
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        LolipantsButton(
          label: localizedFromLocale(
            locale,
            DeliveryStrings.back,
            DeliveryStrings.backAr,
          ),
          variant: LolipantsButtonVariant.secondary,
          onPressed: () => context.pop(),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: AppTextStyles.bodySmall),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }

  Future<void> _markPickedUp() async {
    setState(() => _busy = true);
    final locale = ref.read(settingsLocaleProvider);
    final repo = ref.read(deliveryRepositoryProvider);
    final result = await repo.markPickedUp(widget.orderId);
    if (!mounted) return;
    result.fold(
      (e) {
        _snack(DeliveryStrings.couldNotUpdate(_deliveryErrorMessage(e), locale));
        _unbusy();
      },
      (updated) {
        _snack(
          localizedFromLocale(
            locale,
            DeliveryStrings.markedPickedUp,
            DeliveryStrings.markedPickedUpAr,
          ),
        );
        _finishMutation(updated);
      },
    );
  }

  /// Opens an in-app camera preview (no external camera app / activity restart).
  Future<void> _captureProofInApp() async {
    final bytes = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute<Uint8List>(
        fullscreenDialog: true,
        builder: (_) => const DeliveryProofCameraScreen(),
      ),
    );
    if (bytes == null || bytes.isEmpty || !mounted) return;
    await _uploadProofBytesAndMarkDelivered(bytes);
  }

  /// Fallback when the in-app camera cannot start on a device.
  Future<void> _pickProofFromGallery() async {
    final locale = ref.read(settingsLocaleProvider);
    final granted = await DevicePermissionPrompt.ensureForImageSource(
      context,
      ImageSource.gallery,
    );
    if (!granted || !mounted) return;

    XFile? picked;
    try {
      picked = await _galleryPicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 70,
        requestFullMetadata: false,
      );
    } on Object {
      _snack(
        localizedFromLocale(
          locale,
          DeliveryStrings.couldNotOpenPhotoLibrary,
          DeliveryStrings.couldNotOpenPhotoLibraryAr,
        ),
      );
      return;
    }
    if (picked == null || !mounted) return;

    try {
      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) {
        _snack(
          localizedFromLocale(
            locale,
            DeliveryStrings.photoWasEmpty,
            DeliveryStrings.photoWasEmptyAr,
          ),
        );
        return;
      }
      await _uploadProofBytesAndMarkDelivered(bytes);
    } on Object {
      _snack(
        localizedFromLocale(
          locale,
          DeliveryStrings.couldNotReadPhoto,
          DeliveryStrings.couldNotReadPhotoAr,
        ),
      );
    }
  }

  Future<void> _uploadProofBytesAndMarkDelivered(Uint8List bytes) async {
    if (!mounted) return;
    setState(() => _busy = true);
    final locale = ref.read(settingsLocaleProvider);

    try {
      final designsRepo = ref.read(designsRepositoryProvider);
      final upload = await designsRepo.uploadPrintBytes(
        bytes: bytes,
        filename: 'delivery-proof.jpg',
      );
      final uploaded = upload.fold<String?>((_) => null, (url) => url);
      if (uploaded == null) {
        if (!mounted) return;
        _snack(
          localizedFromLocale(
            locale,
            DeliveryStrings.photoUploadFailed,
            DeliveryStrings.photoUploadFailedAr,
          ),
        );
        _unbusy();
        return;
      }

      final repo = ref.read(deliveryRepositoryProvider);
      final result = await repo.markDelivered(
        orderId: widget.orderId,
        proofUrl: uploaded,
      );
      if (!mounted) return;
      result.fold(
        (e) {
          _snack(
            DeliveryStrings.couldNotMarkDelivered(
              _deliveryErrorMessage(e),
              locale,
            ),
          );
          _unbusy();
        },
        (updated) {
          _snack(
            localizedFromLocale(
              locale,
              DeliveryStrings.deliveryRecorded,
              DeliveryStrings.deliveryRecordedAr,
            ),
          );
          _finishMutation(updated);
        },
      );
    } on Object {
      if (!mounted) return;
      _snack(
        localizedFromLocale(
          locale,
          DeliveryStrings.couldNotProcessPhoto,
          DeliveryStrings.couldNotProcessPhotoAr,
        ),
      );
      _unbusy();
    }
  }

  void _finishMutation(Order updated) {
    _invalidateDeliveryQueues();
    if (!mounted) return;
    setState(() {
      _orderOverride = updated;
      _busy = false;
    });
  }

  void _unbusy() {
    if (!mounted) return;
    setState(() => _busy = false);
  }

  void _invalidateDeliveryQueues() {
    for (final bucket in DeliveryQueueBucket.values) {
      ref.invalidate(deliveryQueueProvider(bucket));
    }
  }

  String _deliveryErrorMessage(AppException error) {
    if (error case ServerException(message: final msg) when msg.isNotEmpty) {
      return msg;
    }
    if (error case NetworkException(message: final msg)) {
      return msg;
    }
    return error.toString();
  }

  void _snack(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}
