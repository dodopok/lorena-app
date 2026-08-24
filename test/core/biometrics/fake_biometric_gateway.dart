import 'package:local_auth/local_auth.dart';
import 'package:lume/core/biometrics/biometric_gateway.dart';
import 'package:lume/core/biometrics/local_auth_biometric_gateway.dart';

class FakeLocalAuthClient implements LocalAuthClient {
  FakeLocalAuthClient({
    this.supported = true,
    this.canCheck = true,
    this.authenticationResult = true,
    this.availabilityError,
    this.authenticationError,
  });

  final bool supported;
  final bool canCheck;
  final bool authenticationResult;
  final Object? availabilityError;
  final Object? authenticationError;

  int authenticateCalls = 0;
  String? lastLocalizedReason;
  AuthenticationOptions? lastOptions;

  @override
  Future<bool> isDeviceSupported() async {
    _throwIfPresent(availabilityError);
    return supported;
  }

  @override
  Future<bool> get canCheckBiometrics async {
    _throwIfPresent(availabilityError);
    return canCheck;
  }

  @override
  Future<bool> authenticate({
    required String localizedReason,
    required AuthenticationOptions options,
  }) async {
    authenticateCalls += 1;
    lastLocalizedReason = localizedReason;
    lastOptions = options;
    _throwIfPresent(authenticationError);
    return authenticationResult;
  }

  static void _throwIfPresent(Object? error) {
    if (error != null) throw error;
  }
}

class FakeBiometricGateway implements BiometricGateway {
  FakeBiometricGateway({
    this.available = true,
    this.authenticationResult = true,
    this.authenticationError,
  });

  bool available;
  bool authenticationResult;
  Object? authenticationError;
  int authenticateCalls = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate() async {
    authenticateCalls += 1;
    _throwIfPresent(authenticationError);
    return authenticationResult;
  }

  static void _throwIfPresent(Object? error) {
    if (error != null) throw error;
  }
}
