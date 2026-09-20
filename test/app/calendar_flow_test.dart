import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lume/app/app_controller.dart';
import 'package:lume/app/lume_app.dart';
import 'package:lume/app/models.dart';
import 'package:lume/core/calendar/calendar_gateway.dart';

Future<void> _route(WidgetTester tester, String route) async {
  tester.state<NavigatorState>(find.byType(Navigator).first).pushNamed(route);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final allDay in [false, true]) {
    testWidgets(
      'editing an imported event preserves duration and custom options, allDay=$allDay',
      (tester) async {
        final gateway = _Calendar();
        final original = CalendarEvent(
          id: 'event-1',
          title: 'Uma viagem',
          start: DateTime(2026, 9, 1),
          end: DateTime(2026, 9, 4),
          isAllDay: allDay,
          colorId: '5',
          timeZone: 'America/New_York',
          recurrence: const [
            'RRULE:FREQ=WEEKLY;COUNT=2',
            'EXDATE:20260908T000000Z',
          ],
          reminderMinutes: const [15, 30],
          reminderConfiguration: const {
            'useDefault': false,
            'overrides': [
              {'method': 'email', 'minutes': 15},
              {'method': 'popup', 'minutes': 30},
            ],
          },
        );
        final controller = AppController(calendarGateway: gateway)
          ..isReady = true
          ..signedIn = true
          ..settings = const UserSettings(
            onboardingComplete: true,
            calendarConnected: true,
          )
          ..calendarEvents = [original];
        await tester.pumpWidget(LumeApp(controller: controller));
        await tester.pumpAndSettle();
        await _route(tester, '/app/calendar/event/event-1/edit');
        expect(find.text('Editar evento'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.enterText(
          find.widgetWithText(TextField, 'Uma viagem'),
          'Viagem revisada',
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Salvar alterações'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Salvar alterações'));
        await tester.pumpAndSettle();
        final saved = gateway.updated!;
        expect(saved.title, 'Viagem revisada');
        expect(saved.id, original.id);
        expect(saved.start, original.start);
        expect(saved.end, original.end);
        expect(saved.recurrence, original.recurrence);
        expect(saved.reminderMinutes, original.reminderMinutes);
        expect(saved.reminderConfiguration, original.reminderConfiguration);
        expect(saved.timeZone, original.timeZone);
        expect(saved.colorId, original.colorId);
        expect(controller.calendarEvents, hasLength(1));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        controller.dispose();
      },
    );
  }

  testWidgets(
    'new event uses a valid recurrence rule and its form supports large text',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(() => tester.binding.setSurfaceSize(null));
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final gateway = _Calendar();
      final controller = AppController(calendarGateway: gateway)
        ..isReady = true
        ..signedIn = true
        ..settings = const UserSettings(
          onboardingComplete: true,
          calendarConnected: true,
        );
      await tester.pumpWidget(LumeApp(controller: controller));
      await tester.pumpAndSettle();
      await _route(tester, '/app/calendar/event/new');
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextField).first, 'Caminhar');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Não repetir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Não repetir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Semanal').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Criar evento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Criar evento'));
      await tester.pumpAndSettle();
      expect(gateway.created?.recurrence, ['RRULE:FREQ=WEEKLY']);
      expect(gateway.created?.reminderMinutes, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );

  testWidgets(
    'a calendar link waits for an explicit connection and can be canceled',
    (tester) async {
      final gateway = _Calendar();
      final controller = AppController(calendarGateway: gateway)
        ..isReady = true
        ..signedIn = true
        ..settings = const UserSettings(onboardingComplete: true);
      await tester.pumpWidget(LumeApp(controller: controller));
      await tester.pumpAndSettle();
      await _route(tester, '/app/calendar/event/new');
      expect(find.byTooltip('Fechar'), findsOneWidget);
      expect(gateway.connections, 0);
      await tester.tap(find.byTooltip('Fechar'));
      await tester.pumpAndSettle();
      expect(controller.settings.calendarConnected, isFalse);
      expect(gateway.created, isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );
}

class _Calendar extends LocalCalendarGateway {
  int connections = 0;
  CalendarEvent? created;
  CalendarEvent? updated;
  @override
  Future<void> connect() async {
    connections++;
  }

  @override
  Future<CalendarEvent> createEvent(CalendarEvent event) async =>
      created = event.copyWith(id: 'created-1');
  @override
  Future<CalendarEvent> updateEvent(CalendarEvent event) async =>
      updated = event;
}
