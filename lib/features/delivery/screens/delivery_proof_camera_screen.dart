import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/constants/delivery_strings.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/core/permissions/device_permission_prompt.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// In-app delivery proof capture. Stays inside the Flutter activity so Android
/// does not tear down [MainActivity] like the external camera intent does.
class DeliveryProofCameraScreen extends ConsumerStatefulWidget {
  const DeliveryProofCameraScreen({super.key});

  @override
  ConsumerState<DeliveryProofCameraScreen> createState() =>
      _DeliveryProofCameraScreenState();
}

class _DeliveryProofCameraScreenState
    extends ConsumerState<DeliveryProofCameraScreen> {
  CameraController? _controller;
  bool _ready = false;
  bool _capturing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootCamera());
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Locale get _locale => ref.read(settingsLocaleProvider);

  Future<void> _bootCamera() async {
    final granted = await DevicePermissionPrompt.ensure(
      context,
      AppDevicePermission.camera,
    );
    if (!granted) {
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() => _error = localizedFromLocale(
              _locale,
              DeliveryStrings.noCameraFound,
              DeliveryStrings.noCameraFoundAr,
            ));
        return;
      }
      final selected = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _ready = true;
        _error = null;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _error = DeliveryStrings.couldNotStartCamera(
            e.runtimeType.toString(),
            _locale,
          ));
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (!_ready || controller == null || _capturing) return;
    setState(() {
      _capturing = true;
      _error = null;
    });
    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.isEmpty) {
        setState(() {
          _capturing = false;
          _error = localizedFromLocale(
            _locale,
            DeliveryStrings.photoEmptyRetry,
            DeliveryStrings.photoEmptyRetryAr,
          );
        });
        return;
      }
      Navigator.of(context).pop(Uint8List.fromList(bytes));
    } on Object {
      if (!mounted) return;
      setState(() {
        _capturing = false;
        _error = localizedFromLocale(
          _locale,
          DeliveryStrings.couldNotTakePhoto,
          DeliveryStrings.couldNotTakePhotoAr,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(settingsLocaleProvider);
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        title: Text(
          localizedFromLocale(
            locale,
            DeliveryStrings.proofPhotoTitle,
            DeliveryStrings.proofPhotoTitleAr,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _capturing ? null : () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: ColoredBox(
                  color: AppColors.stone,
                  child: _buildPreview(locale),
                ),
              ),
            ),
          ),
          if (_error != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.rubyLight),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.sm,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: LolipantsButton(
              label: _capturing
                  ? localizedFromLocale(
                      locale,
                      DeliveryStrings.capturing,
                      DeliveryStrings.capturingAr,
                    )
                  : localizedFromLocale(
                      locale,
                      DeliveryStrings.takePhoto,
                      DeliveryStrings.takePhotoAr,
                    ),
              loading: _capturing,
              onPressed: _ready && !_capturing ? _capture : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(Locale locale) {
    if (_error != null && !_ready) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
        ),
      );
    }
    final controller = _controller;
    if (!_ready || controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(controller),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            color: Colors.black54,
            child: Text(
              localizedFromLocale(
                locale,
                DeliveryStrings.photographParcelHint,
                DeliveryStrings.photographParcelHintAr,
              ),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.sand),
            ),
          ),
        ),
      ],
    );
  }
}
