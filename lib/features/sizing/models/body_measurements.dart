/// User body measurements captured by AI/manual/workshop flows.
class BodyMeasurements {
  /// Creates a measurement snapshot.
  const BodyMeasurements({
    this.chest,
    this.waist,
    this.hips,
    this.shoulderWidth,
    this.height,
    this.armLength,
    this.preferredSize,
    this.savedAt,
  });

  /// Parses API payload.
  factory BodyMeasurements.fromApi(Map<String, dynamic> json) {
    return BodyMeasurements(
      chest: _toDouble(json['chest']),
      waist: _toDouble(json['waist']),
      hips: _toDouble(json['hips']),
      shoulderWidth:
          _toDouble(json['shoulder_width']) ?? _toDouble(json['shoulderWidth']),
      height: _toDouble(json['height']),
      armLength: _toDouble(json['arm_length']) ?? _toDouble(json['armLength']),
      preferredSize:
          json['preferred_size']?.toString() ??
          json['preferredSize']?.toString(),
      savedAt: DateTime.tryParse(
        json['saved_at']?.toString() ?? json['savedAt']?.toString() ?? '',
      ),
    );
  }

  /// Converts to request payload.
  Map<String, dynamic> toApi() => {
        'chest': chest,
        'waist': waist,
        'hips': hips,
        'shoulderWidth': shoulderWidth,
        'height': height,
        'armLength': armLength,
        'preferredSize': preferredSize,
      };

  /// Chest in cm.
  final double? chest;

  /// Waist in cm.
  final double? waist;

  /// Hips in cm.
  final double? hips;

  /// Shoulder width in cm.
  final double? shoulderWidth;

  /// Height in cm.
  final double? height;

  /// Arm length in cm.
  final double? armLength;

  /// Optional ready-made size.
  final String? preferredSize;

  /// Last saved timestamp.
  final DateTime? savedAt;
}

double? _toDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
