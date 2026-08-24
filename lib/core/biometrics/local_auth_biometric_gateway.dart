import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import 'biometric_gateway.dart';

/// Small adapter around [LocalAuthentication] so the gateway can be tested
/// without opening native authentication UI.
abstract interface class LocalAuthClient {
  Future<bool> isDeviceSupported();

  Future<bool> get canCheckBiometrics;

  Future<bool> authenticate({
    required String localizedReason,
    required AuthenticationOptions options,
  });
}

/// Production adapter for the `local_auth` plugin.
class FlutterLocalAuthClient implements LocalAuthClient {
  FlutterLocalAuthClient({LocalAuthentication? authentication})
    : _authentication = authentication ?? LocalAuthentication();

  final LocalAuthentication _authentication;

  @override
  Future<bool> isDeviceSupported() => _authentication.isDeviceSupported();

  @override
  Future<bool> get canCheckBiometrics => _authentication.canCheckBiometrics;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    required AuthenticationOptions options,
  }) => _authentication.authenticate(
    localizedReason: localizedReason,
    options: options,
  );
}

/// Local biometric authentication backed by the operating system.
///
/// No biometric data, templates, secrets, or authentication results are
/// persisted by this class. The plugin owns the native interaction and this
/// boundary returns only the result of the current challenge.
class LocalAuthBiometricGateway implements BiometricGateway {
  LocalAuthBiometricGateway({
    LocalAuthClient? client,
    this.localizedReason =
        'Confirme sua identidade para acessar seus dados no Lume.',
  }) : _client = client ?? FlutterLocalAuthClient();

  final LocalAuthClient _client;
  final String localizedReason;

  @override
  Future<bool> isAvailable() async {
    final status = await _checkAvailability();
    return status == _Availability.available;
  }

  @override
  Future<bool> authenticate() async {
    switch (await _checkAvailability()) {
      case _Availability.available:
        break;
      case _Availability.unavailable:
        throw const BiometricGatewayException.unavailable();
      case _Availability.platformError:
        throw const BiometricGatewayException.platformError();
    }

    try {
      return await _client.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          // Face ID/Touch ID remains the preferred prompt, but allowing the
          // device passcode preserves a recovery path if biometrics are
          // temporarily unavailable or have been reset.
          biometricOnly: false,
          sensitiveTransaction: true,
          stickyAuth: true,
          useErrorDialogs: false,
        ),
      );
    } on PlatformException catch (error) {
      return _handlePlatformException(error);
    } catch (_) {
      throw const BiometricGatewayException.platformError();
    }
  }

  Future<_Availability> _checkAvailability() async {
    try {
      if (!await _client.isDeviceSupported()) {
        return _Availability.unavailable;
      }
      if (!await _client.canCheckBiometrics) {
        return _Availability.unavailable;
      }
      return _Availability.available;
    } on PlatformException {
      return _Availability.platformError;
    } catch (_) {
      return _Availability.platformError;
    }
  }

  bool _handlePlatformException(PlatformException error) {
    final code = error.code;
    if (_cancelledCodes.contains(code)) return false;
    if (_unavailableCodes.contains(code)) {
      throw const BiometricGatewayException.unavailable();
    }
    if (_temporarilyUnavailableCodes.contains(code)) {
      throw const BiometricGatewayException.temporarilyUnavailable();
    }
    throw const BiometricGatewayException.platformError();
  }
}

enum _Availability { available, unavailable, platformError }

const _cancelledCodes = <String>{
  'Canceled',
  'Cancelled',
  'UserCancelled',
  'UserCanceled',
  'UserFallback',
  'cancel',
  'cancelled',
  'userCanceled',
  'userCancelled',
  'user_canceled',
  'user_cancelled',
  'user_fallback',
};

const _unavailableCodes = <String>{
  'BiometricNotAvailable',
  'NotAvailable',
  'NotEnrolled',
  'PasscodeNotSet',
  'biometricOnlyNotSupported',
  'no_biometric_hardware',
  'noBiometricHardware',
};

const _temporarilyUnavailableCodes = <String>{
  'LockedOut',
  'PermanentlyLockedOut',
  'biometricHardwareTemporarilyUnavailable',
  'biometricLockout',
  'temporaryLockout',
};
