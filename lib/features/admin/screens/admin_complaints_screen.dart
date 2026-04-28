import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/admin/providers/admin_providers.dart';

/// Admin view of user-submitted complaints.
class AdminComplaintsScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const AdminComplaintsScreen({super.key});

  @override
  ConsumerState<AdminComplaintsScreen> createState() =>
      _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends ConsumerState<AdminComplaintsScreen> {
  String? _status = 'open';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminComplaintsProvider(_status));
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
                items: const [
                  DropdownMenuItem(value: null, child: Text('any')),
                  DropdownMenuItem(value: 'open', child: Text('open')),
                  DropdownMenuItem(value: 'resolved', child: Text('resolved')),
                  DropdownMenuItem(value: 'rejected', child: Text('rejected')),
                ],
                onChanged: (v) => setState(() => _status = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(adminComplaintsProvider(_status)),
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
                        child: Text('No complaints in this bucket.',
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
                  itemBuilder: (context, i) => _ComplaintCard(
                    data: rows[i],
                    onChanged: () =>
                        ref.invalidate(adminComplaintsProvider(_status)),
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

class _ComplaintCard extends ConsumerWidget {
  const _ComplaintCard({required this.data, required this.onChanged});
  final Map<String, dynamic> data;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = data['id']?.toString() ?? '';
    final subject = data['subject']?.toString() ?? '(no subject)';
    final body = data['body']?.toString() ?? '';
    final status = data['status']?.toString() ?? '';
    final userId = data['userId']?.toString() ??
        data['user_id']?.toString() ?? '';
    final target = '${data['targetType'] ?? data['target_type']}:'
        '${data['targetId'] ?? data['target_id']}';
    final resolution = data['resolution']?.toString();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child:
                      Text(subject, style: AppTextStyles.titleMedium),
                ),
                Chip(label: Text(status)),
              ],
            ),
            const SizedBox(height: 2),
            Text('From: $userId · $target', style: AppTextStyles.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            Text(body, style: AppTextStyles.bodyMedium),
            if (resolution != null && resolution.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text('Resolution: $resolution',
                  style: AppTextStyles.bodySmall),
            ],
            if (status == 'open') ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  FilledButton(
                    onPressed: () =>
                        _respond(context, ref, id, 'resolved'),
                    child: const Text('Resolve'),
                  ),
                  OutlinedButton(
                    onPressed: () =>
                        _respond(context, ref, id, 'rejected'),
                    child: const Text('Reject'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _respond(
    BuildContext context,
    WidgetRef ref,
    String id,
    String status,
  ) async {
    final note = await showDialog<String>(
      context: context,
      builder: (_) => _ResolutionDialog(status: status),
    );
    if (note == null) return;
    final res = await ref.read(adminRepositoryProvider).patchComplaint(
          id: id,
          status: status,
          resolution: note.trim().isEmpty ? null : note.trim(),
        );
    res.fold(
      (err) => _snack(context, 'Failed: ${err.runtimeType}'),
      (_) {
        _snack(context, status == 'resolved' ? 'Resolved' : 'Rejected');
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

class _ResolutionDialog extends StatefulWidget {
  const _ResolutionDialog({required this.status});
  final String status;

  @override
  State<_ResolutionDialog> createState() => _ResolutionDialogState();
}

class _ResolutionDialogState extends State<_ResolutionDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.status == 'resolved'
          ? 'Resolution note (optional)'
          : 'Rejection reason (optional)'),
      content: TextField(
        controller: _ctrl,
        maxLines: 3,
        decoration: const InputDecoration(hintText: 'Internal note'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_ctrl.text),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
