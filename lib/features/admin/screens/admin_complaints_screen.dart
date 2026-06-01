import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/admin_strings.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
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
              Text(
                '${localized(ref, AdminStrings.statusLabel, AdminStrings.statusLabelAr)} ',
              ),
              const SizedBox(width: AppSpacing.sm),
              DropdownButton<String?>(
                value: _status,
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(
                      localized(ref, AdminStrings.filterAny, AdminStrings.filterAnyAr),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'open',
                    child: Text(
                      localized(ref, AdminStrings.filterOpen, AdminStrings.filterOpenAr),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'resolved',
                    child: Text(
                      localized(ref, AdminStrings.resolved, AdminStrings.resolvedAr),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'rejected',
                    child: Text(
                      localized(
                        ref,
                        AdminStrings.filterRejected,
                        AdminStrings.filterRejectedAr,
                      ),
                    ),
                  ),
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
                        child: Text(
                          localized(
                            ref,
                            AdminStrings.noComplaints,
                            AdminStrings.noComplaintsAr,
                          ),
                          style: AppTextStyles.bodyMedium,
                        ),
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
            Text(
              '${localized(ref, AdminStrings.fromLabel, AdminStrings.fromLabelAr)} $userId · $target',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(body, style: AppTextStyles.bodyMedium),
            if (resolution != null && resolution.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${localized(ref, AdminStrings.resolutionPrefix, AdminStrings.resolutionPrefixAr)} $resolution',
                style: AppTextStyles.bodySmall,
              ),
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
                    child: Text(
                      localized(ref, AdminStrings.resolve, AdminStrings.resolveAr),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () =>
                        _respond(context, ref, id, 'rejected'),
                    child: Text(
                      localized(ref, AdminStrings.reject, AdminStrings.rejectAr),
                    ),
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
      (err) => _snack(
        context,
        '${localized(ref, AdminStrings.failedPrefix, AdminStrings.failedPrefixAr)} ${err.runtimeType}',
      ),
      (_) {
        _snack(
          context,
          status == 'resolved'
              ? localized(ref, AdminStrings.resolved, AdminStrings.resolvedAr)
              : localized(ref, AdminStrings.rejectedSnack, AdminStrings.rejectedSnackAr),
        );
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

class _ResolutionDialog extends ConsumerStatefulWidget {
  const _ResolutionDialog({required this.status});
  final String status;

  @override
  ConsumerState<_ResolutionDialog> createState() => _ResolutionDialogState();
}

class _ResolutionDialogState extends ConsumerState<_ResolutionDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isResolved = widget.status == 'resolved';
    return AlertDialog(
      title: Text(
        localized(
          ref,
          isResolved
              ? AdminStrings.resolutionNoteOptional
              : AdminStrings.rejectionReasonOptional,
          isResolved
              ? AdminStrings.resolutionNoteOptionalAr
              : AdminStrings.rejectionReasonOptionalAr,
        ),
      ),
      content: TextField(
        controller: _ctrl,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: localized(
            ref,
            AdminStrings.internalNote,
            AdminStrings.internalNoteAr,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            localizedFromContext(context, AppStrings.cancel, AppStrings.cancelAr),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_ctrl.text),
          child: Text(
            localized(ref, AdminStrings.submit, AdminStrings.submitAr),
          ),
        ),
      ],
    );
  }
}
