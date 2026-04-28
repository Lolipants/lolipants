import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
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
                  decoration: const InputDecoration(
                    hintText: 'Search name/email',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              DropdownButton<String?>(
                value: _roleFilter,
                hint: const Text('role'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('any role')),
                  DropdownMenuItem(
                      value: UserRoles.user, child: Text('user')),
                  DropdownMenuItem(
                      value: UserRoles.tailor, child: Text('tailor')),
                  DropdownMenuItem(
                      value: UserRoles.delivery, child: Text('delivery')),
                  DropdownMenuItem(
                      value: UserRoles.admin, child: Text('admin')),
                ],
                onChanged: (v) => setState(() => _roleFilter = v),
              ),
              const SizedBox(width: AppSpacing.sm),
              DropdownButton<bool?>(
                value: _bannedFilter,
                hint: const Text('status'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('any')),
                  DropdownMenuItem(value: false, child: Text('active')),
                  DropdownMenuItem(value: true, child: Text('banned')),
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
                  Text('Could not load users.',
                      style: AppTextStyles.bodyMedium),
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
                        child: Text('No users match the filter.',
                            style: AppTextStyles.bodyMedium),
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
                  const Chip(label: Text('banned')),
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
                  label: const Text('Edit role'),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _toggleBan(context, ref, id, banned),
                  icon: Icon(banned ? Icons.lock_open : Icons.block, size: 18),
                  label: Text(banned ? 'Unban' : 'Ban'),
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
      (err) => _snack(context, 'Failed: ${err.runtimeType}'),
      (_) {
        _snack(context, 'Updated');
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
      (err) => _snack(context, 'Failed: ${err.runtimeType}'),
      (_) {
        _snack(context, currentlyBanned ? 'User unbanned' : 'User banned');
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

class _RoleEditDialog extends StatefulWidget {
  const _RoleEditDialog({required this.initialRole, required this.initialScopes});
  final String initialRole;
  final List<String> initialScopes;

  @override
  State<_RoleEditDialog> createState() => _RoleEditDialogState();
}

class _RoleEditDialogState extends State<_RoleEditDialog> {
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
      title: const Text('Edit role + scopes'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Role'),
            DropdownButton<String>(
              value: _role,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: UserRoles.user, child: Text('user')),
                DropdownMenuItem(value: UserRoles.tailor, child: Text('tailor')),
                DropdownMenuItem(
                    value: UserRoles.delivery, child: Text('delivery')),
                DropdownMenuItem(value: UserRoles.admin, child: Text('admin')),
              ],
              onChanged: (v) => setState(() => _role = v ?? _role),
            ),
            const SizedBox(height: AppSpacing.md),
            if (isAdmin) ...[
              const Text('Admin scopes'),
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
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            _RoleEdit(
              _role,
              isAdmin ? _scopes.toList(growable: false) : const <String>[],
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
