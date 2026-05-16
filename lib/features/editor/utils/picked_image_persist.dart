import 'dart:io';

import 'package:image_picker/image_picker.dart';

/// Copies a gallery pick into app temp storage so [File] and multipart upload work.
Future<String?> persistPickedImage(XFile file) async {
  try {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return null;
    final ext = _extensionFor(file.path);
    final dest = File(
      '${Directory.systemTemp.path}/lolipants_${DateTime.now().microsecondsSinceEpoch}$ext',
    );
    await dest.writeAsBytes(bytes, flush: true);
    return dest.path;
  } on Exception {
    return null;
  }
}

String _extensionFor(String path) {
  final dot = path.lastIndexOf('.');
  if (dot <= 0 || dot >= path.length - 1) return '.jpg';
  final ext = path.substring(dot).toLowerCase();
  if (ext == '.png' || ext == '.jpg' || ext == '.jpeg' || ext == '.webp') {
    return ext == '.jpeg' ? '.jpg' : ext;
  }
  return '.jpg';
}
