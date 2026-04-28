import 'package:flutter/material.dart';

/// Text overlay placed onto a [GarmentDesign] at normalised coordinates.
///
/// Phase 3 spec model. `placement` is in 0.0-1.0 relative to the mannequin's
/// visual bounds so it survives viewer resize.
@immutable
class DesignTextLayer {
  /// Creates a text layer.
  const DesignTextLayer({
    required this.id,
    required this.text,
    required this.fontFamily,
    required this.fontSize,
    required this.colour,
    required this.placement,
    this.rotation = 0,
  });

  /// Stable identifier.
  final String id;

  /// Rendered string.
  final String text;

  /// Font family name (Poppins, Noto Naskh Arabic, etc.).
  final String fontFamily;

  /// Logical pixels.
  final double fontSize;

  /// Rendered colour.
  final Color colour;

  /// Normalised position in 0-1 range.
  final Offset placement;

  /// Rotation in radians.
  final double rotation;

  /// Returns a copy with the provided fields overridden.
  DesignTextLayer copyWith({
    String? text,
    String? fontFamily,
    double? fontSize,
    Color? colour,
    Offset? placement,
    double? rotation,
  }) {
    return DesignTextLayer(
      id: id,
      text: text ?? this.text,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      colour: colour ?? this.colour,
      placement: placement ?? this.placement,
      rotation: rotation ?? this.rotation,
    );
  }
}
