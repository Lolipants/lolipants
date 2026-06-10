import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/features/editor/widgets/editor_design_panel.dart';

/// Unified bottom shell for the design editor panel.
class EditorBottomPanel extends ConsumerWidget {
  const EditorBottomPanel({
    required this.height,
    required this.onGenerateAi,
    super.key,
  });

  final double height;
  final Future<void> Function() onGenerateAi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.stone,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
          border: const Border(top: BorderSide(color: AppColors.borderStrong)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 6),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderDefault,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            Expanded(
              child: EditorDesignPanel(
                embedded: true,
                onGenerateAi: onGenerateAi,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
