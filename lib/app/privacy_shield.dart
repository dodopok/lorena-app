import 'package:flutter/material.dart';

import 'theme.dart';

/// Covers sensitive content while iOS captures the app switcher snapshot or
/// while the app is not visible. The biometric gateway can be attached later
/// without changing the presentation tree.
class AppPrivacyShield extends StatefulWidget {
  const AppPrivacyShield({required this.child, super.key});

  final Widget child;

  @override
  State<AppPrivacyShield> createState() => _AppPrivacyShieldState();
}

class _AppPrivacyShieldState extends State<AppPrivacyShield>
    with WidgetsBindingObserver {
  bool _covered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final shouldCover =
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached;
    if (shouldCover != _covered && mounted) {
      setState(() => _covered = shouldCover);
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.topLeft,
    fit: StackFit.expand,
    children: [
      widget.child,
      if (_covered)
        ColoredBox(
          color: LumeColors.background,
          child: Center(
            child: Semantics(
              label: 'Conteúdo protegido',
              child: Icon(
                Icons.wb_sunny_outlined,
                size: 48,
                color: LumeColors.brand,
              ),
            ),
          ),
        ),
    ],
  );
}
