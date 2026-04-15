import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/sizing/providers/sizing_providers.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';

/// Entry screen for choosing sizing method.
class SizingMethodScreen extends ConsumerWidget {
  /// Creates sizing method chooser.
  const SizingMethodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final measurementState = ref.watch(myMeasurementsProvider);
    final hasSaved = measurementState.valueOrNull != null;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.sizingOptions)),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              Text(
                AppStrings.sizingQuestion,
                style: AppTextStyles.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xl),
              _SizingMethodCard(
                icon: Icons.camera_alt_outlined,
                title: AppStrings.sizingAiOption,
                subtitle: AppStrings.sizingAiSubtitle,
                onTap: () => context.push('/sizing/ai'),
              ),
              const SizedBox(height: AppSpacing.md),
              _SizingMethodCard(
                icon: Icons.straighten,
                title: AppStrings.sizingManualOption,
                subtitle: AppStrings.sizingManualSubtitle,
                onTap: () => context.push('/sizing/manual'),
              ),
              const SizedBox(height: AppSpacing.md),
              _SizingMethodCard(
                icon: Icons.storefront_outlined,
                title: AppStrings.sizingWorkshopOption,
                subtitle: AppStrings.sizingWorkshopSubtitle,
                onTap: () => context.push('/sizing/workshop'),
              ),
              if (hasSaved) ...[
                const SizedBox(height: AppSpacing.lg),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: Text(
                      AppStrings.sizingUseSaved,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SizingMethodCard extends StatelessWidget {
  const _SizingMethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.stone,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.gold),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(subtitle, style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.sand),
          ],
        ),
      ),
    );
  }
}
