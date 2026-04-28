import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';

/// Circular user avatar with initial fallback and optional pro-tick.
class UserAvatar extends StatelessWidget {
  /// Creates an avatar.
  const UserAvatar({
    required this.name,
    this.avatarUrl,
    this.isProDesigner = false,
    this.radius = 18,
    super.key,
  });

  /// Display name (used for initial fallback + semantics).
  final String name;

  /// Optional avatar URL.
  final String? avatarUrl;

  /// Whether to render a gold check-mark.
  final bool isProDesigner;

  /// Avatar radius.
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    final hasImage = (avatarUrl ?? '').isNotEmpty;
    return SizedBox(
      width: radius * 2 + 4,
      height: radius * 2 + 4,
      child: Stack(
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: AppColors.smoke,
            backgroundImage: hasImage ? NetworkImage(avatarUrl!) : null,
            child: hasImage
                ? null
                : Text(
                    initial,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.gold,
                    ),
                  ),
          ),
          if (isProDesigner)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.ink,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified,
                  color: AppColors.gold,
                  size: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
