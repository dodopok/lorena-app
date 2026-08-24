import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app_controller.dart';
import 'app/environment.dart';
import 'app/lume_app.dart';
import 'core/auth/auth_gateway.dart';
import 'core/biometrics/local_auth_biometric_gateway.dart';
import 'core/bootstrap/firebase_bootstrap.dart';
import 'core/calendar/calendar_gateway.dart';
import 'core/notifications/lume_notification_gateway.dart';
import 'core/photos/firebase_photo_storage.dart';
import 'core/sync/firestore_snapshot_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  final firebaseReady = await FirebaseBootstrap.initialize();
  final biometricGateway = LocalAuthBiometricGateway();
  final authGateway = firebaseReady ? FirebaseAppleAuthGateway() : null;
  final calendarGateway =
      LumeBuildConfig.enableCalendar &&
          LumeBuildConfig.googleCalendarIosClientId.isNotEmpty
      ? GoogleCalendarGateway(
          signIn: GoogleSignIn(
            clientId: LumeBuildConfig.googleCalendarIosClientId,
            scopes: const [
              'https://www.googleapis.com/auth/calendar.calendarlist.readonly',
              'https://www.googleapis.com/auth/calendar.events.readonly',
            ],
          ),
        )
      : null;
  final controller = AppController(
    authGateway: authGateway,
    calendarGateway: calendarGateway,
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
