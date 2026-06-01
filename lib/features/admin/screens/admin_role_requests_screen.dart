import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/admin_strings.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/admin/providers/admin_providers.dart';
/// Admin queue for tailor/delivery role requests.
class AdminRoleRequestsScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const AdminRoleRequestsScreen({super.key});

  @override
  ConsumerState<AdminRoleRequestsScreen> createState() =>
      _AdminRoleRequestsScreenState();
}

class _AdminRoleRequestsScreenState
    extends ConsumerState<AdminRoleRequestsScreen> {
  String? _status = 'pending';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminRoleRequestsProvider(_status));
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
                    value: 'pending',
                    child: Text(
                      localized(
                        ref,
                        AdminStrings.filterPending,
                        AdminStrings.filterPendingAr,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'approved',
                    child: Text(
                      localized(
                        ref,
                        AdminStrings.filterApproved,
                        AdminStrings.filterApprovedAr,
                      ),
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
                ref.invalidate(adminRoleRequestsProvider(_status)),
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
                            AdminStrings.noRoleRequestsInFilter,
                            AdminStrings.noRoleRequestsInFilterAr,
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
                  itemBuilder: (context, i) => _RoleRequestCard(
                    data: rows[i],
                    onChanged: () =>
                        ref.invalidate(adminRoleRequestsProvider(_status)),
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

class _RoleRequestCard extends ConsumerWidget {
  const _RoleRequestCard({
    required this.data,
    required this.onChanged,
  });

  final Map<String, dynamic> data;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = data['id']?.toString() ?? '';
    final reqRole = data['requested_role']?.toString() ??
        data['requestedRole']?.toString() ??
        '';
    final status = data['status']?.toString() ?? '';
    final message = data['message']?.toString() ?? '';
    final name = data['requester_name']?.toString() ??
        data['requesterName']?.toString() ??
        '';
    final email = data['requester_email']?.toString() ??
        data['requesterEmail']?.toString() ??
        '';
    final created = data['created_at']?.toString() ?? '';
    final adminNote = data['admin_note']?.toString() ?? '';
    final pending = status == 'pending';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$reqRole · $name',
                    style: AppTextStyles.titleMedium,
                  ),
                ),
                Chip(label: Text(status)),
              ],
            ),
            Text(email, style: AppTextStyles.bodySmall),
            Text(created, style: AppTextStyles.bodySmall),
            if (message.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(message, style: AppTextStyles.bodyMedium),
            ],
            if (adminNote.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${localized(ref, AdminStrings.adminNotePrefix, AdminStrings.adminNotePrefixAr)} $adminNote',
                style: AppTextStyles.bodySmall,
              ),
            ],
            if (pending) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  FilledButton(
                    onPressed: () => _confirm(
                      context,
                      ref,
                      id,
                      approved: true,
                    ),
                    child: Text(
                      localized(ref, AdminStrings.approve, AdminStrings.approveAr),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  OutlinedButton(
                    onPressed: () => _confirm(
                      context,
                      ref,
                      id,
                      approved: false,
                    ),
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

  Future<void> _confirm(
    BuildContext context,
    WidgetRef ref,
    String id, {
    required bool approved,
  }) async {
    final noteCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          localized(
            ref,
            approved
                ? AdminStrings.approveRequestTitle
                : AdminStrings.rejectRequestTitle,
            approved
                ? AdminStrings.approveRequestTitleAr
                : AdminStrings.rejectRequestTitleAr,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              localized(
                ref,
                approved
                    ? AdminStrings.approveRequestBodyAssign
                    : AdminStrings.rejectRequestBodyResubmit,
                approved
                    ? AdminStrings.approveRequestBodyAssignAr
                    : AdminStrings.rejectRequestBodyResubmitAr,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(
                labelText: localized(
                  ref,
                  AdminStrings.noteOptional,
                  AdminStrings.noteOptionalAr,
                ),
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              localizedFromContext(ctx, AppStrings.cancel, AppStrings.cancelAr),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              localized(
                ref,
                approved ? AdminStrings.approve : AdminStrings.reject,
                approved ? AdminStrings.approveAr : AdminStrings.rejectAr,
              ),
            ),
          ),
        ],
      ),
    );
    if ((ok ?? false) && context.mounted) {
      final repo = ref.read(adminRepositoryProvider);
      final note = noteCtrl.text.trim();
      final result = await repo.patchRoleRequest(
        id: id,
        status: approved ? 'approved' : 'rejected',
        adminNote: note.isEmpty ? null : note,
      );
      noteCtrl.dispose();
      if (!context.mounted) return;
      result.fold(
        (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        },
        (_) {
          onChanged();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                localized(
                  ref,
                  approved ? AdminStrings.approvedSnack : AdminStrings.rejectedSnack,
                  approved
                      ? AdminStrings.approvedSnackAr
                      : AdminStrings.rejectedSnackAr,
                ),
              ),
            ),
          );
        },
      );
    } else {
      noteCtrl.dispose();
    }
  }
}
