import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/models.dart';
import 'package:lume/core/calendar/calendar_gateway.dart';

void main() {
  test('interpreta eventos com horário e dia inteiro sem inventar horário', () {
    final events = parseCalendarEvents({
      'items': [
        {
          'id': 'event-1',
          'calendarId': 'work',
          'etag': '"v1"',
          'htmlLink': 'https://calendar.google.com/event?eid=1',
          'summary': 'Consulta',
          'description': 'Levar documentos',
          'colorId': '5',
          'recurrence': ['RRULE:FREQ=WEEKLY;COUNT=2'],
          'reminders': {
            'useDefault': false,
            'overrides': [
              {'method': 'popup', 'minutes': 30},
            ],
          },
          'start': {'dateTime': '2026-08-24T10:00:00-03:00'},
          'end': {'dateTime': '2026-08-24T11:00:00-03:00'},
        },
        {
          'summary': 'Feriado',
          'start': {'date': '2026-08-25'},
          'end': {'date': '2026-08-26'},
        },
      ],
    });

    expect(events, hasLength(2));
    expect(events.first.title, 'Consulta');
    expect(events.first.id, 'event-1');
    expect(events.first.calendarId, 'work');
    expect(events.first.description, 'Levar documentos');
    expect(events.first.colorId, '5');
    expect(events.first.etag, '"v1"');
    expect(events.first.htmlLink, 'https://calendar.google.com/event?eid=1');
    expect(events.first.recurrence, ['RRULE:FREQ=WEEKLY;COUNT=2']);
    expect(events.first.reminderMinutes, [30]);
    expect(events.first.isAllDay, isFalse);
    expect(events.last.title, 'Feriado');
    expect(events.last.isAllDay, isTrue);
    expect(events.last.start.hour, 0);
  });

  test('descarta eventos sem início ou fim utilizáveis', () {
    expect(
      parseCalendarEvents({
        'items': [
          {'summary': 'Incompleto', 'start': {}, 'end': {}},
        ],
      }),
      isEmpty,
    );
  });

  test('serializa evento com horário, recorrência e lembrete', () {
    final payload = calendarEventRequestBody(
      CalendarEvent(
        id: 'event-1',
        title: 'Consulta',
        description: 'Levar documentos',
        start: DateTime(2026, 8, 24, 10),
        end: DateTime(2026, 8, 24, 11),
        recurrence: const ['RRULE:FREQ=WEEKLY;COUNT=2'],
        reminderMinutes: const [30],
      ),
    );

    expect(payload['id'], 'event-1');
    expect(payload['summary'], 'Consulta');
    expect(payload['start'], {'dateTime': '2026-08-24T13:00:00.000Z'});
    expect(payload['end'], {'dateTime': '2026-08-24T14:00:00.000Z'});
    expect(payload['recurrence'], ['RRULE:FREQ=WEEKLY;COUNT=2']);
    expect(payload['reminders'], {
      'useDefault': false,
      'overrides': [
        {'method': 'popup', 'minutes': 30},
      ],
    });
  });

  test('serializa evento de dia inteiro como datas sem horário', () {
    final payload = calendarEventRequestBody(
      CalendarEvent(
        title: 'Feriado',
        start: DateTime(2026, 8, 25),
        end: DateTime(2026, 8, 26),
        isAllDay: true,
      ),
    );

    expect(payload['start'], {'date': '2026-08-25'});
    expect(payload['end'], {'date': '2026-08-26'});
  });

  test('não aceita evento sem duração positiva', () {
    expect(
      () => calendarEventRequestBody(
        CalendarEvent(
          title: 'Inválido',
          start: DateTime(2026, 8, 24, 11),
          end: DateTime(2026, 8, 24, 10),
        ),
      ),
      throwsA(isA<CalendarGatewayException>()),
    );
  });
}
