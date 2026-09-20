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

/// Keeps a destination mounted while replaying only its entrance on selection.
class LumeTabStage extends StatefulWidget {
  const LumeTabStage({required this.active, required this.child, super.key});
  final bool active;
  final Widget child;

  @override
  State<LumeTabStage> createState() => _LumeTabStageState();
}

class _LumeTabStageState extends State<LumeTabStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1,
  );

  @override
  void didUpdateWidget(LumeTabStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return FadeTransition(
      opacity: _controller.drive(CurveTween(curve: Curves.easeOutCubic)),
      child: widget.child,
    );
  }
}

/// Paint-only feedback; InkWell remains responsible for taps and semantics.
class LumePressScale extends StatefulWidget {
  const LumePressScale({required this.child, this.enabled = true, super.key});
  final Widget child;
  final bool enabled;

  @override
  State<LumePressScale> createState() => _LumePressScaleState();
}

class _LumePressScaleState extends State<LumePressScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: widget.enabled ? (_) => _setPressed(true) : null,
    onPointerUp: (_) => _setPressed(false),
    onPointerCancel: (_) => _setPressed(false),
    child: AnimatedScale(
      scale:
          _pressed && widget.enabled && !MediaQuery.disableAnimationsOf(context)
          ? .975
          : 1,
      duration: lumeMotionDuration(context, const Duration(milliseconds: 140)),
      curve: Curves.easeOutCubic,
      child: widget.child,
    ),
  );
}

/// A short, bounded entrance sequence for the daily overview.
class LumeStaggeredColumn extends StatelessWidget {
  const LumeStaggeredColumn({required this.children, super.key});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var index = 0; index < children.length; index++)
        if (children[index] is SizedBox)
          children[index]
        else
          LumeReveal(
            delay: Duration(milliseconds: (index * 30).clamp(0, 210)),
            duration: const Duration(milliseconds: 300),
            child: children[index],
          ),
    ],
  );
}
