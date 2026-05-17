import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Splash GIF asset path and warm-cache helpers.
abstract final class SplashAssets {
  /// Bundled panda splash animation.
  static const String gifPath = 'assets/animations/lolipants_splash.gif';

  static Uint8List? _bytes;
  static MemoryImage? _memoryImage;

  /// True after [warm] has finished successfully.
  static bool get isWarmed => _bytes != null;

  /// Loads GIF bytes into memory so the first splash frame avoids disk I/O.
  static Future<void> warm() async {
    if (_bytes != null) return;
    final data = await rootBundle.load(gifPath);
    _bytes = data.buffer.asUint8List();
    _memoryImage = MemoryImage(_bytes!);
    // Prime the GIF codec during bootstrap so the splash paints on first frame.
    final codec = await ui.instantiateImageCodec(_bytes!);
    final frame = await codec.getNextFrame();
    frame.image.dispose();
    codec.dispose();
  }

  /// Provider for the splash [Image]; uses memory when [warm] ran first.
  static ImageProvider get imageProvider =>
      _memoryImage ?? const AssetImage(gifPath);
}
