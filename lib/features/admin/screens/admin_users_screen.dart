import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/admin_strings.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/admin/providers/admin_providers.dart';
import 'package:lolipants/features/auth/models/user.dart';

/// User list with role + ban management.
class AdminUsersScreen extends ConsumerStatefulWidget {
  /// Creates the users screen.
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String? _roleFilter;
  bool? _bannedFilter;
  final _searchCtrl = TextEditingController();

  AdminUsersFilter get _filter => AdminUsersFilter(
        role: _roleFilter,
        banned: _bannedFilter,
        search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      );

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminUsersProvider(_filter));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onSubmitted: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: localized(
                      ref,
                      AdminStrings.searchNameEmail,
                      AdminStrings.searchNameEmailAr,
                    ),
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              DropdownButton<String?>(
                value: _roleFilter,
                hint: Text(
                  localized(ref, AdminStrings.roleLabel, AdminStrings.roleLabelAr),
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(
                      localized(ref, AdminStrings.anyRole, AdminStrings.anyRoleAr),
                    ),
                  ),
                  DropdownMenuItem(
                    value: UserRoles.user,
                    child: Text(
                      localized(ref, AdminStrings.roleUser, AdminStrings.roleUserAr),
                    ),
                  ),
                  DropdownMenuItem(
                    value: UserRoles.tailor,
                    child: Text(
                      localized(ref, AdminStrings.roleTailor, AdminStrings.roleTailorAr),
                    ),
                  ),
                  DropdownMenuItem(
                    value: UserRoles.delivery,
                    child: Text(
                      localized(
                        ref,
                        AdminStrings.roleDelivery,
                        AdminStrings.roleDeliveryAr,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: UserRoles.admin,
                    child: Text(
                      localized(ref, AdminStrings.roleAdmin, AdminStrings.roleAdminAr),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _roleFilter = v),
              ),
              const SizedBox(width: AppSpacing.sm),
              DropdownButton<bool?>(
                value: _bannedFilter,
                hint: Text(
                  localized(
                    ref,
                    AdminStrings.statusFilter,
                    AdminStrings.statusFilterAr,
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(
                      localized(ref, AdminStrings.filterAny, AdminStrings.filterAnyAr),
                    ),
                  ),
                  DropdownMenuItem(
                    value: false,
                    child: Text(
                      localized(
                        ref,
                        AdminStrings.statusActive,
                        AdminStrings.statusActiveAr,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: true,
                    child: Text(
                      localized(
                        ref,
                        AdminStrings.statusBanned,
                        AdminStrings.statusBannedAr,
                      ),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _bannedFilter = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminUsersProvider(_filter)),
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
                  const Icon(Icons.error_outline, size: 32),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    localized(
                      ref,
                      AdminStrings.couldNotLoadUsers,
                      AdminStrings.couldNotLoadUsersAr,
                    ),
                    style: AppTextStyles.bodyMedium,
                  ),
                  Text(
                    formatAdminProviderError(error),
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
              data: (users) {
                if (users.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    children: [
                      Center(
                        child: Text(
                          localized(
                            ref,
                            AdminStrings.noUsersMatch,
                            AdminStrings.noUsersMatchAr,
                          ),
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: users.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) => _UserTile(
                    data: users[i],
                    onChanged: () =>
                        ref.invalidate(adminUsersProvider(_filter)),
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

class _UserTile extends ConsumerWidget {
  const _UserTile({required this.data, required this.onChanged});
  final Map<String, dynamic> data;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = data['id']?.toString() ?? '';
    final name = data['name']?.toString() ?? '';
    final email = data['email']?.toString() ?? '';
    final role = data['role']?.toString() ?? UserRoles.user;
    final banned = data['bannedAt'] != null || data['banned'] == true;
    final scopes = _scopesOf(data['adminScopes'] ?? data['admin_scopes']);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name.isEmpty ? email : name,
                          style: AppTextStyles.titleMedium),
                      const SizedBox(height: 2),
                      Text(email, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                Chip(
                  label: Text(role),
                  backgroundColor: role == UserRoles.admin
                      ? Colors.amber.withValues(alpha: 0.2)
                      : null,
                ),
                if (banned) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Chip(
                    label: Text(
                      localized(
                        ref,
                        AdminStrings.statusBanned,
                        AdminStrings.statusBannedAr,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (scopes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final s in scopes)
                    Chip(label: Text(s), visualDensity: VisualDensity.compact),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _editRole(context, ref, id, role, scopes),
                  icon: const Icon(Icons.badge_outlined, size: 18),
                  label: Text(
                    localized(ref, AdminStrings.editRole, AdminStrings.editRoleAr),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _toggleBan(context, ref, id, banned),
                  icon: Icon(banned ? Icons.lock_open : Icons.block, size: 18),
                  label: Text(
                    banned
                        ? localized(ref, AdminStrings.unban, AdminStrings.unbanAr)
                        : localized(ref, AdminStrings.ban, AdminStrings.banAr),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<String> _scopesOf(Object? raw) {
    if (raw is List) {
      return raw
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        // Values come back as JSON strings when stored as TEXT.
        final v = raw.trim();
        if (v.startsWith('[')) {
          final list = <String>[];
          for (final part in v
              .substring(1, v.length - 1)
              .split(',')
              .map((p) => p.replaceAll('"', '').trim())) {
            if (part.isNotEmpty) list.add(part);
          }
          return list;
        }
      } on Exception {
        // fall through
      }
    }
    return const <String>[];
  }

  Future<void> _editRole(
    BuildContext context,
    WidgetRef ref,
    String id,
    String role,
    List<String> scopes,
  ) async {
    final result = await showDialog<_RoleEdit>(
      context: context,
      builder: (_) => _RoleEditDialog(initialRole: role, initialScopes: scopes),
    );
    if (result == null) return;
    final res = await ref.read(adminRepositoryProvider).patchUser(
          id: id,
          role: result.role,
          adminScopes: result.scopes,
        );
    res.fold(
      (err) => _snack(
        context,
        '${localized(ref, AdminStrings.failedPrefix, AdminStrings.failedPrefixAr)} ${err.runtimeType}',
      ),
      (_) {
        _snack(
          context,
          localized(ref, AdminStrings.updatedSnack, AdminStrings.updatedSnackAr),
        );
        onChanged();
      },
    );
  }

  Future<void> _toggleBan(
    BuildContext context,
    WidgetRef ref,
    String id,
    bool currentlyBanned,
  ) async {
    final res = await ref
        .read(adminRepositoryProvider)
        .patchUser(id: id, banned: !currentlyBanned);
    res.fold(
      (err) => _snack(
        context,
        '${localized(ref, AdminStrings.failedPrefix, AdminStrings.failedPrefixAr)} ${err.runtimeType}',
      ),
      (_) {
        _snack(
          context,
          currentlyBanned
              ? localized(ref, AdminStrings.userUnbanned, AdminStrings.userUnbannedAr)
              : localized(ref, AdminStrings.userBanned, AdminStrings.userBannedAr),
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

class _RoleEdit {
  const _RoleEdit(this.role, this.scopes);
  final String role;
  final List<String> scopes;
}

class _RoleEditDialog extends ConsumerStatefulWidget {
  const _RoleEditDialog({required this.initialRole, required this.initialScopes});
  final String initialRole;
  final List<String> initialScopes;

  @override
  ConsumerState<_RoleEditDialog> createState() => _RoleEditDialogState();
}

class _RoleEditDialogState extends ConsumerState<_RoleEditDialog> {
  late String _role = widget.initialRole;
  late final Set<String> _scopes = widget.initialScopes.toSet();

  static const _allScopes = [
    AdminScopes.superAdmin,
    AdminScopes.usersMgmt,
    AdminScopes.ordersOversight,
    AdminScopes.payouts,
    AdminScopes.moderation,
    AdminScopes.cms,
    AdminScopes.complaints,
    AdminScopes.tailorMgmt,
    AdminScopes.deliveryMgmt,
  ];

  @override
  Widget build(BuildContext context) {
    final isAdmin = _role == UserRoles.admin;
    return AlertDialog(
      title: Text(
        localized(
          ref,
          AdminStrings.editRoleScopes,
          AdminStrings.editRoleScopesAr,
        ),
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localized(ref, AdminStrings.roleHeading, AdminStrings.roleHeadingAr),
            ),
            DropdownButton<String>(
              value: _role,
              isExpanded: true,
              items: [
                DropdownMenuItem(
                  value: UserRoles.user,
                  child: Text(
                    localized(ref, AdminStrings.roleUser, AdminStrings.roleUserAr),
                  ),
                ),
                DropdownMenuItem(
                  value: UserRoles.tailor,
                  child: Text(
                    localized(ref, AdminStrings.roleTailor, AdminStrings.roleTailorAr),
                  ),
                ),
                DropdownMenuItem(
                  value: UserRoles.delivery,
                  child: Text(
                    localized(
                      ref,
                      AdminStrings.roleDelivery,
                      AdminStrings.roleDeliveryAr,
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: UserRoles.admin,
                  child: Text(
                    localized(ref, AdminStrings.roleAdmin, AdminStrings.roleAdminAr),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _role = v ?? _role),
            ),
            const SizedBox(height: AppSpacing.md),
            if (isAdmin) ...[
              Text(
                localized(
                  ref,
                  AdminStrings.adminScopes,
                  AdminStrings.adminScopesAr,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final s in _allScopes)
                    FilterChip(
                      label: Text(s),
                      selected: _scopes.contains(s),
                      onSelected: (sel) => setState(() {
                        sel ? _scopes.add(s) : _scopes.remove(s);
                      }),
                    ),
                ],
              ),
            ],
          ],
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
          onPressed: () => Navigator.of(context).pop(
            _RoleEdit(
              _role,
              isAdmin ? _scopes.toList(growable: false) : const <String>[],
            ),
          ),
          child: Text(localized(ref, AdminStrings.save, AdminStrings.saveAr)),
        ),
      ],
    );
  }
}
