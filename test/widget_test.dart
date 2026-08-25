import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/app_controller.dart';
import 'package:lume/app/lume_app.dart';

void main() {
  testWidgets('mostra a proposta do Lume para uma sessão nova', (tester) async {
    final controller = AppController()..isReady = true;
    await tester.pumpWidget(LumeApp(controller: controller));

    expect(find.text('Lume'), findsOneWidget);
    expect(find.text('Começar'), findsOneWidget);
    expect(find.textContaining('pequenos passos'), findsOneWidget);
  });

  testWidgets('escudo de privacidade mantém Directionality no app', (
    tester,
  ) async {
    final controller = AppController()..isReady = true;
    await tester.pumpWidget(LumeApp(controller: controller));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
