import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/orders/models/order_design_draft.dart';
import 'package:lolipants/features/editor/widgets/mannequin_viewer.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Simple rotating mannequin preview for Phase 3B.
class DesignPreview360Screen extends ConsumerStatefulWidget {
  const DesignPreview360Screen({super.key});

  @override
  ConsumerState<DesignPreview360Screen> createState() =>
      _DesignPreview360ScreenState();
}

class _DesignPreview360ScreenState extends ConsumerState<DesignPreview360Screen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editor = ref.watch(editorProvider);
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(title: const Text('Preview 360°')),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          Column(
            children: [
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final angle = _controller.value * 6.28318530718;
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(angle),
                        child: child,
                      );
                    },
                    child: SizedBox(
                      width: 260,
                      height: 360,
                      child: MannequinViewer(
                        garmentType: editor.garmentType,
                        primaryColour: editor.primaryColour,
                        accentColour: editor.accentColour,
                        textLayers: editor.textLayers,
                        selectedTextLayerId: editor.selectedTextLayerId,
                        printImagePath: editor.printImagePath,
                        printPlacement: editor.printPlacement,
                        printScale: editor.printScale,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: LolipantsButton(
                        label: 'Back to editor',
                        variant: LolipantsButtonVariant.secondary,
                        onPressed: () => context.pop(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: LolipantsButton(
                        label: 'Order this design',
                        onPressed: () => context.push(
                          '/order/summary',
                          extra: OrderDesignDraft(
                            name: editor.designName.trim().isEmpty
                                ? 'Current design'
                                : editor.designName,
                            garmentType: editor.garmentType,
                            primaryColour: _toHex(editor.primaryColour),
                            accentColour: _toHex(editor.accentColour),
                            fabricId: editor.selectedFabricId,
                            patternId: editor.selectedPatternId,
                            mannequinId: editor.mannequinId,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _toHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }
}
