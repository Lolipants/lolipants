import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/features/editor/data/render_preview_repository.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/editor/providers/designs_providers.dart';
import 'package:lolipants/features/orders/models/order_design_draft.dart';
import 'package:lolipants/features/editor/widgets/mannequin_viewer.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Deterministic template preview with editor fallback.
class DesignPreview360Screen extends ConsumerStatefulWidget {
  const DesignPreview360Screen({super.key});

  @override
  ConsumerState<DesignPreview360Screen> createState() =>
      _DesignPreview360ScreenState();
}

class _DesignPreview360ScreenState extends ConsumerState<DesignPreview360Screen>
    with SingleTickerProviderStateMixin {
  bool _ordering = false;
  String? _jobId;
  RenderPreviewJob? _renderJob;
  bool _isStartingRender = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startRender();
    });
  }

  @override
  Widget build(BuildContext context) {
    final editor = ref.watch(editorProvider);
    final heroFront = _renderJob?.artifacts['heroFrontUrl'];
    final heroSide = _renderJob?.artifacts['heroSideUrl'];
    final heroBack = _renderJob?.artifacts['heroBackUrl'];
    final isReady = _renderJob?.status == 'completed' &&
        heroFront != null &&
        heroFront.trim().isNotEmpty;
    final front = heroFront?.trim().isNotEmpty == true ? heroFront! : '';
    final side =
        heroSide?.trim().isNotEmpty == true ? heroSide! : front;
    final back =
        heroBack?.trim().isNotEmpty == true ? heroBack! : front;
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(title: const Text('Final Render Preview')),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          Column(
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        if (_isStartingRender || _renderJob == null || _renderJob?.status != 'completed')
                          LinearProgressIndicator(
                            value: _renderJob?.progress,
                            minHeight: 6,
                          ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _statusLabel(_renderJob),
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (isReady) ...[
                          Expanded(
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _renderCard('Front', front),
                                const SizedBox(width: AppSpacing.md),
                                _renderCard('Side', side),
                                const SizedBox(width: AppSpacing.md),
                                _renderCard('Back', back),
                              ],
                            ),
                          ),
                        ] else ...[
                          Expanded(
                            child: SizedBox(
                              width: 260,
                              child: MannequinViewer(
                                garmentType: editor.garmentType,
                                primaryColour: editor.primaryColour,
                                accentColour: editor.accentColour,
                                fabricProfile: editor.fabricQuality,
                                textLayers: editor.textLayers,
                                selectedTextLayerId: editor.selectedTextLayerId,
                                printImagePath: editor.printImagePath,
                                printPlacement: editor.printPlacement,
                                printScale: editor.printScale,
                              ),
                            ),
                          ),
                        ],
                      ],
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
                        label: _ordering ? 'Saving...' : 'Order with best preview',
                        onPressed: _ordering ? null : () => _orderFromPreview(),
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

  Widget _renderCard(String title, String url) {
    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(url, fit: BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(RenderPreviewJob? job) {
    if (job == null) return 'Preparing template preview...';
    if (job.status == 'failed') {
      return '${job.error ?? 'Preview failed'}. Showing editor fallback.';
    }
    if (job.status == 'completed') {
      return 'Template preview ready';
    }
    return 'Rendering template preview...';
  }

  String _toHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  Future<void> _orderFromPreview() async {
    final notifier = ref.read(editorProvider.notifier);
    var name = ref.read(editorProvider).designName.trim();
    if (name.isEmpty) {
      final controller = TextEditingController();
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.stone,
          title: const Text('Design name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      if (result == null || result.trim().isEmpty) return;
      name = result.trim();
    }

    setState(() => _ordering = true);
    final saved = await notifier.saveDesign(forceName: name);
    if (!mounted) return;
    setState(() => _ordering = false);
    if (!saved.success || saved.designId == null || saved.designId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(saved.message ?? 'Could not prepare this design for order.'),
        ),
      );
      return;
    }

    final repo = ref.read(renderPreviewRepositoryProvider);
    final start = await repo.startRender(designId: saved.designId!);
    await start.fold((_) async {}, (job) async {
      _jobId = job.jobId;
      _renderJob = job;
      await _pollJob();
    });

    final editor = ref.read(editorProvider);
    final bestPreview = _renderJob?.artifacts['heroFrontUrl'] ??
        _renderJob?.artifacts['fallbackPreviewUrl'];
    context.push(
      '/order/summary',
      extra: OrderDesignDraft(
        designId: saved.designId,
        name: editor.designName.trim().isEmpty ? 'Current design' : editor.designName,
        garmentType: editor.garmentType,
        primaryColour: _toHex(editor.primaryColour),
        accentColour: _toHex(editor.accentColour),
        fabricId: editor.selectedFabricId,
        patternId: editor.selectedPatternId,
        mannequinId: editor.mannequinId,
        previewImageUrl: bestPreview ?? ref.read(editorProvider).printImagePath,
      ),
    );
  }

  Future<void> _startRender() async {
    final editor = ref.read(editorProvider);
    if (editor.designName.trim().isEmpty) return;
    final notifier = ref.read(editorProvider.notifier);
    setState(() => _isStartingRender = true);
    final saved = await notifier.saveDesign(forceName: editor.designName.trim());
    if (!mounted) return;
    if (!saved.success || saved.designId == null) {
      setState(() => _isStartingRender = false);
      return;
    }
    final repo = ref.read(renderPreviewRepositoryProvider);
    final started = await repo.startRender(designId: saved.designId!);
    if (!mounted) return;
    started.fold(
      (_) => setState(() => _isStartingRender = false),
      (job) async {
        setState(() {
          _jobId = job.jobId;
          _renderJob = job;
          _isStartingRender = false;
        });
        await _pollJob();
      },
    );
  }

  Future<void> _pollJob() async {
    final jobId = _jobId;
    if (jobId == null || jobId.isEmpty) return;
    final repo = ref.read(renderPreviewRepositoryProvider);
    for (var i = 0; i < 18; i++) {
      if (!mounted) return;
      await Future<void>.delayed(const Duration(seconds: 2));
      final result = await repo.getRenderStatus(jobId: jobId);
      if (!mounted) return;
      result.fold((_) {}, (job) {
        setState(() => _renderJob = job);
      });
      final status = _renderJob?.status;
      if (status == 'completed' || status == 'failed') return;
    }
  }
}
