import 'package:flutter/widgets.dart';

import 'app/app_controller.dart';
import 'app/lume_app.dart';
import 'core/auth/auth_gateway.dart';
import 'core/bootstrap/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseReady = await FirebaseBootstrap.initialize();
  final controller = AppController(
    authGateway: firebaseReady ? FirebaseAppleAuthGateway() : null,
  );
  await controller.hydrate();
  await controller.restoreAuthSession();
  runApp(LumeApp(controller: controller));
}
