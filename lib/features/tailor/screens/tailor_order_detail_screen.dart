import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/constants/tailor_strings.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/orders/models/order.dart';
import 'package:lolipants/features/orders/models/order_status.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lolipants/features/orders/widgets/order_status_timeline.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';
import 'package:lolipants/features/tailor/providers/tailor_providers.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

const Map<String, List<String>> _tailorTransitions = {
  'placed': ['confirmed', 'cancelled'],
  'confirmed': ['cutting', 'cancelled'],
  'cutting': ['stitching', 'cancelled'],
  'stitching': ['embroidery', 'quality_check', 'cancelled'],
  'embroidery': ['quality_check', 'cancelled'],
  'quality_check': ['ready_to_ship', 'cancelled'],
  'ready_to_ship': ['cancelled'],
};

/// Detail view for a single order shown to the tailor role.
class TailorOrderDetailScreen extends ConsumerStatefulWidget {
  /// Takes [orderId] from the path.
  const TailorOrderDetailScreen({required this.orderId, super.key});

  /// Order id segment from the URL.
  final String orderId;

  @override
  ConsumerState<TailorOrderDetailScreen> createState() =>
      _TailorOrderDetailScreenState();
}

class _TailorOrderDetailScreenState
    extends ConsumerState<TailorOrderDetailScreen> {
  bool _busy = false;
  Order? _orderOverride;

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(settingsLocaleProvider);
    final async = ref.watch(tailorOrderDetailProvider(widget.orderId));
    final displayOrder = _orderOverride ?? async.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          TailorStrings.orderTitle(widget.orderId, locale),
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
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    TailorStrings.couldNotLoadOrderError(e, locale),
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
    final current = order.status;
    final allowed = _tailorTransitions[current.name] ??
        _tailorTransitions[_serverKey(current)] ??
        const <String>[];
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        _SummaryCard(order: order, showStatus: true, locale: locale),
        if (order.printImageUrl != null &&
            order.printImageUrl!.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          LolipantsButton(
            label: localizedFromLocale(
              locale,
              TailorStrings.downloadPrintFile,
              TailorStrings.downloadPrintFileAr,
            ),
            variant: LolipantsButtonVariant.secondary,
            onPressed: () => _openUrl(order.printImageUrl!, locale),
          ),
        ],
        if (order.sketchImageUrl != null &&
            order.sketchImageUrl!.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          LolipantsButton(
            label: localizedFromLocale(
              locale,
              TailorStrings.downloadSketch,
              TailorStrings.downloadSketchAr,
            ),
            variant: LolipantsButtonVariant.secondary,
            onPressed: () => _openUrl(order.sketchImageUrl!, locale),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        OrderStatusTimeline(order: order),
        const SizedBox(height: AppSpacing.lg),
        if (current == OrderStatus.placed) ...[
          LolipantsButton(
            label: localizedFromLocale(
              locale,
              TailorStrings.acceptThisOrder,
              TailorStrings.acceptThisOrderAr,
            ),
            loading: _busy,
            onPressed: _busy ? null : () => _accept(order, locale),
          ),
          const SizedBox(height: AppSpacing.sm),
          LolipantsButton(
            label: localizedFromLocale(
              locale,
              TailorStrings.declineWithReason,
              TailorStrings.declineWithReasonAr,
            ),
            variant: LolipantsButtonVariant.destructive,
            onPressed: _busy ? null : () => _declineWithReason(order, locale),
          ),
        ] else ...[
          for (final next in allowed)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: LolipantsButton(
                label: _advanceButtonLabel(next, locale),
                variant: next == 'cancelled'
                    ? LolipantsButtonVariant.destructive
                    : LolipantsButtonVariant.primary,
                loading: _busy,
                onPressed: _busy ? null : () => _advance(order, next, locale),
              ),
            ),
        ],
        const SizedBox(height: AppSpacing.sm),
        LolipantsButton(
          label: localizedFromLocale(
            locale,
            TailorStrings.back,
            TailorStrings.backAr,
          ),
          variant: LolipantsButtonVariant.secondary,
          onPressed: () => context.pop(),
        ),
      ],
    );
  }

  String _serverKey(OrderStatus s) {
    switch (s) {
      case OrderStatus.qualityCheck:
        return 'quality_check';
      case OrderStatus.readyToShip:
        return 'ready_to_ship';
      case OrderStatus.outForDelivery:
        return 'out_for_delivery';
      default:
        return s.name;
    }
  }

  OrderStatus? _statusFromKey(String key) {
    switch (key) {
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'cutting':
        return OrderStatus.cutting;
      case 'stitching':
        return OrderStatus.stitching;
      case 'embroidery':
        return OrderStatus.embroidery;
      case 'quality_check':
        return OrderStatus.qualityCheck;
      case 'ready_to_ship':
        return OrderStatus.readyToShip;
      case 'out_for_delivery':
        return OrderStatus.outForDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return null;
    }
  }

  String _prettyStatus(String key, Locale locale) {
    final status = _statusFromKey(key);
    if (status != null) return status.labelFor(locale);
    return key;
  }

  String _advanceButtonLabel(String next, Locale locale) {
    if (next == 'cancelled') {
      return localizedFromLocale(
        locale,
        TailorStrings.cancelOrder,
        TailorStrings.cancelOrderAr,
      );
    }
    if (next == 'ready_to_ship') {
      return localizedFromLocale(
        locale,
        TailorStrings.handOffToDelivery,
        TailorStrings.handOffToDeliveryAr,
      );
    }
    return TailorStrings.advanceTo(_prettyStatus(next, locale), locale);
  }

  Future<void> _accept(Order order, Locale locale) async {
    setState(() => _busy = true);
    final tailorRepo = ref.read(tailorRepositoryProvider);
    if (order.status != OrderStatus.placed) {
      _snack(
        localizedFromLocale(
          locale,
          TailorStrings.orderAlreadyConfirmed,
          TailorStrings.orderAlreadyConfirmedAr,
        ),
      );
      _unbusy();
      return;
    }
    final claim = await tailorRepo.claim(order.id);
    final claimErr = claim.fold<String?>(_tailorErrorMessage, (_) => null);
    if (claimErr != null) {
      _snack(TailorStrings.couldNotAcceptOrder(claimErr, locale));
      _unbusy();
      return;
    }
    final advance = await tailorRepo.advanceStatus(
      orderId: order.id,
      status: 'confirmed',
    );
    advance.fold(
      (e) => _snack(TailorStrings.couldNotConfirm(_tailorErrorMessage(e), locale)),
      (updated) {
        _snack(
          localizedFromLocale(
            locale,
            TailorStrings.orderAccepted,
            TailorStrings.orderAcceptedAr,
          ),
        );
        _finishMutation(updated);
      },
    );
    if (!advance.isRight()) _unbusy();
  }

  Future<void> _declineWithReason(Order order, Locale locale) async {
    final controller = TextEditingController();
    final reason = await showDialog<String?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          localizedFromLocale(
            locale,
            TailorStrings.declineOrderTitle,
            TailorStrings.declineOrderTitleAr,
          ),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: localizedFromLocale(
              locale,
              TailorStrings.reason,
              TailorStrings.reasonAr,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: Text(
              localizedFromLocale(
                locale,
                TailorStrings.cancel,
                TailorStrings.cancelAr,
              ),
            ),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(
              localizedFromLocale(
                locale,
                TailorStrings.decline,
                TailorStrings.declineAr,
              ),
            ),
          ),
        ],
      ),
    );
    if (reason == null) return;
    setState(() => _busy = true);
    final repo = ref.read(tailorRepositoryProvider);
    final result = await repo.advanceStatus(
      orderId: order.id,
      status: 'cancelled',
      note: reason.isEmpty ? null : reason,
    );
    result.fold(
      (e) => _snack(TailorStrings.couldNotDecline(_tailorErrorMessage(e), locale)),
      (updated) {
        _snack(
          localizedFromLocale(
            locale,
            TailorStrings.orderDeclined,
            TailorStrings.orderDeclinedAr,
          ),
        );
        _finishMutation(updated);
      },
    );
    if (!result.isRight()) _unbusy();
  }

  Future<void> _advance(Order order, String next, Locale locale) async {
    setState(() => _busy = true);
    final repo = ref.read(tailorRepositoryProvider);
    final result = await repo.advanceStatus(
      orderId: order.id,
      status: next,
    );
    result.fold(
      (e) => _snack(TailorStrings.couldNotAdvance(_tailorErrorMessage(e), locale)),
      (updated) {
        if (next == 'ready_to_ship') {
          final courier = updated.courierName;
          _snack(
            courier != null && courier.isNotEmpty
                ? TailorStrings.handedOffToCourier(courier, locale)
                : localizedFromLocale(
                    locale,
                    TailorStrings.handedOffToDelivery,
                    TailorStrings.handedOffToDeliveryAr,
                  ),
          );
        } else {
          _snack(
            TailorStrings.statusUpdatedTo(_prettyStatus(next, locale), locale),
          );
        }
        _finishMutation(updated);
      },
    );
    if (!result.isRight()) _unbusy();
  }

  void _finishMutation(Order updated) {
    invalidateAllTailorQueues(ref);
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

  String _tailorErrorMessage(AppException error) {
    if (error case ServerException(
          code: 'NO_COURIER_AVAILABLE',
          message: final msg,
        )) {
      return msg;
    }
    if (error case ServerException(statusCode: 403, message: final msg)) {
      return msg;
    }
    if (error case ServerException(statusCode: 409, message: final msg)) {
      return msg;
    }
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
    if (messenger == null) return;
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openUrl(String url, Locale locale) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _snack(
        localizedFromLocale(
          locale,
          TailorStrings.couldNotOpenFileLink,
          TailorStrings.couldNotOpenFileLinkAr,
        ),
      );
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.order,
    required this.locale,
    this.showStatus = false,
  });

  final Order order;
  final Locale locale;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          if (order.weddingFulfillmentLabel != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              order.weddingFulfillmentLabel!,
              style: AppTextStyles.labelGold.copyWith(fontSize: 12),
            ),
          ],
          if (showStatus) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              TailorStrings.statusLine(order.status.labelFor(locale), locale),
              style: AppTextStyles.labelGold.copyWith(fontSize: 12),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          _LabelValue(
            label: localizedFromLocale(
              locale,
              TailorStrings.address,
              TailorStrings.addressAr,
            ),
            value: order.deliveryAddress ?? '—',
          ),
          _LabelValue(
            label: localizedFromLocale(
              locale,
              TailorStrings.city,
              TailorStrings.cityAr,
            ),
            value: order.deliveryCity ?? '—',
          ),
          _LabelValue(
            label: localizedFromLocale(
              locale,
              TailorStrings.phone,
              TailorStrings.phoneAr,
            ),
            value: order.deliveryPhone ?? '—',
          ),
          _LabelValue(
            label: localizedFromLocale(
              locale,
              TailorStrings.total,
              TailorStrings.totalAr,
            ),
            value: order.totalPrice == null
                ? '—'
                : '${order.totalPrice} ${order.currency}',
          ),
          if (order.courierName != null && order.courierName!.isNotEmpty)
            _LabelValue(
              label: localizedFromLocale(
                locale,
                TailorStrings.courier,
                TailorStrings.courierAr,
              ),
              value: order.courierName!,
            ),
          if (order.paymentStatus != null)
            _LabelValue(
              label: localizedFromLocale(
                locale,
                TailorStrings.payment,
                TailorStrings.paymentAr,
              ),
              value: order.paymentStatus!,
            ),
        ],
      ),
    );
  }
}

class _LabelValue extends StatelessWidget {
  const _LabelValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: AppTextStyles.bodySmall),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }
}
