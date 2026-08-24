/// Configuração pública necessária para inicializar um app Firebase.
///
/// Estes valores não substituem regras de segurança nem contêm credenciais de
/// backend. A API key do Firebase é pública e vem do GoogleService-Info.plist
/// compartilhado deste app.
class FirebaseAppConfig {
  const FirebaseAppConfig({
    required this.projectId,
    required this.appId,
    required this.apiKey,
    required this.messagingSenderId,
    required this.storageBucket,
    required this.iosClientId,
  }) : assert(projectId != ''),
       assert(appId != ''),
       assert(apiKey != ''),
       assert(messagingSenderId != ''),
       assert(storageBucket != ''),
       assert(iosClientId != '');

  final String projectId;
  final String appId;
  final String apiKey;
  final String messagingSenderId;
  final String storageBucket;
  final String iosClientId;

  /// Configuração pública compartilhada informada para o projeto Lume.
  ///
  /// Nenhum segredo ou client secret deve ser colocado aqui.
  static const shared = FirebaseAppConfig(
    projectId: 'lume-13125',
    appId: '1:980338934048:ios:e7b42996cde98f0bba5745',
    apiKey: 'AIzaSyCXB7GA_ZTJGT9qLchFHP5v3AYMNXFigVI',
    messagingSenderId: '980338934048',
    storageBucket: 'lume-13125.firebasestorage.app',
    iosClientId:
        '980338934048-d1ijkl2g5e2o1u28bo2ihtnbfi04a5vk.apps.googleusercontent.com',
  );

  bool get hasPlaceholderApiKey => apiKey.startsWith('PUBLIC_');
}
