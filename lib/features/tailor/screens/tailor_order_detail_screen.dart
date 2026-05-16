import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/orders/models/order.dart';
import 'package:lolipants/features/orders/models/order_status.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lolipants/features/orders/widgets/order_status_timeline.dart';
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
  'ready_to_ship': ['out_for_delivery', 'cancelled'],
  'out_for_delivery': ['delivered'],
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

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(tailorOrderDetailProvider(widget.orderId));
    return Scaffold(
      appBar: AppBar(
        title: Text('Order ${widget.orderId}',
            style: AppTextStyles.titleMedium),
      ),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'Could not load order. $e',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            ),
            data: (order) => _content(order),
          ),
        ],
      ),
    );
  }

  Widget _content(Order order) {
    final current = order.status;
    final allowed = _tailorTransitions[current.name] ??
        _tailorTransitions[_serverKey(current)] ??
        const <String>[];
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        _SummaryCard(order: order),
        if (order.printImageUrl != null &&
            order.printImageUrl!.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          LolipantsButton(
            label: 'Download print file / تحميل ملف الطباعة',
            variant: LolipantsButtonVariant.secondary,
            onPressed: () => _openUrl(order.printImageUrl!),
          ),
        ],
        if (order.sketchImageUrl != null &&
            order.sketchImageUrl!.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          LolipantsButton(
            label: 'Download sketch / تحميل السكتش',
            variant: LolipantsButtonVariant.secondary,
            onPressed: () => _openUrl(order.sketchImageUrl!),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        OrderStatusTimeline(order: order),
        const SizedBox(height: AppSpacing.lg),
        if (current == OrderStatus.placed) ...[
          LolipantsButton(
            label: _busy ? 'Working...' : 'Accept this order',
            onPressed: _busy ? null : () => _accept(order),
          ),
          const SizedBox(height: AppSpacing.sm),
          LolipantsButton(
            label: 'Decline with reason',
            variant: LolipantsButtonVariant.destructive,
            onPressed: _busy ? null : () => _declineWithReason(order),
          ),
        ] else ...[
          for (final next in allowed)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: LolipantsButton(
                label: next == 'cancelled'
                    ? 'Cancel order'
                    : 'Advance to ${_prettyStatus(next)}',
                variant: next == 'cancelled'
                    ? LolipantsButtonVariant.destructive
                    : LolipantsButtonVariant.primary,
                onPressed: _busy ? null : () => _advance(order, next),
              ),
            ),
        ],
        const SizedBox(height: AppSpacing.sm),
        LolipantsButton(
          label: 'Back',
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

  String _prettyStatus(String key) {
    switch (key) {
      case 'confirmed':
        return 'Confirmed';
      case 'cutting':
        return 'Cutting';
      case 'stitching':
        return 'Stitching';
      case 'embroidery':
        return 'Embroidery';
      case 'quality_check':
        return 'Quality check';
      case 'ready_to_ship':
        return 'Ready to ship';
      case 'out_for_delivery':
        return 'Out for delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return key;
    }
  }

  Future<void> _accept(Order order) async {
    setState(() => _busy = true);
    final tailorRepo = ref.read(tailorRepositoryProvider);
    final claim = await tailorRepo.claim(order.id);
    final claimErr = claim.fold<String?>((e) => '$e', (_) => null);
    if (claimErr != null) {
      _snack('Could not accept order: $claimErr');
      if (mounted) setState(() => _busy = false);
      return;
    }
    final advance = await tailorRepo.advanceStatus(
      orderId: order.id,
      status: 'confirmed',
    );
    advance.fold(
      (e) => _snack('Could not confirm: $e'),
      (_) => _snack('Order accepted'),
    );
    _refreshAndUnbusy();
  }

  Future<void> _declineWithReason(Order order) async {
    final controller = TextEditingController();
    final reason = await showDialog<String?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Decline order'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Reason'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Decline'),
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
      (e) => _snack('Could not decline: $e'),
      (_) => _snack('Order declined'),
    );
    _refreshAndUnbusy();
  }

  Future<void> _advance(Order order, String next) async {
    setState(() => _busy = true);
    final repo = ref.read(tailorRepositoryProvider);
    final result = await repo.advanceStatus(
      orderId: order.id,
      status: next,
    );
    result.fold(
      (e) => _snack('Could not advance: $e'),
      (_) => _snack('Status updated to ${_prettyStatus(next)}'),
    );
    _refreshAndUnbusy();
  }

  void _refreshAndUnbusy() {
    ref.invalidate(tailorOrderDetailProvider(widget.orderId));
    ref.invalidate(tailorQueueProvider);
    if (mounted) setState(() => _busy = false);
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _snack('Could not open file link.');
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.order});

  final Order order;

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
          const SizedBox(height: AppSpacing.xs),
          _LabelValue(
            label: 'Address',
            value: order.deliveryAddress ?? '—',
          ),
          _LabelValue(label: 'City', value: order.deliveryCity ?? '—'),
          _LabelValue(label: 'Phone', value: order.deliveryPhone ?? '—'),
          _LabelValue(
            label: 'Total',
            value: order.totalPrice == null
                ? '—'
                : '${order.totalPrice} ${order.currency}',
          ),
          if (order.paymentStatus != null)
            _LabelValue(label: 'Payment', value: order.paymentStatus!),
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
