import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/biometrics/biometric_gateway.dart';
import 'package:lume/core/biometrics/local_auth_biometric_gateway.dart';

import 'fake_biometric_gateway.dart';

void main() {
  group('LocalAuthBiometricGateway', () {
    test(
      'reports availability only when the device can check biometrics',
      () async {
        final client = FakeLocalAuthClient();
        final gateway = LocalAuthBiometricGateway(client: client);

        expect(await gateway.isAvailable(), isTrue);
        expect(client.authenticateCalls, 0);
      },
    );

    test('reports false when biometric hardware is unavailable', () async {
      final gateway = LocalAuthBiometricGateway(
        client: FakeLocalAuthClient(supported: false),
      );

      expect(await gateway.isAvailable(), isFalse);
    });

    test('reports false when biometrics cannot be checked', () async {
      final gateway = LocalAuthBiometricGateway(
        client: FakeLocalAuthClient(canCheck: false),
      );

      expect(await gateway.isAvailable(), isFalse);
    });

    test('prefers biometrics and keeps passcode recovery available', () async {
      final client = FakeLocalAuthClient();
      final gateway = LocalAuthBiometricGateway(client: client);

      expect(await gateway.authenticate(), isTrue);
      expect(client.authenticateCalls, 1);
      expect(client.lastLocalizedReason, contains('Lume'));
      expect(client.lastOptions?.biometricOnly, isFalse);
      expect(client.lastOptions?.sensitiveTransaction, isTrue);
      expect(client.lastOptions?.stickyAuth, isTrue);
      expect(client.lastOptions?.useErrorDialogs, isFalse);
    });

    test('returns false when the user cancels the challenge', () async {
      final gateway = LocalAuthBiometricGateway(
        client: FakeLocalAuthClient(
          authenticationError: PlatformException(
            code: 'UserCancelled',
            message: 'native cancellation detail must stay private',
          ),
        ),
      );

      expect(await gateway.authenticate(), isFalse);
    });

    test(
      'returns false when the platform reports an unsuccessful challenge',
      () async {
        final gateway = LocalAuthBiometricGateway(
          client: FakeLocalAuthClient(authenticationResult: false),
        );

        expect(await gateway.authenticate(), isFalse);
      },
    );

    test('maps missing hardware to a friendly exception', () async {
      final gateway = LocalAuthBiometricGateway(
        client: FakeLocalAuthClient(
          authenticationError: PlatformException(
            code: 'NotAvailable',
            message: 'native hardware detail must stay private',
          ),
        ),
      );

      final error = await _captureGatewayException(gateway.authenticate());

      expect(error.reason, BiometricFailureReason.unavailable);
      expect(
        error.toString(),
        'A autenticação biométrica não está disponível neste aparelho.',
      );
      expect(error.toString(), isNot(contains('native')));
    });

    test('maps lockout to a friendly temporary failure', () async {
      final gateway = LocalAuthBiometricGateway(
        client: FakeLocalAuthClient(
          authenticationError: PlatformException(
            code: 'LockedOut',
            message: 'native lockout detail must stay private',
          ),
        ),
      );

      final error = await _captureGatewayException(gateway.authenticate());

      expect(error.reason, BiometricFailureReason.temporarilyUnavailable);
      expect(error.toString(), isNot(contains('native')));
    });

    test(
      'maps unexpected platform errors without exposing native details',
      () async {
        final gateway = LocalAuthBiometricGateway(
          client: FakeLocalAuthClient(
            authenticationError: PlatformException(
              code: 'private_native_code',
              message: 'private native message',
              details: 'private native details',
            ),
          ),
        );

        final error = await _captureGatewayException(gateway.authenticate());

        expect(error.reason, BiometricFailureReason.platformError);
        expect(
          error.toString(),
          'Não foi possível concluir a autenticação biométrica. Tente novamente.',
        );
        expect(error.toString(), isNot(contains('private')));
      },
    );

    test('turns availability platform errors into false', () async {
      final gateway = LocalAuthBiometricGateway(
        client: FakeLocalAuthClient(
          availabilityError: PlatformException(
            code: 'private_native_code',
            message: 'private native message',
          ),
        ),
      );

      expect(await gateway.isAvailable(), isFalse);
    });
  });

  test('FakeBiometricGateway is a controllable test double', () async {
    final fake = FakeBiometricGateway(
      available: false,
      authenticationResult: false,
    );

    expect(await fake.isAvailable(), isFalse);
    expect(await fake.authenticate(), isFalse);
    expect(fake.authenticateCalls, 1);
  });
}

Future<BiometricGatewayException> _captureGatewayException(
  Future<bool> operation,
) async {
  try {
    await operation;
    fail('Expected a BiometricGatewayException.');
  } on BiometricGatewayException catch (error) {
    return error;
  }
}
