import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/errors/app_exception_message_mapper.dart';
import 'package:lolipants/features/role_request/providers/role_request_providers.dart';

/// Lets a customer request tailor or delivery partner access.
class RoleRequestScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const RoleRequestScreen({super.key});

  @override
  ConsumerState<RoleRequestScreen> createState() => _RoleRequestScreenState();
}

class _RoleRequestScreenState extends ConsumerState<RoleRequestScreen> {
  String _requestedRole = 'tailor';
  final _messageCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  bool _hasPending(List<Map<String, dynamic>> rows) {
    for (final r in rows) {
      if ((r['status']?.toString() ?? '') == 'pending') return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(myRoleRequestsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner with Lolipants'),
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.sand,
      ),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              e is AppException
                  ? mapAppExceptionMessage(
                      e,
                      fallback: 'Could not load requests.',
                      networkMessage:
                          'Network issue. Check your connection and try again.',
                      authMessage:
                          'Session expired. Sign in again to continue.',
                    )
                  : e.toString(),
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ),
        data: (rows) {
          final pending = _hasPending(rows);
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              Text(
                'Request access as a tailor or a delivery partner. Our team will review your request.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (pending) ...[
                Card(
                  color: AppColors.stone,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        const Icon(Icons.hourglass_top, color: AppColors.ember),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'You already have a pending request. We will notify you when it is reviewed.',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              Text('Previous requests', style: AppTextStyles.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              if (rows.isEmpty)
                Text('No requests yet.', style: AppTextStyles.bodySmall)
              else
                ...rows.map((r) {
                  final st = r['status']?.toString() ?? '';
                  final role = r['requested_role']?.toString() ??
                      r['requestedRole']?.toString() ??
                      '';
                  final created = r['created_at']?.toString() ?? '';
                  return ListTile(
                    dense: true,
                    title: Text('$role · $st'),
                    subtitle: Text(created, style: AppTextStyles.bodySmall),
                  );
                }),
              if (!pending) ...[
                const SizedBox(height: AppSpacing.xl),
                Text('New request', style: AppTextStyles.titleSmall),
                const SizedBox(height: AppSpacing.md),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'tailor',
                      label: Text('Tailor'),
                      icon: Icon(Icons.cut),
                    ),
                    ButtonSegment(
                      value: 'delivery',
                      label: Text('Delivery'),
                      icon: Icon(Icons.delivery_dining),
                    ),
                  ],
                  selected: {_requestedRole},
                  onSelectionChanged: (s) {
                    if (s.isNotEmpty) {
                      setState(() => _requestedRole = s.first);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _messageCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Message (optional)',
                    hintText: 'Short note about your experience or coverage area',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: _submitting
                      ? null
                      : () async {
                          setState(() => _submitting = true);
                          final repo = ref.read(roleRequestRepositoryProvider);
                          final result = await repo.createRequest(
                            requestedRole: _requestedRole,
                            message: _messageCtrl.text,
                          );
                          if (!context.mounted) return;
                          setState(() => _submitting = false);
                          result.fold(
                            (err) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    mapAppExceptionMessage(
                                      err,
                                      fallback: 'Request failed.',
                                      networkMessage: 'Network issue.',
                                      authMessage: 'Session issue.',
                                    ),
                                  ),
                                ),
                              );
                            },
                            (_) {
                              _messageCtrl.clear();
                              ref.invalidate(myRoleRequestsProvider);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Request submitted.'),
                                ),
                              );
                            },
                          );
                        },
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit request'),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'If your request is approved, sign out and back in so the app opens the correct home for your new role.',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
