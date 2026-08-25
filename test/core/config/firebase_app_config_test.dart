import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/environment.dart';
import 'package:lume/core/config/firebase_app_config.dart';

void main() {
  test(
    'configuração compartilhada contém os identificadores públicos informados',
    () {
      const config = FirebaseAppConfig.shared;

      expect(config.projectId, 'lume-13125');
      expect(config.appId, '1:980338934048:ios:e7b42996cde98f0bba5745');
      expect(config.messagingSenderId, '980338934048');
      expect(config.storageBucket, 'lume-13125.firebasestorage.app');
      expect(
        config.iosClientId,
        '980338934048-d1ijkl2g5e2o1u28bo2ihtnbfi04a5vk.apps.googleusercontent.com',
      );
      expect(config.apiKey, isNotEmpty);
    },
  );

  test('modelo é imutável e não aceita campos públicos vazios', () {
    const config = FirebaseAppConfig.shared;
    expect(config.hasPlaceholderApiKey, isFalse);
    expect(
      () => FirebaseAppConfig(
        projectId: '',
        appId: 'app',
        apiKey: 'key',
        messagingSenderId: 'sender',
        storageBucket: 'bucket',
        iosClientId: 'client',
      ),
      throwsA(isA<AssertionError>()),
    );
  });

  test('a configuração não incorpora formato de segredo privado', () {
    const config = FirebaseAppConfig.shared;
    expect(config.apiKey, isNot(contains('PRIVATE')));
    expect(config.apiKey, isNot(contains('client_secret')));
    expect(config.apiKey, isNot(contains('.p8')));
  });

  test('a Agenda usa o client iOS público confirmado por padrão', () {
    expect(LumeBuildConfig.enableCalendar, isTrue);
    expect(
      LumeBuildConfig.googleCalendarIosClientId,
      '1018427269031-btmqjfbld86lqsfpr0aivec1vj8bbn8d.apps.googleusercontent.com',
    );
    expect(
      LumeBuildConfig.googleCalendarWebClientId,
      '1018427269031-d002niqglh23u9omq8urmee091gqotca.apps.googleusercontent.com',
    );
  });
}
