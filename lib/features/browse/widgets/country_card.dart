import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';

/// Browse grid tile for a Gulf country.
class CountryCard extends StatelessWidget {
  /// Qatar preset.
  const CountryCard.qatar({super.key})
      : name = AppStrings.countryQatar,
        code = AppStrings.countryCodeQa,
        garments = AppStrings.countryGarmentsQa,
        bg = const Color(0xFF130D1F);

  /// Saudi Arabia preset.
  const CountryCard.saudi({super.key})
      : name = AppStrings.countrySaudi,
        code = AppStrings.countryCodeSa,
        garments = AppStrings.countryGarmentsSa,
        bg = const Color(0xFF0C180F);

  /// UAE preset.
  const CountryCard.uae({super.key})
      : name = AppStrings.countryUae,
        code = AppStrings.countryCodeAe,
        garments = AppStrings.countryGarmentsAe,
        bg = const Color(0xFF181200);

  /// Oman preset.
  const CountryCard.oman({super.key})
      : name = AppStrings.countryOman,
        code = AppStrings.countryCodeOm,
        garments = AppStrings.countryGarmentsOm,
        bg = const Color(0xFF001610);

  /// Display name.
  final String name;

  /// Short country code badge.
  final String code;

  /// Garment keywords line.
  final String garments;

  /// Header colour behind the arch motif.
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.comingPhase3)),
          );
        },
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.stone,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 54,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.md),
                      ),
                      child: ColoredBox(
                        color: bg,
                        child: const Center(
                          child: _ArchPainterWidget(),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.borderSubtle,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          code,
                          style: AppTextStyles.labelGold.copyWith(fontSize: 6.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.titleSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      garments,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArchPainterWidget extends StatelessWidget {
  const _ArchPainterWidget();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ArchPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _ArchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.15, h * 0.85)
      ..quadraticBezierTo(w * 0.5, h * 0.15, w * 0.85, h * 0.85);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
