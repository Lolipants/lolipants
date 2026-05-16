import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/features/editor/widgets/editor_resize_handle.dart';

typedef EditorResizeDragCallback = void Function(
  EditorResizeHandle handle,
  Offset delta,
);

/// Selection frame with 8 resize anchors; drag inside the frame to move.
class EditorLayerResizeWrapper extends StatefulWidget {
  const EditorLayerResizeWrapper({
    required this.child,
    required this.selected,
    this.contentSize,
    this.onMove,
    this.onResize,
    this.onTap,
    super.key,
  });

  final Widget child;
  final bool selected;

  /// When set (e.g. fixed print dimensions), skips layout measure for the frame.
  final Size? contentSize;

  final VoidCallback? onTap;
  final ValueChanged<Offset>? onMove;
  final EditorResizeDragCallback? onResize;

  static const double handleVisualSize = 12;
  static const double handleHitSize = 28;
  static const double _borderWidth = 2;

  @override
  State<EditorLayerResizeWrapper> createState() =>
      _EditorLayerResizeWrapperState();
}

class _EditorLayerResizeWrapperState extends State<EditorLayerResizeWrapper> {
  final GlobalKey _contentKey = GlobalKey();
  Size? _measuredSize;
  bool _resizing = false;

  Size? get _frameSize => widget.contentSize ?? _measuredSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_measureContent);
  }

  @override
  void didUpdateWidget(EditorLayerResizeWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.contentSize != oldWidget.contentSize) {
      setState(() {});
    }
    WidgetsBinding.instance.addPostFrameCallback(_measureContent);
  }

  void _measureContent(_) {
    if (!mounted || widget.contentSize != null) return;
    final box = _contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final next = box.size;
    if (_measuredSize != next) {
      setState(() => _measuredSize = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = EditorLayerResizeWrapper.handleHitSize / 2;
    final frame = _frameSize;

    return Padding(
      padding: EdgeInsets.all(pad),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          KeyedSubtree(
            key: _contentKey,
            child: widget.child,
          ),
          if (frame != null && widget.onTap != null && !widget.selected)
            Positioned(
              left: 0,
              top: 0,
              width: frame.width,
              height: frame.height,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: widget.onTap,
              ),
            ),
          if (frame != null &&
              widget.selected &&
              widget.onMove != null &&
              !_resizing)
            Positioned(
              left: 0,
              top: 0,
              width: frame.width,
              height: frame.height,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onTap,
                onPanUpdate: (details) => widget.onMove!(details.delta),
              ),
            ),
          if (widget.selected && frame != null) ...[
            Positioned(
              left: 0,
              top: 0,
              width: frame.width,
              height: frame.height,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.goldLight,
                      width: EditorLayerResizeWrapper._borderWidth,
                    ),
                  ),
                ),
              ),
            ),
            if (widget.onResize != null) ..._buildHandles(frame),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildHandles(Size size) {
    const hit = EditorLayerResizeWrapper.handleHitSize;
    const visual = EditorLayerResizeWrapper.handleVisualSize;
    final hitHalf = hit / 2;
    final visualHalf = visual / 2;
    final w = size.width;
    final height = size.height;

    Offset anchor(EditorResizeHandle handle) {
      final center = switch (handle) {
        EditorResizeHandle.topLeft => Offset(0, 0),
        EditorResizeHandle.topCenter => Offset(w / 2, 0),
        EditorResizeHandle.topRight => Offset(w, 0),
        EditorResizeHandle.centerLeft => Offset(0, height / 2),
        EditorResizeHandle.centerRight => Offset(w, height / 2),
        EditorResizeHandle.bottomLeft => Offset(0, height),
        EditorResizeHandle.bottomCenter => Offset(w / 2, height),
        EditorResizeHandle.bottomRight => Offset(w, height),
      };
      return Offset(center.dx - hitHalf, center.dy - hitHalf);
    }

    return EditorResizeHandle.values.map((handle) {
      final pos = anchor(handle);
      return Positioned(
        left: pos.dx,
        top: pos.dy,
        child: _ResizeHandle(
          handle: handle,
          onDragStart: () => setState(() => _resizing = true),
          onDragEnd: () => setState(() => _resizing = false),
          onDrag: (delta) => widget.onResize!(handle, delta),
          visualHalf: visualHalf,
        ),
      );
    }).toList();
  }
}

class _ResizeHandle extends StatefulWidget {
  const _ResizeHandle({
    required this.handle,
    required this.onDrag,
    required this.onDragStart,
    required this.onDragEnd,
    required this.visualHalf,
  });

  final EditorResizeHandle handle;
  final ValueChanged<Offset> onDrag;
  final VoidCallback onDragStart;
  final VoidCallback onDragEnd;
  final double visualHalf;

  @override
  State<_ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<_ResizeHandle> {
  int? _activePointer;

  @override
  Widget build(BuildContext context) {
    final hit = EditorLayerResizeWrapper.handleHitSize;

    return MouseRegion(
      cursor: editorResizeCursor(widget.handle),
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) {
          widget.onDragStart();
          setState(() => _activePointer = event.pointer);
        },
        onPointerMove: (event) {
          if (_activePointer != event.pointer) return;
          if (event.delta != Offset.zero) {
            widget.onDrag(event.delta);
          }
        },
        onPointerUp: (event) {
          if (_activePointer != event.pointer) return;
          setState(() => _activePointer = null);
          widget.onDragEnd();
        },
        onPointerCancel: (event) {
          if (_activePointer != event.pointer) return;
          setState(() => _activePointer = null);
          widget.onDragEnd();
        },
        child: SizedBox(
          width: hit,
          height: hit,
          child: Center(
            child: Container(
              width: widget.visualHalf * 2,
              height: widget.visualHalf * 2,
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.35),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
