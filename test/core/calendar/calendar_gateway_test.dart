import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/calendar/calendar_gateway.dart';

void main() {
  test('interpreta eventos com horário e dia inteiro sem inventar horário', () {
    final events = parseCalendarEvents({
      'items': [
        {
          'summary': 'Consulta',
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
}
