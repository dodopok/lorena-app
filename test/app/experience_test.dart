import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lume/app/app_controller.dart';
import 'package:lume/app/lume_app.dart';
import 'package:lume/app/models.dart';
import 'package:lume/app/theme.dart';
import 'package:lume/core/widgets/lume_navigation.dart';
import 'package:lume/features/auth/presentation/auth_screens.dart';

AppController _controller() => AppController()
  ..isReady = true
  ..signedIn = true
  ..settings = const UserSettings(onboardingComplete: true);

Widget _host(
  AppController controller, {
  AppDestination destination = AppDestination.today,
  double textScale = 1,
  bool dark = false,
  Widget? child,
}) => AppScope(
  controller: controller,
  child: MaterialApp(
    theme: dark ? LumeTheme.dark() : LumeTheme.light(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: child ?? AppShell(initialDestination: destination),
  ),
);

Future<void> _tab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(
      of: find.byType(LumeBottomNavigation),
      matching: find.text(label),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('atalhos selecionam a aba sem empilhar outro shell', (
    tester,
  ) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_host(controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver histórico'));
    await tester.pumpAndSettle();
    expect(find.byType(AppShell, skipOffstage: false), findsOneWidget);
    expect(find.text('Registros gentis, sem cobrança'), findsOneWidget);
    await _tab(tester, 'Hoje');
    expect(find.text('Ver histórico'), findsOneWidget);
  });

  testWidgets('busca e rolagem do Cantinho sobrevivem à troca de abas', (
    tester,
  ) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(controller, destination: AppDestination.corner),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Clarice');
    tester.testTextInput.hide();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -240));
    await tester.pumpAndSettle();
    final scrollable = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    final offset = scrollable.position.pixels;
    expect(offset, greaterThan(0));
    await _tab(tester, 'Hoje');
    await _tab(tester, 'Cantinho');
    expect(find.text('Clarice'), findsOneWidget);
    expect(scrollable.position.pixels, offset);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'histórico inclui dias anteriores mesmo sem água hoje e permite desfazer',
    (tester) async {
      final controller = _controller();
      addTearDown(controller.dispose);
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      controller.waterLogs = [
        WaterLog(
          id: 'older',
          amountMl: 375,
          occurredAt: yesterday,
          localDate: controller.localDateFor(yesterday),
        ),
      ];
      await tester.pumpWidget(
        _host(controller, destination: AppDestination.wellbeing),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver tudo'));
      await tester.pumpAndSettle();
      expect(find.text('Histórico de água'), findsOneWidget);
      expect(find.text('375 ml registrados'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(controller.waterLogs, isEmpty);
      await tester.tap(find.text('Desfazer'));
      await tester.pumpAndSettle();
      expect(controller.waterLogs.single.id, 'older');
    },
  );

  for (final dark in [false, true]) {
    testWidgets(
      'Hoje e boas-vindas cabem em 320px com texto ampliado, dark=$dark',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final controller = _controller();
        addTearDown(controller.dispose);
        await tester.pumpWidget(_host(controller, textScale: 1.6, dark: dark));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(
          _host(
            controller,
            textScale: 1.6,
            dark: dark,
            child: const WelcomeScreen(),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Começar'));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
