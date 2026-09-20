import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lume/app/app_controller.dart';
import 'package:lume/app/local_store.dart';
import 'package:lume/app/lume_app.dart';
import 'package:lume/app/models.dart';

Future<void> _open(WidgetTester tester, AppController controller) async {
  await tester.pumpWidget(LumeApp(controller: controller));
  await tester.pumpAndSettle();
  tester
      .state<NavigatorState>(find.byType(Navigator).first)
      .pushNamed('/app/wellbeing/water/new');
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'manual water saves the selected date and time using Portuguese pickers',
    (tester) async {
      final controller = AppController()
        ..isReady = true
        ..signedIn = true
        ..settings = const UserSettings(onboardingComplete: true);
      await _open(tester, controller);
      await tester.enterText(find.byType(TextField), '375');
      await _tap(tester, find.textContaining('Data:'));
      expect(find.text('Cancelar'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await tester.enterText(
        find.byType(TextField).last,
        '${yesterday.day.toString().padLeft(2, '0')}/${yesterday.month.toString().padLeft(2, '0')}/${yesterday.year}',
      );
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await _tap(tester, find.textContaining('Horário:'));
      expect(find.text('Cancelar'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await tester.pumpAndSettle();
      final timeFields = find.descendant(
        of: find.byType(TimePickerDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(timeFields.at(0), '09');
      await tester.enterText(timeFields.at(1), '30');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsNothing);
      await _tap(tester, find.text('Salvar'));
      final saved = controller.waterLogs.single;
      expect(saved.amountMl, 375);
      expect(saved.localDate, controller.localDateFor(yesterday));
      expect(saved.occurredAt.hour, 9);
      expect(saved.occurredAt.minute, 30);
      expect(controller.waterTotalFor(DateTime.now()), 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );

  testWidgets(
    'failed water save keeps fields and retry stores exactly one record',
    (tester) async {
      final store = _FailingStore();
      final controller = AppController(store: store)
        ..isReady = true
        ..signedIn = true
        ..settings = const UserSettings(onboardingComplete: true);
      await _open(tester, controller);
      await tester.enterText(find.byType(TextField), '275');
      await _tap(tester, find.text('Salvar'));
      expect(controller.waterLogs, isEmpty);
      expect(find.textContaining('Não foi possível salvar'), findsOneWidget);
      expect(find.widgetWithText(TextField, '275'), findsOneWidget);
      store.fail = false;
      await _tap(tester, find.text('Salvar'));
      expect(controller.waterLogs.single.amountMl, 275);
      final restored = AppController();
      await restored.hydrate();
      expect(restored.waterLogs.single.amountMl, 275);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      restored.dispose();
    },
  );
}

class _FailingStore extends LocalStore {
  bool fail = true;
  @override
  Future<void> write(AppSnapshot snapshot) async {
    if (fail) throw StateError('Disk unavailable');
    await super.write(snapshot);
  }
}
