import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/sizing/models/body_measurements.dart';
import 'package:lolipants/features/sizing/providers/sizing_providers.dart';
import 'package:lolipants/features/sizing/services/pose_quality_service.dart';
import 'package:lolipants/core/ai/ai_data_sharing_consent.dart';
import 'package:lolipants/core/permissions/device_permission_prompt.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';
import 'package:lolipants/core/l10n/app_localization.dart';

/// AI-assisted measurement flow (Phase 3 scaffold).
class AiMeasurementScreen extends ConsumerStatefulWidget {
  /// Creates AI measurement screen.
  const AiMeasurementScreen({super.key});

  @override
  ConsumerState<AiMeasurementScreen> createState() => _AiMeasurementScreenState();
}

class _AiMeasurementScreenState extends ConsumerState<AiMeasurementScreen> {
  int _step = 0;
  bool _isBusy = false;
  BodyMeasurements? _result;
  String? _error;
  CameraController? _cameraController;
  final _poseQualityService = PoseQualityService();
  bool _cameraReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initCamera());
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseQualityService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(pickSlashFromContext(context, AppStrings.aiMeasurementTitle))),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              if (_step == 0) ...[
                Text(
                  AppStrings.aiMeasurementInstructions,
                  style: AppTextStyles.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(AppStrings.aiMeasurementStep1),
                const Text(AppStrings.aiMeasurementStep2),
                const Text(AppStrings.aiMeasurementStep3),
                const Text(AppStrings.aiMeasurementStep4),
                const SizedBox(height: AppSpacing.lg),
                LolipantsButton(
                  label: AppStrings.aiMeasurementStartScan,
                  onPressed: () => setState(() => _step = 1),
                ),
              ] else if (_step == 1) ...[
                Text(
                  AppStrings.aiMeasurementCameraScan,
                  style: AppTextStyles.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                _CameraPreviewCard(
                  controller: _cameraController,
                  cameraReady: _cameraReady,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppStrings.aiMeasurementAlignHint,
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                if (_isBusy)
                  const _AnalysingIndicator()
                else
                  const SizedBox.shrink(),
                if (_isBusy) const SizedBox(height: AppSpacing.md),
                LolipantsButton(
                  label: AppStrings.aiMeasurementAnalyse,
                  loading: _isBusy,
                  onPressed: _analyseCapturedFrame,
                ),
              ] else ...[
                Text(
                  AppStrings.aiMeasurementEstimated,
                  style: AppTextStyles.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                _Row(label: AppStrings.measurementChest, value: _result?.chest),
                _Row(label: AppStrings.measurementWaist, value: _result?.waist),
                _Row(label: AppStrings.measurementHips, value: _result?.hips),
                _Row(
                  label: AppStrings.measurementShoulderWidth,
                  value: _result?.shoulderWidth,
                ),
                _Row(label: AppStrings.measurementHeight, value: _result?.height),
                _Row(
                  label: AppStrings.measurementArmLength,
                  value: _result?.armLength,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  AppStrings.aiMeasurementVerifyHint,
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                LolipantsButton(
                  label: AppStrings.aiMeasurementSave,
                  loading: _isBusy,
                  onPressed: _save,
                ),
                TextButton(
                  onPressed: () => context.push('/sizing/manual'),
                  child: Text(pickSlashFromContext(context, AppStrings.aiMeasurementManualFallback)),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _error!,
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.redAccent),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _initCamera() async {
    try {
      final granted = await DevicePermissionPrompt.ensure(
        context,
        AppDevicePermission.camera,
      );
      if (!granted) {
        if (!mounted) return;
        setState(() {
          _error = AppStrings.aiMeasurementCameraPermissionDenied;
        });
        return;
      }
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _error = AppStrings.aiMeasurementNoCamera;
        });
        return;
      }
      final selected = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _cameraController = controller;
        _cameraReady = true;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _error = AppStrings.aiMeasurementCameraInitFailed;
      });
    }
  }

  Future<void> _analyseCapturedFrame() async {
    final allowed = await AiDataSharingConsent.ensure(context, ref);
    if (!allowed || !mounted) return;

    final controller = _cameraController;
    if (!_cameraReady || controller == null) {
      setState(() {
        _error = AppStrings.aiMeasurementCameraNotReady;
      });
      return;
    }
    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      final captured = await controller.takePicture();
      final inputImage = InputImage.fromFilePath(captured.path);
      final quality = await _poseQualityService.validate(inputImage);
      if (!quality.isValid) {
        if (!mounted) return;
        setState(() {
          _isBusy = false;
          _error = quality.message;
        });
        return;
      }

      final bytes = await captured.readAsBytes();
      final imageBase64 = base64Encode(bytes);
      final repo = ref.read(sizingRepositoryProvider);
      final result = await repo.estimateFromImageBase64(imageBase64);
      if (!mounted) return;
      result.fold(
        (e) => setState(() {
          _isBusy = false;
          _error = sizingErrorMessage(
            e,
            fallback: AppStrings.aiMeasurementEstimateFailed,
          );
        }),
        (m) => setState(() {
          _isBusy = false;
          _result = _sanitizeMeasurements(m);
          _step = 2;
        }),
      );
    } on Exception {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _error = AppStrings.aiMeasurementCaptureFailed;
      });
    }
  }

  Future<void> _save() async {
    final data = _result;
    if (data == null) return;
    setState(() => _isBusy = true);
    await ref.read(myMeasurementsProvider.notifier).save(data);
    setState(() => _isBusy = false);
    if (!mounted) return;
    final state = ref.read(myMeasurementsProvider);
    if (state.hasError) {
      setState(() {
        _error = sizingErrorMessage(
          state.error!,
          fallback: AppStrings.aiMeasurementSaveFailed,
        );
      });
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          pickSlashFromContext(context, AppStrings.aiMeasurementSaved),
        ),
      ),
    );
    if (context.mounted) context.pop();
  }

  BodyMeasurements _sanitizeMeasurements(BodyMeasurements input) {
    double? clamp(double? value) {
      if (value == null) return null;
      if (value.isNaN || value.isInfinite) return null;
      if (value < 0 || value > 300) return null;
      return value;
    }

    return BodyMeasurements(
      chest: clamp(input.chest),
      waist: clamp(input.waist),
      hips: clamp(input.hips),
      shoulderWidth: clamp(input.shoulderWidth),
      height: clamp(input.height),
      armLength: clamp(input.armLength),
      preferredSize: input.preferredSize,
      savedAt: input.savedAt,
    );
  }
}

class _CameraPreviewCard extends StatelessWidget {
  const _CameraPreviewCard({
    required this.controller,
    required this.cameraReady,
  });

  final CameraController? controller;
  final bool cameraReady;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.white24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: !cameraReady || controller == null
            ? const CircularProgressIndicator()
            : Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(controller!),
                  IgnorePointer(
                    child: CustomPaint(
                      painter: _SilhouetteOverlayPainter(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SilhouetteOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.45);
    final outer = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final frameRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.56,
      height: size.height * 0.84,
    );
    final silhouette = Path()
      ..addRRect(RRect.fromRectAndRadius(frameRect, const Radius.circular(140)));
    final cutout = Path.combine(PathOperation.difference, outer, silhouette);
    canvas.drawPath(cutout, overlayPaint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white70;
    canvas.drawPath(silhouette, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AnalysingIndicator extends StatelessWidget {
  const _AnalysingIndicator();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.9, end: 1.15),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Transform.scale(scale: value, child: child);
          },
          onEnd: () {},
          child: const Icon(Icons.radar, color: Colors.white70, size: 32),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(AppStrings.aiMeasurementAnalysing, style: AppTextStyles.bodySmall),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final double? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          Text(
            value == null
                ? '-'
                : '${value!.toStringAsFixed(1)} ${AppStrings.measurementUnitCm}',
            style: AppTextStyles.titleSmall,
          ),
        ],
      ),
    );
  }
}
