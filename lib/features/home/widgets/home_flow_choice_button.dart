import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';

/// Large frosted choice button for the home design wizard.
class HomeFlowChoiceButton extends StatelessWidget {
  const HomeFlowChoiceButton({
    required this.label,
    required this.onTap,
    required this.buttonWidth,
    this.icon,
    this.subtitle,
    this.isAr = false,
    super.key,
  });

  final IconData? icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final double buttonWidth;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final textDir = isAr ? TextDirection.rtl : TextDirection.ltr;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: buttonWidth,
              constraints: const BoxConstraints(minHeight: 68),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.14),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.38),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 22, color: AppColors.gold),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          style: (isAr
                                  ? AppTextStyles.arabicBody
                                  : AppTextStyles.titleSmall)
                              .copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.sand,
                          ),
                          textAlign: TextAlign.center,
                          textDirection: textDir,
                        ),
                      ),
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: (isAr
                              ? AppTextStyles.arabicBody
                              : AppTextStyles.bodySmall)
                          .copyWith(color: AppColors.fog, fontSize: 12),
                      textAlign: TextAlign.center,
                      textDirection: textDir,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
