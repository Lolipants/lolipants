import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';

/// Pulsing down arrow that hints the home tab scrolls for more content.
class HomeScrollHint extends StatefulWidget {
  const HomeScrollHint({super.key});

  @override
  State<HomeScrollHint> createState() => _HomeScrollHintState();
}

class _HomeScrollHintState extends State<HomeScrollHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final opacity = 0.3 + (t * 0.7);
        final offset = t * 8;
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, offset),
            child: child,
          ),
        );
      },
      child: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.gold,
        size: 34,
      ),
    );
  }
}
