import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../app/environment.dart';
import '../config/firebase_app_config.dart';

abstract final class FirebaseBootstrap {
  static Future<bool> initialize() async {
    if (LumeBuildConfig.environment == LumeEnvironment.local) return false;

    // The first distribution target is iPhone. Android keeps the local
    // gateway until its own Firebase app registration is supplied.
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return false;

    if (Firebase.apps.isNotEmpty) return true;
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: FirebaseAppConfig.shared.apiKey,
        appId: FirebaseAppConfig.shared.appId,
        messagingSenderId: FirebaseAppConfig.shared.messagingSenderId,
        projectId: FirebaseAppConfig.shared.projectId,
        storageBucket: FirebaseAppConfig.shared.storageBucket,
      ),
    );
    return true;
  }
}
