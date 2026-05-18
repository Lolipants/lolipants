import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/admin/providers/admin_providers.dart';

/// All-orders oversight with status + reassignment controls.
class AdminOrdersScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  String? _status;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminOrdersProvider(_status));
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
                  DropdownMenuItem(value: 'placed', child: Text('placed')),
                  DropdownMenuItem(value: 'confirmed', child: Text('confirmed')),
                  DropdownMenuItem(value: 'cutting', child: Text('cutting')),
                  DropdownMenuItem(value: 'stitching', child: Text('stitching')),
                  DropdownMenuItem(
                      value: 'embroidery', child: Text('embroidery')),
                  DropdownMenuItem(
                      value: 'quality_check', child: Text('quality_check')),
                  DropdownMenuItem(
                      value: 'ready_to_ship', child: Text('ready_to_ship')),
                  DropdownMenuItem(
                      value: 'out_for_delivery',
                      child: Text('out_for_delivery')),
                  DropdownMenuItem(value: 'delivered', child: Text('delivered')),
                  DropdownMenuItem(value: 'cancelled', child: Text('cancelled')),
                ],
                onChanged: (v) => setState(() => _status = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminOrdersProvider(_status)),
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
              data: (orders) {
                if (orders.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    children: [
                      Center(
                        child: Text('No orders match the filter.',
                            style: AppTextStyles.bodyMedium),
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) => _OrderRow(
                    data: orders[i],
                    onChanged: () =>
                        ref.invalidate(adminOrdersProvider(_status)),
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

class _OrderRow extends ConsumerWidget {
  const _OrderRow({required this.data, required this.onChanged});
  final Map<String, dynamic> data;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = data['id']?.toString() ?? '';
    final status = data['status']?.toString() ?? '';
    final tailorId = data['tailorId']?.toString() ?? data['tailor_id']?.toString() ?? '';
    final courierId = data['courierId']?.toString() ?? data['courier_id']?.toString() ?? '';
    final designName = data['designName']?.toString() ?? data['design_name']?.toString() ?? 'Order';
    final city = data['deliveryCity']?.toString() ?? data['delivery_city']?.toString() ?? '';
    final fulfillment = data['fulfillment_type']?.toString() ??
        data['fulfillmentType']?.toString() ??
        '';
    final rentalDays = data['rental_days'] ?? data['rentalDays'];
    String? fulfillmentLabel;
    if (fulfillment == 'wedding_rent') {
      fulfillmentLabel = rentalDays != null
          ? 'Wedding rent · $rentalDays days'
          : 'Wedding rent';
    } else if (fulfillment == 'wedding_purchase') {
      fulfillmentLabel = 'Wedding purchase';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(designName, style: AppTextStyles.titleMedium),
                ),
                Chip(label: Text(status)),
              ],
            ),
            const SizedBox(height: 2),
            Text('Order #$id  $city', style: AppTextStyles.bodySmall),
            if (fulfillmentLabel != null)
              Text(fulfillmentLabel, style: AppTextStyles.labelGold.copyWith(fontSize: 12)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tailor: ${tailorId.isEmpty ? '—' : tailorId}  '
              'Courier: ${courierId.isEmpty ? '—' : courierId}',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                OutlinedButton(
                  onPressed: () => _changeStatus(context, ref, id),
                  child: const Text('Change status'),
                ),
                OutlinedButton(
                  onPressed: () => _reassign(context, ref, id, 'tailor'),
                  child: const Text('Reassign tailor'),
                ),
                OutlinedButton(
                  onPressed: () => _reassign(context, ref, id, 'courier'),
                  child: const Text('Reassign courier'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeStatus(BuildContext context, WidgetRef ref, String id) async {
    final v = await showDialog<String>(
      context: context,
      builder: (_) => const _OptionPickerDialog(
        title: 'New status',
        options: [
          'confirmed',
          'cutting',
          'stitching',
          'embroidery',
          'quality_check',
          'ready_to_ship',
          'out_for_delivery',
          'delivered',
          'cancelled',
        ],
      ),
    );
    if (v == null) return;
    final res = await ref
        .read(adminRepositoryProvider)
        .patchOrder(id: id, status: v);
    res.fold(
      (err) => _snack(context, 'Failed: ${err.runtimeType}'),
      (_) {
        _snack(context, 'Status updated');
        onChanged();
      },
    );
  }

  Future<void> _reassign(
    BuildContext context,
    WidgetRef ref,
    String id,
    String kind,
  ) async {
    final v = await showDialog<String>(
      context: context,
      builder: (_) => _TextPromptDialog(title: 'New $kind user id'),
    );
    if (v == null || v.trim().isEmpty) return;
    final res = await ref.read(adminRepositoryProvider).patchOrder(
          id: id,
          tailorId: kind == 'tailor' ? v.trim() : null,
          courierId: kind == 'courier' ? v.trim() : null,
        );
    res.fold(
      (err) => _snack(context, 'Failed: ${err.runtimeType}'),
      (_) {
        _snack(context, 'Reassigned');
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

class _OptionPickerDialog extends StatelessWidget {
  const _OptionPickerDialog({required this.title, required this.options});
  final String title;
  final List<String> options;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final o in options)
              ListTile(
                title: Text(o),
                onTap: () => Navigator.of(context).pop(o),
              ),
          ],
        ),
      ),
    );
  }
}

class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({required this.title});
  final String title;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
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
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Enter value'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_ctrl.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
