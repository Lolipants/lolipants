import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/admin_strings.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
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
        Text(
          localized(ref, AdminStrings.moderationTitle, AdminStrings.moderationTitleAr),
          style: AppTextStyles.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          localized(ref, AdminStrings.moderationBody, AdminStrings.moderationBodyAr),
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        _Action(
          titleEn: AdminStrings.hideCommunityPost,
          titleAr: AdminStrings.hideCommunityPostAr,
          controller: _postCtrl,
          hintEn: AdminStrings.postId,
          hintAr: AdminStrings.postIdAr,
          buttonLabelEn: AdminStrings.hidePost,
          buttonLabelAr: AdminStrings.hidePostAr,
          onSubmit: (id) async {
            final res =
                await ref.read(adminRepositoryProvider).hidePost(id);
            res.fold(
              (err) => _snack(
                '${localized(ref, AdminStrings.failedPrefix, AdminStrings.failedPrefixAr)} ${err.runtimeType}',
              ),
              (_) => _snack(
                localized(ref, AdminStrings.postHidden, AdminStrings.postHiddenAr),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        _Action(
          titleEn: AdminStrings.unlistDesign,
          titleAr: AdminStrings.unlistDesignAr,
          controller: _designCtrl,
          hintEn: AdminStrings.designId,
          hintAr: AdminStrings.designIdAr,
          buttonLabelEn: AdminStrings.unlistDesignAction,
          buttonLabelAr: AdminStrings.unlistDesignActionAr,
          onSubmit: (id) async {
            final res =
                await ref.read(adminRepositoryProvider).hideDesign(id);
            res.fold(
              (err) => _snack(
                '${localized(ref, AdminStrings.failedPrefix, AdminStrings.failedPrefixAr)} ${err.runtimeType}',
              ),
              (_) => _snack(
                localized(
                  ref,
                  AdminStrings.designUnlisted,
                  AdminStrings.designUnlistedAr,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        _Action(
          titleEn: AdminStrings.voidCommission,
          titleAr: AdminStrings.voidCommissionAr,
          controller: _commissionCtrl,
          hintEn: AdminStrings.commissionId,
          hintAr: AdminStrings.commissionIdAr,
          buttonLabelEn: AdminStrings.voidCommissionAction,
          buttonLabelAr: AdminStrings.voidCommissionActionAr,
          onSubmit: (id) async {
            final res = await ref
                .read(adminRepositoryProvider)
                .voidCommission(id);
            res.fold(
              (err) => _snack(
                '${localized(ref, AdminStrings.failedPrefix, AdminStrings.failedPrefixAr)} ${err.runtimeType}',
              ),
              (_) => _snack(
                localized(
                  ref,
                  AdminStrings.commissionVoided,
                  AdminStrings.commissionVoidedAr,
                ),
              ),
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

class _Action extends ConsumerWidget {
  const _Action({
    required this.titleEn,
    required this.titleAr,
    required this.controller,
    required this.hintEn,
    required this.hintAr,
    required this.buttonLabelEn,
    required this.buttonLabelAr,
    required this.onSubmit,
  });

  final String titleEn;
  final String titleAr;
  final TextEditingController controller;
  final String hintEn;
  final String hintAr;
  final String buttonLabelEn;
  final String buttonLabelAr;
  final Future<void> Function(String id) onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localized(ref, titleEn, titleAr),
          style: AppTextStyles.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: localized(ref, hintEn, hintAr),
                ),
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
              child: Text(localized(ref, buttonLabelEn, buttonLabelAr)),
            ),
          ],
        ),
      ],
    );
  }
}
