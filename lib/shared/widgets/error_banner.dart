import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';

/// Dismissible error strip with slide + fade entrance.
class ErrorBanner extends StatefulWidget {
  /// Creates a banner that auto-dismisses after [autoDismissDuration].
  const ErrorBanner({
    required this.message,
    required this.onDismiss,
    this.autoDismissDuration = const Duration(seconds: 5),
    super.key,
  });

  /// Message shown next to the warning icon.
  final String message;

  /// Called when the user taps close or auto-dismiss completes.
  final VoidCallback onDismiss;

  /// Delay before the banner removes itself.
  final Duration autoDismissDuration;

  @override
  State<ErrorBanner> createState() => _ErrorBannerState();
}

class _ErrorBannerState extends State<ErrorBanner> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.autoDismissDuration, widget.onDismiss);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.ruby,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.sand),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                widget.message,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 12,
                  color: AppColors.sand,
                ),
              ),
            ),
            IconButton(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onPressed: widget.onDismiss,
              icon: const Icon(Icons.close, color: AppColors.sand, size: 18),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 200.ms)
        .slideY(begin: 0.08, duration: 200.ms);
  }
}
