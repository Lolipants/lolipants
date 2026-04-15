import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Result of validating user framing for AI sizing.
class PoseQualityResult {
  /// Creates a pose quality result.
  const PoseQualityResult({
    required this.isValid,
    required this.message,
  });

  /// Whether pose includes key landmarks needed for sizing.
  final bool isValid;

  /// User-facing guidance message.
  final String message;
}

/// Uses ML Kit pose detection to verify framing quality.
///
/// This checks whether core landmarks are visible before uploading
/// the captured image for AI measurement estimation.
class PoseQualityService {
  final PoseDetector _detector = PoseDetector(
    options: PoseDetectorOptions(
      model: PoseDetectionModel.base,
    ),
  );

  /// Validates that one full-body pose is visible.
  Future<PoseQualityResult> validate(InputImage image) async {
    final poses = await _detector.processImage(image);
    if (poses.isEmpty) {
      return const PoseQualityResult(
        isValid: false,
        message: 'No person detected. Step back and keep full body in frame.',
      );
    }
    final pose = poses.first;
    final required = [
      PoseLandmarkType.nose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    ];
    final missing = required
        .where((type) => pose.landmarks[type] == null)
        .toList(growable: false);
    if (missing.isNotEmpty) {
      return const PoseQualityResult(
        isValid: false,
        message: 'Full body not visible. Stand farther and keep legs in frame.',
      );
    }
    return const PoseQualityResult(
      isValid: true,
      message: 'Pose looks good for estimation.',
    );
  }

  /// Releases native detector resources.
  Future<void> dispose() => _detector.close();
}
