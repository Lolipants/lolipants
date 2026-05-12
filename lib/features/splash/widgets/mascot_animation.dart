import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/features/mascot/mascot_controller.dart';
import 'package:rive/rive.dart';

/// Hosts the Rive panda mascot shown on the splash screen.
///
/// The animation is driven by a state machine named `MascotState` with a
/// numeric input `state` where 0 = idle, 1 = celebrate, 2 = sad. When the
/// asset is missing or fails to load we fall back to a branded placeholder so
/// the splash still lays out correctly.
class MascotAnimation extends StatefulWidget {
  /// Creates the mascot animation at its default splash size.
  const MascotAnimation({
    super.key,
    this.width = 130,
    this.height = 160,
    this.initialState = MascotState.idle,
  });

  /// Target width in logical pixels.
  final double width;

  /// Target height in logical pixels.
  final double height;

  /// State to bootstrap the machine in. Splash should stay idle.
  final MascotState initialState;

  @override
  State<MascotAnimation> createState() => _MascotAnimationState();
}

class _MascotAnimationState extends State<MascotAnimation> {
  static const _assetPath = 'assets/animations/mascot.riv';

  SMINumber? _stateInput;
  bool _loadFailed = false;
  bool _loading = true;
  RiveFile? _riveFile;

  @override
  void initState() {
    super.initState();
    _loadRive();
  }

  Future<void> _loadRive() async {
    try {
      final file = await RiveFile.asset(_assetPath);
      if (!mounted) return;
      setState(() {
        _riveFile = file;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadFailed = true;
        _loading = false;
      });
    }
  }

  void _onInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(
      artboard,
      'MascotState',
    );
    if (controller == null) {
      setState(() => _loadFailed = true);
      return;
    }
    artboard.addController(controller);
    _stateInput = controller.findInput<double>('state') as SMINumber?;
    _stateInput?.value = widget.initialState.index.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadFailed) {
      return _fallback();
    }
    if (_loading || _riveFile == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.gold.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: RiveAnimation.direct(
        _riveFile!,
        fit: BoxFit.contain,
        onInit: _onInit,
        placeHolder: _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      width: widget.width,
      height: widget.height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.ember,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Icon(Icons.pets, color: AppColors.gold.withValues(alpha: 0.35)),
    );
  }
}
