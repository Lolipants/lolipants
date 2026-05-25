import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/admin/providers/admin_providers.dart';

/// Commission payout review + approve/mark-paid UI around the existing HMAC
/// endpoint. Admins with the payouts scope can flip payable commissions to
/// `paid` (optionally with a payout reference) or `void` them.
class AdminPayoutsScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const AdminPayoutsScreen({super.key});

  @override
  ConsumerState<AdminPayoutsScreen> createState() => _AdminPayoutsScreenState();
}

class _AdminPayoutsScreenState extends ConsumerState<AdminPayoutsScreen> {
  String? _status = 'approved';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminPayoutsProvider(_status));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const Text('Status: '),
              const SizedBox(width: AppSpacing.sm),
              DropdownButton<String?>(
                value: _status,
                hint: const Text('any'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('any')),
                  DropdownMenuItem(value: 'pending', child: Text('pending')),
                  DropdownMenuItem(value: 'approved', child: Text('approved')),
                  DropdownMenuItem(value: 'paid', child: Text('paid')),
                  DropdownMenuItem(value: 'void', child: Text('void')),
                ],
                onChanged: (v) => setState(() => _status = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(adminPayoutsProvider(_status)),
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
                  Text(
                    formatAdminProviderError(error),
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
              data: (rows) {
                if (rows.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    children: [
                      Center(
                        child: Text('No commissions match the filter.',
                            style: AppTextStyles.bodyMedium),
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) => _PayoutRow(
                    data: rows[i],
                    onChanged: () =>
                        ref.invalidate(adminPayoutsProvider(_status)),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _PayoutRow extends ConsumerWidget {
  const _PayoutRow({required this.data, required this.onChanged});
  final Map<String, dynamic> data;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = data['id']?.toString() ?? '';
    final status = data['status']?.toString() ?? '';
    final designerId = data['designerId']?.toString() ??
        data['designer_id']?.toString() ?? '';
    final amount = data['amountCents']?.toString() ??
        data['amount_cents']?.toString() ?? '0';
    final orderId = data['orderId']?.toString() ??
        data['order_id']?.toString() ?? '';

    final canPay = status == 'approved' || status == 'pending';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Commission #$id',
                      style: AppTextStyles.titleMedium),
                ),
                Chip(label: Text(status)),
              ],
            ),
            const SizedBox(height: 2),
            Text('Designer: $designerId', style: AppTextStyles.bodySmall),
            Text('Order: $orderId', style: AppTextStyles.bodySmall),
            Text('Amount: $amount (cents)', style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (canPay)
                  FilledButton.icon(
                    onPressed: () => _markPaid(context, ref, id),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Mark paid'),
                  ),
                if (status != 'paid' && status != 'void')
                  OutlinedButton.icon(
                    onPressed: () => _void(context, ref, id),
                    icon: const Icon(Icons.block, size: 18),
                    label: const Text('Void'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markPaid(BuildContext context, WidgetRef ref, String id) async {
    final reference = await showDialog<String>(
      context: context,
      builder: (_) => const _TextDialog(title: 'Payout reference (optional)'),
    );
    final res = await ref.read(adminRepositoryProvider).patchPayout(
          id: id,
          status: 'paid',
          payoutReference: (reference == null || reference.trim().isEmpty)
              ? null
              : reference.trim(),
        );
    res.fold(
      (err) => _snack(context, 'Failed: ${err.runtimeType}'),
      (_) {
        _snack(context, 'Marked paid');
        onChanged();
      },
    );
  }

  Future<void> _void(BuildContext context, WidgetRef ref, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Void commission?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Void')),
        ],
      ),
    );
    if (confirm != true) return;
    final res = await ref
        .read(adminRepositoryProvider)
        .patchPayout(id: id, status: 'void');
    res.fold(
      (err) => _snack(context, 'Failed: ${err.runtimeType}'),
      (_) {
        _snack(context, 'Voided');
        onChanged();
      },
    );
  }

  void _snack(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _TextDialog extends StatefulWidget {
  const _TextDialog({required this.title});
  final String title;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(controller: _ctrl, autofocus: true),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Skip')),
        FilledButton(
            onPressed: () => Navigator.of(context).pop(_ctrl.text),
            child: const Text('Save')),
      ],
    );
  }
}
