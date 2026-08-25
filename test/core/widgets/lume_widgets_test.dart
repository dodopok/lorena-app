import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/theme/lume_theme.dart';
import 'package:lume/core/widgets/lume_actions.dart';
import 'package:lume/core/widgets/lume_navigation.dart';
import 'package:lume/core/widgets/lume_progress.dart';
import 'package:lume/core/widgets/lume_states.dart';
import 'package:lume/core/widgets/lume_sync_indicator.dart';

Widget _host(Widget child) => MaterialApp(
  theme: LumeTheme.light(),
  home: Scaffold(body: child),
);

void main() {
  testWidgets(
    'progress card handles missing and zero goals without division errors',
    (tester) async {
      await tester.pumpWidget(
        _host(const LumeProgressCard(label: 'Água', value: 300, unit: 'ml')),
      );
      expect(find.text('300 ml'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        _host(
          const LumeProgressCard(label: 'Água', value: 300, max: 0, unit: 'ml'),
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('money summary stays readable at compact width', (tester) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 320,
          child: LumeMoneySummaryCard(
            periodLabel: '08/2026',
            balanceMinor: 120000,
            currency: 'BRL',
            incomeMinor: 120000,
            expenseMinor: 0,
            rolloverMinor: 0,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(LumeMoneySummaryCard)).width, 320);
  });

  testWidgets('button loading state announces saving and prevents taps', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      _host(
        LumeButton(label: 'Salvar', isLoading: true, onPressed: () => calls++),
      ),
    );
    expect(find.text('Salvando'), findsOneWidget);
    await tester.tap(find.byType(LumeButton));
    expect(calls, 0);
  });

  testWidgets('bottom navigation exposes selected destination semantically', (
    tester,
  ) async {
    var selected = LumeDestination.today;
    await tester.pumpWidget(
      _host(
        LumeBottomNavigation(
          currentDestination: selected,
          onDestinationSelected: (value) => selected = value,
        ),
      ),
    );
    expect(find.bySemanticsLabel('Hoje, aba selecionada'), findsOneWidget);
    await tester.tap(find.text('Agenda'));
    expect(selected, LumeDestination.calendar);
  });

  testWidgets('empty, error and sync states render only provided actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const LumeEmptyState(
          title: 'Nada salvo',
          description: 'Crie seu primeiro registro.',
        ),
      ),
    );
    expect(find.text('Nada salvo'), findsOneWidget);
    await tester.pumpWidget(
      _host(
        const LumeErrorState(
          title: 'Não foi possível carregar',
          description: 'Tente novamente.',
        ),
      ),
    );
    expect(find.text('Tentar novamente'), findsNothing);
    await tester.pumpWidget(
      _host(const LumeSyncIndicator(state: LumeSyncState.pending)),
    );
    expect(find.textContaining('Salvo neste aparelho'), findsOneWidget);
  });
}
