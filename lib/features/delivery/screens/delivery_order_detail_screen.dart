import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/permissions/device_permission_prompt.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/delivery/providers/delivery_providers.dart';
import 'package:lolipants/features/editor/providers/designs_providers.dart';
import 'package:lolipants/features/orders/models/order.dart';
import 'package:lolipants/features/orders/models/order_status.dart';
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
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(deliveryOrderProvider(widget.orderId));
    final displayOrder = _orderOverride ?? async.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Delivery #${widget.orderId}',
          style: AppTextStyles.titleMedium,
        ),
      ),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          if (displayOrder != null)
            _content(displayOrder)
          else
            async.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    'Could not load order. $error',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ),
              data: _content,
            ),
        ],
      ),
    );
  }

  Widget _content(Order order) {
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
                'Status: ${status.labelEn}',
                style: AppTextStyles.labelGold.copyWith(fontSize: 12),
              ),
              const SizedBox(height: AppSpacing.xs),
              _row('Address', order.deliveryAddress ?? '—'),
              _row('City', order.deliveryCity ?? '—'),
              _row('Phone', order.deliveryPhone ?? '—'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (status == OrderStatus.readyToShip)
          LolipantsButton(
            label: 'Mark picked up',
            loading: _busy,
            onPressed: _busy ? null : _markPickedUp,
          ),
        if (status == OrderStatus.outForDelivery) ...[
          LolipantsButton(
            label: 'Mark delivered (with photo)',
            loading: _busy,
            onPressed: _busy ? null : _markDelivered,
          ),
        ],
        if (status == OrderStatus.delivered)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(
              'Delivered on ${order.placedAt}',
              style: AppTextStyles.bodySmall,
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        LolipantsButton(
          label: 'Back',
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
    final repo = ref.read(deliveryRepositoryProvider);
    final result = await repo.markPickedUp(widget.orderId);
    if (!mounted) return;
    result.fold(
      (e) {
        _snack('Could not update: ${_deliveryErrorMessage(e)}');
        _unbusy();
      },
      (updated) {
        _snack('Marked picked up');
        _finishMutation(updated);
      },
    );
  }

  Future<void> _markDelivered() async {
    final granted = await DevicePermissionPrompt.ensureForImageSource(
      context,
      ImageSource.camera,
    );
    if (!granted) return;
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      imageQuality: 70,
    );
    if (image == null) return;
    if (!mounted) return;
    setState(() => _busy = true);
    final designsRepo = ref.read(designsRepositoryProvider);
    final upload = await designsRepo.uploadPrintImage(filePath: image.path);
    final uploaded = upload.fold<String?>((_) => null, (url) => url);
    if (uploaded == null) {
      if (!mounted) return;
      _snack('Photo upload failed, try again.');
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
        _snack('Could not mark delivered: ${_deliveryErrorMessage(e)}');
        _unbusy();
      },
      (updated) {
        _snack('Delivery recorded');
        _finishMutation(updated);
      },
    );
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
