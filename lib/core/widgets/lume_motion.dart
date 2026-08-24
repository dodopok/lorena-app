import 'dart:async';

import 'package:flutter/material.dart';

Duration lumeMotionDuration(BuildContext context, Duration duration) =>
    (MediaQuery.maybeOf(context)?.disableAnimations ?? false)
    ? Duration.zero
    : duration;

/// A small entrance motion that does not change the child's layout bounds.
///
/// The translation is applied during painting, so the surrounding content does
/// not jump while the animation runs. It also follows the platform's Reduce
/// Motion setting automatically.
class LumeReveal extends StatefulWidget {
  const LumeReveal({
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.beginOffset = const Offset(0, .025),
    super.key,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset beginOffset;

  @override
  State<LumeReveal> createState() => _LumeRevealState();
}

class _LumeRevealState extends State<LumeReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  late final Animation<Offset> _offset = Tween<Offset>(
    begin: widget.beginOffset,
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return widget.child;
    }
    return FadeTransition(
      key: const ValueKey('lume-reveal-fade'),
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

/// A page-level wrapper for state changes that can alter content height.
///
/// The top edge remains anchored while the rest expands or contracts over a
/// short interval. This prevents lists and cards below a changed state from
/// snapping to a new position.
class LumeAnimatedContent extends StatelessWidget {
  const LumeAnimatedContent({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) return child;
    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      child: child,
    );
  }
}

Widget lumePageTransition(Widget child, Animation<double> animation) {
  final curved = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  final offset = Tween<Offset>(
    begin: const Offset(.025, 0),
    end: Offset.zero,
  ).animate(curved);
  return FadeTransition(
    opacity: curved,
    child: SlideTransition(position: offset, child: child),
  );
}
