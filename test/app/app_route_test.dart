import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lume/app/app_controller.dart';
import 'package:lume/app/app_route.dart';
import 'package:lume/app/lume_app.dart';
import 'package:lume/app/models.dart';

Future<void> _navigate(WidgetTester tester, String route) async {
  tester.state<NavigatorState>(find.byType(Navigator).first).pushNamed(route);
  await tester.pumpAndSettle();
}

AppController _controller() => AppController()
  ..isReady = true
  ..signedIn = true
  ..settings = const UserSettings(onboardingComplete: true);

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'documented editor and collection routes retain their action and ID',
    () {
      const routes = {
        '/app/wellbeing/water/new': AppRouteAction.waterNew,
        '/app/wellbeing/bowel/new': AppRouteAction.bowelNew,
        '/app/wellbeing/exercise/new': AppRouteAction.exerciseNew,
        '/app/calendar/connect': AppRouteAction.calendarConnect,
        '/app/calendar/event/new': AppRouteAction.eventNew,
        '/app/calendar/event/event-1/edit': AppRouteAction.eventEdit,
        '/app/finance/transaction/new': AppRouteAction.transactionNew,
        '/app/finance/transaction/tx-1/edit': AppRouteAction.transactionEdit,
        '/app/finance/shopping/list-1': AppRouteAction.shopping,
        '/app/finance/wishlist': AppRouteAction.wishlist,
        '/app/finance/wishlist/new': AppRouteAction.wishlistNew,
        '/app/finance/wishlist/wish-1/edit': AppRouteAction.wishlistEdit,
        '/app/corner/books': AppRouteAction.books,
        '/app/corner/books/new': AppRouteAction.bookNew,
        '/app/corner/books/book-1/edit': AppRouteAction.bookEdit,
        '/app/corner/gratitude': AppRouteAction.gratitude,
        '/app/corner/gratitude/2026-09-05/edit': AppRouteAction.gratitudeEdit,
      };
      for (final route in routes.entries) {
        expect(
          AppRouteRequest.parse(route.key)?.action,
          route.value,
          reason: route.key,
        );
      }
      expect(
        AppRouteRequest.parse('/app/finance/shopping/list-1')?.id,
        'list-1',
      );
      expect(
        AppRouteRequest.parse(
          '/app/finance/transaction/new?type=income',
        )?.income,
        isTrue,
      );
      for (final invalid in [
        '/app/calendar/event/',
        '/app/corner/books/no-id',
        '/app/corner/gratitude/2026-02-30/edit',
        '/app/corner/gratitude/bad/edit',
        '/app/today/extra',
        'https://example.com/app/today',
      ]) {
        expect(AppRouteRequest.parse(invalid), isNull, reason: invalid);
      }
    },
  );

  for (final route in {
    '/app/wellbeing/water/new': 'Adicionar água',
    '/app/wellbeing/bowel/new': 'Registrar evacuação',
    '/app/wellbeing/exercise/new': 'Novo exercício',
    '/app/finance/transaction/new': 'Novo gasto',
    '/app/finance/transaction/new?type=income': 'Nova entrada',
    '/app/finance/wishlist/new': 'Salvar desejo',
    '/app/corner/books/new': 'Adicionar livro',
  }.entries) {
    for (final compact in [false, true]) {
      testWidgets('${route.key} opens its form, compact=$compact', (
        tester,
      ) async {
        if (compact) {
          await tester.binding.setSurfaceSize(const Size(320, 640));
          tester.platformDispatcher.textScaleFactorTestValue = 1.6;
          tester.view.viewInsets = const FakeViewPadding(bottom: 240);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          addTearDown(tester.view.resetViewInsets);
        }
        final controller = _controller();
        await tester.pumpWidget(LumeApp(controller: controller));
        await tester.pumpAndSettle();
        await _navigate(tester, route.key);
        expect(find.byTooltip('Fechar'), findsOneWidget);
        expect(find.text(route.value), findsWidgets);
        expect(find.byType(TextField), findsWidgets);
        expect(tester.takeException(), isNull);
        await tester.drag(
          find.byType(SingleChildScrollView).last,
          const Offset(0, -1500),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        controller.dispose();
      });
    }
  }

  testWidgets('existing book opens populated and a missing ID is explained', (
    tester,
  ) async {
    final controller = _controller();
    controller.books = const [
      BookEntry(
        id: 'book-1',
        title: 'A hora da estrela',
        status: BookStatus.reading,
      ),
    ];
    await tester.pumpWidget(LumeApp(controller: controller));
    await tester.pumpAndSettle();
    await _navigate(tester, '/app/corner/books/book-1/edit');
    expect(find.widgetWithText(TextField, 'A hora da estrela'), findsOneWidget);
    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();
    await _navigate(tester, '/app/corner/books/missing/edit');
    expect(
      find.textContaining('Este registro não está disponível'),
      findsOneWidget,
    );
    expect(find.byTooltip('Fechar'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('private settings require sign in', (tester) async {
    final controller = AppController()..isReady = true;
    await tester.pumpWidget(LumeApp(controller: controller));
    await tester.pumpAndSettle();
    await _navigate(tester, '/app/settings/privacy');
    expect(find.text('Continuar neste aparelho'), findsOneWidget);
    expect(find.text('Exportar dados'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  for (final type in [TransactionType.allowance, TransactionType.adjustment]) {
    testWidgets('editing ${type.name} keeps its type and saves in place', (
      tester,
    ) async {
      final controller = _controller();
      controller.transactions = [
        TransactionEntry(
          id: 'transaction-1',
          type: type,
          amountMinor: 5000,
          occurredAt: DateTime(2026, 8, 15),
          period: '2026-08',
          category: 'Receita',
          description: 'Valor original',
        ),
      ];
      await tester.pumpWidget(LumeApp(controller: controller));
      await tester.pumpAndSettle();
      await _navigate(tester, '/app/finance/transaction/transaction-1/edit');
      expect(find.text('Editar lançamento'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.enterText(
        find.widgetWithText(TextField, 'Valor original'),
        'Valor revisado',
      );
      await tester.ensureVisible(find.text('Salvar lançamento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar lançamento'));
      await tester.pumpAndSettle();
      expect(controller.transactions.single.id, 'transaction-1');
      expect(controller.transactions.single.type, type);
      expect(controller.transactions.single.description, 'Valor revisado');
      expect(controller.transactions.single.period, '2026-08');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    });
  }

  testWidgets(
    'full gratitude history reaches and edits entries older than the preview',
    (tester) async {
      final controller = _controller();
      controller.gratitudeEntries = List.generate(
        14,
        (index) => GratitudeEntry(
          localDate: controller.localDateFor(DateTime(2026, 8, index + 1)),
          text: 'Lembrança ${index + 1}',
        ),
      );
      await tester.pumpWidget(LumeApp(controller: controller));
      await tester.pumpAndSettle();
      await _navigate(tester, '/app/corner/gratitude');
      expect(find.text('Histórico de gratidão'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Lembrança 1'),
        300,
        scrollable: find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(find.text('Lembrança 1'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Lembrança 1'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('gratitude-text')),
        'Uma memória recuperada',
      );
      await tester.ensureVisible(find.text('Guardar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(
        controller.gratitudeFor(DateTime(2026, 8, 1)).single.text,
        'Uma memória recuperada',
      );
      expect(controller.gratitudeEntries, hasLength(14));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );
}
