import 'package:flutter/material.dart';

import '../core/biometrics/biometric_gateway.dart';
import 'app_controller.dart';
import 'theme.dart';

/// Covers sensitive content while iOS captures the app switcher snapshot or
/// while the app is not visible. When the user enables the optional lock, the
/// same shield stays in front until local authentication succeeds.
class AppPrivacyShield extends StatefulWidget {
  const AppPrivacyShield({
    required this.child,
    required this.controller,
    this.biometricGateway,
    super.key,
  });

  final Widget child;
  final AppController controller;
  final BiometricGateway? biometricGateway;

  @override
  State<AppPrivacyShield> createState() => _AppPrivacyShieldState();
}

class _AppPrivacyShieldState extends State<AppPrivacyShield>
    with WidgetsBindingObserver {
  bool _covered = false;
  bool _locked = false;
  bool _authenticated = false;
  bool _authenticating = false;
  bool _wasRequired = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AppPrivacyShield oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
      _reconcileBiometricLock();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reconcileBiometricLock();
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
    if (state == AppLifecycleState.resumed) {
      _lockForResume();
    }
  }

  void _reconcileBiometricLock() {
    final controller = widget.controller;
    final required = _requiresBiometric(controller);
    if (!required) {
      _wasRequired = false;
      if (_locked || !_authenticated) {
        setState(() {
          _locked = false;
          _authenticated = true;
        });
      }
      return;
    }
    if (!_wasRequired || (!_authenticated && !_locked)) {
      _wasRequired = true;
      setState(() {
        _locked = true;
        _authenticated = false;
      });
      _scheduleAuthentication();
    }
  }

  void _onControllerChanged() {
    if (mounted) _reconcileBiometricLock();
  }

  bool _requiresBiometric(AppController controller) =>
      widget.biometricGateway != null &&
      controller.isReady &&
      controller.signedIn &&
      controller.settings.biometricLockEnabled;

  void _lockForResume() {
    if (!mounted) return;
    final controller = widget.controller;
    if (!_requiresBiometric(controller)) return;
    setState(() {
      _locked = true;
      _authenticated = false;
    });
    _scheduleAuthentication();
  }

  void _scheduleAuthentication() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _authenticate();
    });
  }

  Future<void> _authenticate() async {
    if (_authenticating || !mounted) return;
    final controller = widget.controller;
    if (!_requiresBiometric(controller)) return;
    final gateway = widget.biometricGateway;
    if (gateway == null) return;
    setState(() => _authenticating = true);
    try {
      final available = await gateway.isAvailable();
      final success = available && await gateway.authenticate();
      if (!mounted) return;
      if (success) {
        setState(() {
          _locked = false;
          _authenticated = true;
        });
      }
    } on BiometricGatewayException {
      // Keep the shield visible. The user can retry without exposing data.
    } finally {
      if (mounted) setState(() => _authenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.topLeft,
    fit: StackFit.expand,
    children: [
      widget.child,
      if (_covered || (_locked && !_authenticated))
        ColoredBox(
          color: LumeColors.background,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  label: 'Conteúdo protegido',
                  child: Icon(
                    Icons.lock_outline,
                    size: 48,
                    color: LumeColors.brand,
                  ),
                ),
                if (!_covered && _locked) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Desbloqueie para entrar no Lume',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _authenticating ? null : _authenticate,
                    icon: const Icon(Icons.face_outlined),
                    label: Text(
                      _authenticating ? 'Aguardando…' : 'Desbloquear',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
    ],
  );
}
