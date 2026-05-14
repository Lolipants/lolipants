import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/auth/models/user.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';

/// Time-of-day greeting and signed-in user line for the home feed.
class HomeHeader extends ConsumerWidget {
  /// Creates the home header.
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hour = DateTime.now().hour;
    final (String en, String ar) = switch (hour) {
      >= 5 && < 12 => (AppStrings.goodMorning, AppStrings.goodMorningAr),
      >= 12 && < 17 => (AppStrings.goodAfternoon, AppStrings.goodAfternoonAr),
      _ => (AppStrings.goodEvening, AppStrings.goodEveningAr),
    };

    final auth = ref.watch(authProvider);
    final nameSuffix = auth.maybeWhen(
      data: (state) {
        if (state is! AuthAuthenticated) {
          return '';
        }
        final n = state.user.name.trim();
        if (n.isEmpty) {
          return '';
        }
        final first = n.split(RegExp(r'\s+')).first;
        return ', $first';
      },
      orElse: () => '',
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$en$nameSuffix',
                  style: AppTextStyles.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    '$ar$nameSuffix',
                    style: AppTextStyles.arabicBody.copyWith(
                      fontSize: 16,
                      color: AppColors.gold,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppStrings.tagline,
                  style: AppTextStyles.bodySmall,
                ),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    AppStrings.taglineAr,
                    style: AppTextStyles.arabicBody.copyWith(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          auth.maybeWhen(
            data: (state) {
              if (state is! AuthAuthenticated) {
                return const SizedBox.shrink();
              }
              final avatarImage = _safeAvatarImage(state.user);
              return CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.ember,
                backgroundImage: avatarImage,
                child: avatarImage == null
                    ? Text(
                        state.user.initials,
                        style: AppTextStyles.labelGold.copyWith(fontSize: 14),
                      )
                    : null,
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  static ImageProvider? _safeAvatarImage(User user) {
    final raw = user.imageUrl?.trim() ?? '';
    if (raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null) return null;
    if (!(uri.isScheme('http') || uri.isScheme('https'))) return null;
    if (uri.host.isEmpty) return null;
    return NetworkImage(raw);
  }
}
