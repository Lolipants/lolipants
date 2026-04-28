import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/admin/providers/admin_providers.dart';

/// Content moderation dashboard. Admins paste the offending id (post,
/// design, or commission) and the screen calls the scope-gated endpoints.
class AdminModerationScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const AdminModerationScreen({super.key});

  @override
  ConsumerState<AdminModerationScreen> createState() =>
      _AdminModerationScreenState();
}

class _AdminModerationScreenState extends ConsumerState<AdminModerationScreen> {
  final _postCtrl = TextEditingController();
  final _designCtrl = TextEditingController();
  final _commissionCtrl = TextEditingController();

  @override
  void dispose() {
    _postCtrl.dispose();
    _designCtrl.dispose();
    _commissionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('Moderation', style: AppTextStyles.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Hide community posts/showcase designs or void commissions. Paste '
          'the offending id and confirm.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        _Action(
          title: 'Hide community post',
          controller: _postCtrl,
          hint: 'post id',
          buttonLabel: 'Hide post',
          onSubmit: (id) async {
            final res =
                await ref.read(adminRepositoryProvider).hidePost(id);
            res.fold(
              (err) => _snack('Failed: ${err.runtimeType}'),
              (_) => _snack('Post hidden'),
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        _Action(
          title: 'Unlist design from showcase',
          controller: _designCtrl,
          hint: 'design id',
          buttonLabel: 'Unlist design',
          onSubmit: (id) async {
            final res =
                await ref.read(adminRepositoryProvider).hideDesign(id);
            res.fold(
              (err) => _snack('Failed: ${err.runtimeType}'),
              (_) => _snack('Design unlisted'),
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        _Action(
          title: 'Void commission',
          controller: _commissionCtrl,
          hint: 'commission id',
          buttonLabel: 'Void commission',
          onSubmit: (id) async {
            final res = await ref
                .read(adminRepositoryProvider)
                .voidCommission(id);
            res.fold(
              (err) => _snack('Failed: ${err.runtimeType}'),
              (_) => _snack('Commission voided'),
            );
          },
        ),
      ],
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.title,
    required this.controller,
    required this.hint,
    required this.buttonLabel,
    required this.onSubmit,
  });

  final String title;
  final TextEditingController controller;
  final String hint;
  final String buttonLabel;
  final Future<void> Function(String id) onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(hintText: hint),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            FilledButton(
              onPressed: () async {
                final id = controller.text.trim();
                if (id.isEmpty) return;
                await onSubmit(id);
                controller.clear();
              },
              child: Text(buttonLabel),
            ),
          ],
        ),
      ],
    );
  }
}
