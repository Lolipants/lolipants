import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/community/utils/community_navigation.dart';
import 'package:lolipants/features/editor/models/garment_design.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Consent dialog before publishing a design to the orderable showcase.
Future<bool?> showPublishShowcaseDialog(
  BuildContext context, {
  required GarmentDesign design,
  required int commissionPct,
  String? previewImageUrl,
}) {
  var accepted = false;
  return showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        backgroundColor: AppColors.stone,
        title: Text('Publish to Showcase', style: AppTextStyles.titleMedium),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (previewImageUrl != null && previewImageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Image.network(
                    previewImageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              if (previewImageUrl != null && previewImageUrl.isNotEmpty)
                const SizedBox(height: AppSpacing.md),
              Text(design.name, style: AppTextStyles.titleSmall),
              Text(design.garmentType, style: AppTextStyles.bodySmall),
              const SizedBox(height: AppSpacing.md),
              Text(
                'You earn $commissionPct% when others order this design from Showcase.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: accepted,
                onChanged: (v) => setState(() => accepted = v ?? false),
                title: Text(
                  'I accept the commission terms (v1)',
                  style: AppTextStyles.bodySmall,
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          LolipantsButton(
            label: 'Publish',
            onPressed: accepted ? () => Navigator.of(ctx).pop(true) : null,
          ),
        ],
      ),
    ),
  );
}

/// Snackbar + optional navigation after successful publish.
void showPublishSuccessSnackBar(
  BuildContext context, {
  required int commissionPct,
  required GoRouter router,
  required WidgetRef ref,
}) {
  // Capture router while [context] is still mounted; the snackbar action may
  // fire after the publishing screen has been popped.
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        'Published to Showcase — you earn $commissionPct% on orders. '
        'Find it under Community → Showcase or Feed.',
      ),
      action: SnackBarAction(
        label: 'Showcase',
        onPressed: () => openCommunityHubTab(
          ref,
          router,
          tabIndex: kCommunityShowcaseTab,
        ),
      ),
    ),
  );
}
