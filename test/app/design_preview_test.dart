import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lume/app/app_controller.dart';
import 'package:lume/app/lume_app.dart';
import 'package:lume/app/models.dart';
import 'package:lume/app/theme.dart';
import 'package:lume/features/auth/presentation/auth_screens.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
    for (final font in ['Nunito', 'Lora']) {
      await (FontLoader(font)..addFont(
            rootBundle.load(
              'assets/fonts/${font.toLowerCase()}/$font-Regular.ttf',
            ),
          ))
          .load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  for (final dark in [false, true]) {
    for (final size in [
      const Size(390, 844),
      const Size(320, 640),
      const Size(1024, 900),
    ]) {
      testWidgets('layout ${size.width}, dark=$dark', (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final controller = AppController()
          ..isReady = true
          ..signedIn = true
          ..settings = const UserSettings(onboardingComplete: true);
        addTearDown(controller.dispose);
        final boundary = GlobalKey();
        for (final screen in [
          ...AppDestination.values.map((destination) => destination.name),
          'welcome',
        ]) {
          await tester.pumpWidget(
            RepaintBoundary(
              key: boundary,
              child: AppScope(
                controller: controller,
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: dark ? LumeTheme.dark() : LumeTheme.light(),
                  home: screen == 'welcome'
                      ? const WelcomeScreen()
                      : AppShell(
                          key: ValueKey(screen),
                          initialDestination: AppDestination.values.byName(
                            screen,
                          ),
                        ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.runAsync(() async {
            await precacheImage(
              const AssetImage('assets/images/lume-editorial-still-life.png'),
              tester.element(find.byType(Scaffold).first),
            );
          });
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (const bool.fromEnvironment('DESIGN_PREVIEW')) {
            await tester.runAsync(() async {
              final image =
                  await (boundary.currentContext!.findRenderObject()!
                          as RenderRepaintBoundary)
                      .toImage();
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final file = File(
                'build/design/$screen-${size.width.toInt()}-${dark ? 'dark' : 'light'}.png',
              );
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
        }
      });
    }
  }
}
