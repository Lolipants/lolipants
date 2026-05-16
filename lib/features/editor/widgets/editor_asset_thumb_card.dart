import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';

/// Small square thumb + caption below (Build slot picker).
class EditorCompactThumbCard extends StatelessWidget {
  const EditorCompactThumbCard({
    required this.image,
    required this.label,
    required this.selected,
    required this.onTap,
    this.imageScale = 1.32,
    super.key,
  });

  static const double thumbSize = 100;
  static const double stripHeight = thumbSize + 20;

  final Widget image;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  /// Zoom asset inside the square without changing [thumbSize].
  final double imageScale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: thumbSize,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Ink(
                width: thumbSize,
                height: thumbSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: selected ? AppColors.gold : AppColors.borderSubtle,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm - 1),
                  child: SizedBox.expand(
                    child: imageScale == 1
                        ? image
                        : Transform.scale(
                            scale: imageScale,
                            child: image,
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 9,
              height: 1.15,
              color: selected ? AppColors.gold : AppColors.fog,
            ),
          ),
        ],
      ),
    );
  }
}

/// White preview card used in Build and Designs pickers.
class EditorAssetThumbCard extends StatelessWidget {
  const EditorAssetThumbCard({
    required this.image,
    required this.label,
    required this.selected,
    required this.onTap,
    this.width = 96,
    this.height = 136,
    this.imageScale = 1.45,
    this.imageAlignment = Alignment.bottomCenter,
    super.key,
  });

  final Widget image;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double width;
  final double height;
  final double imageScale;
  final Alignment imageAlignment;

  @override
  Widget build(BuildContext context) {
    const labelMaxLines = 2;
    const labelStyle = TextStyle(
      fontSize: 9,
      height: 1.1,
    );

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: selected ? AppColors.gold : AppColors.borderSubtle,
                width: selected ? 2.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.md - 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(1),
                      child: imageScale == 1
                          ? Align(
                              alignment: imageAlignment,
                              child: image,
                            )
                          : ClipRect(
                              child: Align(
                                alignment: imageAlignment,
                                child: Transform.scale(
                                  scale: imageScale,
                                  child: image,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 4,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.stone,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(AppRadius.md - 1),
                    ),
                  ),
                  child: Text(
                    label,
                    maxLines: labelMaxLines,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: labelStyle.fontSize,
                      height: labelStyle.height,
                      color: selected ? AppColors.gold : AppColors.fog,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
