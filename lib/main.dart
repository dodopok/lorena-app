import 'package:flutter/widgets.dart';

import 'app/app_controller.dart';
import 'app/lume_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController();
  await controller.hydrate();
  runApp(LumeApp(controller: controller));
}
