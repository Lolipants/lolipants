import 'package:flutter/material.dart';

/// Anchor on the selection bounding box (8-point transform).
enum EditorResizeHandle {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

/// Signed scale delta from a handle drag (uniform scale).
double editorResizeScaleDelta(EditorResizeHandle handle, Offset delta) {
  return switch (handle) {
    EditorResizeHandle.topLeft => (-delta.dx - delta.dy) * 0.14,
    EditorResizeHandle.topCenter => -delta.dy * 0.14,
    EditorResizeHandle.topRight => (delta.dx - delta.dy) * 0.14,
    EditorResizeHandle.centerLeft => -delta.dx * 0.14,
    EditorResizeHandle.centerRight => delta.dx * 0.14,
    EditorResizeHandle.bottomLeft => (-delta.dx + delta.dy) * 0.14,
    EditorResizeHandle.bottomCenter => delta.dy * 0.14,
    EditorResizeHandle.bottomRight => (delta.dx + delta.dy) * 0.14,
  };
}

/// Signed font-size delta from a handle drag.
double editorResizeFontDelta(EditorResizeHandle handle, Offset delta) {
  return switch (handle) {
    EditorResizeHandle.topLeft => (-delta.dx - delta.dy) * 0.1,
    EditorResizeHandle.topCenter => -delta.dy * 0.1,
    EditorResizeHandle.topRight => (delta.dx - delta.dy) * 0.1,
    EditorResizeHandle.centerLeft => -delta.dx * 0.1,
    EditorResizeHandle.centerRight => delta.dx * 0.1,
    EditorResizeHandle.bottomLeft => (-delta.dx + delta.dy) * 0.1,
    EditorResizeHandle.bottomCenter => delta.dy * 0.1,
    EditorResizeHandle.bottomRight => (delta.dx + delta.dy) * 0.1,
  };
}

/// Desktop cursor for each handle.
MouseCursor editorResizeCursor(EditorResizeHandle handle) {
  return switch (handle) {
    EditorResizeHandle.topLeft || EditorResizeHandle.bottomRight =>
      SystemMouseCursors.resizeUpLeftDownRight,
    EditorResizeHandle.topRight || EditorResizeHandle.bottomLeft =>
      SystemMouseCursors.resizeUpRightDownLeft,
    EditorResizeHandle.topCenter || EditorResizeHandle.bottomCenter =>
      SystemMouseCursors.resizeUpDown,
    EditorResizeHandle.centerLeft || EditorResizeHandle.centerRight =>
      SystemMouseCursors.resizeLeftRight,
  };
}
