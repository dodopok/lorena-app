/// Boundary for local device authentication.
///
/// Implementations must never persist biometric material. The operating
/// system owns the biometric data and only returns the result of the
/// authentication challenge to the app.
abstract interface class BiometricGateway {
  /// Whether biometric authentication can currently be attempted.
  Future<bool> isAvailable();

  /// Returns `true` after a successful challenge.
  ///
  /// A user cancellation or an unsuccessful challenge returns `false`. An
  /// unavailable sensor or an unexpected platform failure throws a
  /// [BiometricGatewayException] with a user-safe message.
  Future<bool> authenticate();
}

enum BiometricFailureReason {
  unavailable,
  temporarilyUnavailable,
  platformError,
}

/// Safe, user-facing failure from the biometric boundary.
///
/// The exception intentionally accepts only a typed reason, rather than a
/// native error message. This prevents platform details from reaching the UI
/// or telemetry accidentally.
class BiometricGatewayException implements Exception {
  const BiometricGatewayException(this.reason);

  const BiometricGatewayException.unavailable()
    : this(BiometricFailureReason.unavailable);

  const BiometricGatewayException.temporarilyUnavailable()
    : this(BiometricFailureReason.temporarilyUnavailable);

  const BiometricGatewayException.platformError()
    : this(BiometricFailureReason.platformError);

  final BiometricFailureReason reason;

  String get message => switch (reason) {
    BiometricFailureReason.unavailable =>
      'A autenticação biométrica não está disponível neste aparelho.',
    BiometricFailureReason.temporarilyUnavailable =>
      'A biometria está temporariamente indisponível. Tente novamente mais tarde.',
    BiometricFailureReason.platformError =>
      'Não foi possível concluir a autenticação biométrica. Tente novamente.',
  };

  @override
  String toString() => message;
}
