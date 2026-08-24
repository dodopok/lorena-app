import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app/app_controller.dart';
import 'app/lume_app.dart';
import 'core/auth/auth_gateway.dart';
import 'core/biometrics/local_auth_biometric_gateway.dart';
import 'core/bootstrap/firebase_bootstrap.dart';
import 'core/notifications/lume_notification_gateway.dart';
import 'core/photos/firebase_photo_storage.dart';
import 'core/sync/firestore_snapshot_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseReady = await FirebaseBootstrap.initialize();
  final biometricGateway = LocalAuthBiometricGateway();
  final authGateway = firebaseReady ? FirebaseAppleAuthGateway() : null;
  final controller = AppController(
    authGateway: authGateway,
    biometricGateway: biometricGateway,
    notificationGateway: LumeNotificationGateway(),
    photoStorage: firebaseReady ? FirebasePhotoStorage() : null,
    remoteStoreFactory: firebaseReady
        ? (uid) => FirestoreSnapshotStore(
            uid: uid,
            firestore: FirebaseFirestore.instance,
          )
        : null,
  );
  await controller.hydrate();
  await controller.restoreAuthSession();
  await controller.syncRemote();
  runApp(LumeApp(controller: controller, biometricGateway: biometricGateway));
}
