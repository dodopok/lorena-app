import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../../app/models.dart';

const _calendarReadScopes = <String>[
  'https://www.googleapis.com/auth/calendar.calendarlist.readonly',
  'https://www.googleapis.com/auth/calendar.events.readonly',
];
const _calendarWriteScope = 'https://www.googleapis.com/auth/calendar.events';

class CalendarSyncResult {
  const CalendarSyncResult({
    required this.events,
    this.removedEventIds = const [],
    this.nextSyncToken,
    this.isIncremental = false,
  });

  final List<CalendarEvent> events;
  final List<String> removedEventIds;
  final String? nextSyncToken;
  final bool isIncremental;
}

abstract interface class CalendarGateway {
  Future<void> connect();

  Future<void> disconnect();

  Future<CalendarSyncResult> syncEvents({
    DateTime? from,
    DateTime? to,
    String? syncToken,
  });

  Future<List<CalendarEvent>> fetchEvents({DateTime? from, DateTime? to});

  Future<bool> requestWriteAccess();

  Future<CalendarEvent> createEvent(CalendarEvent event);

  Future<CalendarEvent> updateEvent(CalendarEvent event);

  Future<void> deleteEvent(CalendarEvent event);
}

class LocalCalendarGateway implements CalendarGateway {
  const LocalCalendarGateway();

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<CalendarSyncResult> syncEvents({
    DateTime? from,
    DateTime? to,
    String? syncToken,
  }) async => const CalendarSyncResult(events: []);

  @override
  Future<List<CalendarEvent>> fetchEvents({
    DateTime? from,
    DateTime? to,
  }) async => const [];

  @override
  Future<bool> requestWriteAccess() async => true;

  @override
  Future<CalendarEvent> createEvent(CalendarEvent event) async => event;

  @override
  Future<CalendarEvent> updateEvent(CalendarEvent event) async => event;

  @override
  Future<void> deleteEvent(CalendarEvent event) async {}
}

class CalendarGatewayException implements Exception {
  const CalendarGatewayException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class GoogleCalendarGateway implements CalendarGateway {
  GoogleCalendarGateway({
    GoogleSignIn? signIn,
    http.Client? client,
    String? clientId,
  }) : _signIn =
           signIn ??
           GoogleSignIn(scopes: _calendarReadScopes, clientId: clientId),
       _client = client ?? http.Client();

  final GoogleSignIn _signIn;
  final http.Client _client;

  @override
  Future<void> connect() async {
    GoogleSignInAccount? account;
    try {
      account = await _signIn.signIn();
    } catch (_) {
      throw const CalendarGatewayException(
        'Não foi possível abrir a autorização do Google.',
      );
    }
    if (account == null) {
      throw const CalendarGatewayException('Conexão com o Google cancelada.');
    }
    await _accessToken(account);
  }

  @override
  Future<void> disconnect() => _signIn.disconnect();

  @override
  Future<CalendarSyncResult> syncEvents({
    DateTime? from,
    DateTime? to,
    String? syncToken,
  }) async {
    try {
      return await _syncEventsPage(from: from, to: to, syncToken: syncToken);
    } on CalendarGatewayException catch (error) {
      if (error.statusCode != 410 || syncToken == null) rethrow;
      // Google invalidates sync tokens from time to time. A 410 is a signal
      // to discard only the calendar cursor and rebuild the local cache.
      return _syncEventsPage(from: from, to: to);
    }
  }

  @override
  Future<List<CalendarEvent>> fetchEvents({
    DateTime? from,
    DateTime? to,
  }) async => (await syncEvents(from: from, to: to)).events;

  Future<CalendarSyncResult> _syncEventsPage({
    DateTime? from,
    DateTime? to,
    String? syncToken,
  }) async {
    final account = _signIn.currentUser;
    if (account == null) {
      throw const CalendarGatewayException(
        'Conecte a Agenda do Google primeiro.',
      );
    }
    final token = await _accessToken(account);
    final start = from ?? DateTime.now().subtract(const Duration(days: 180));
    final end = to ?? DateTime.now().add(const Duration(days: 365));
    final events = <CalendarEvent>[];
    final removedEventIds = <String>[];
    String? pageToken;
    String? nextSyncToken;

    do {
      final query = <String, String>{
        'singleEvents': 'true',
        'showDeleted': 'true',
        'maxResults': '2500',
      };
      if (pageToken != null) query['pageToken'] = pageToken;
      if (syncToken != null) query['syncToken'] = syncToken;
      if (syncToken == null) {
        query.addAll({
          'timeMin': start.toUtc().toIso8601String(),
          'timeMax': end.toUtc().toIso8601String(),
          'orderBy': 'startTime',
        });
      }
      final response = await _get(
        Uri.https(
          'www.googleapis.com',
          '/calendar/v3/calendars/primary/events',
          query,
        ),
        token: token,
      );
      _throwForResponse(response);
      final decoded = _decodeJson(response.body);
      if (decoded is! Map) break;
      final items = decoded['items'];
      if (items is List) {
        for (final item in items.whereType<Map>()) {
          final id = item['id'] is String ? item['id'] as String : null;
          if (item['status'] == 'cancelled') {
            if (id != null && id.isNotEmpty) removedEventIds.add(id);
            continue;
          }
          final event = parseCalendarEvent(Map<String, dynamic>.from(item));
          if (event != null) events.add(event);
        }
      }
      pageToken = decoded['nextPageToken'] is String
          ? decoded['nextPageToken'] as String
          : null;
      if (decoded['nextSyncToken'] is String) {
        nextSyncToken = decoded['nextSyncToken'] as String;
      }
    } while (pageToken != null);

    return CalendarSyncResult(
      events: List.unmodifiable(events),
      removedEventIds: List.unmodifiable(removedEventIds),
      nextSyncToken: nextSyncToken,
      isIncremental: syncToken != null,
    );
  }

  @override
  Future<bool> requestWriteAccess() async {
    final account = _signIn.currentUser;
    if (account == null) {
      throw const CalendarGatewayException(
        'Conecte a Agenda do Google primeiro.',
      );
    }
    try {
      final granted = await _signIn.requestScopes([_calendarWriteScope]);
      if (!granted) {
        throw const CalendarGatewayException(
          'A permissão para criar e editar eventos não foi concedida.',
        );
      }
      await _accessToken(account);
      return true;
    } on CalendarGatewayException {
      rethrow;
    } catch (_) {
      throw const CalendarGatewayException(
        'Não foi possível solicitar a permissão de edição da Agenda.',
      );
    }
  }

  @override
  Future<CalendarEvent> createEvent(CalendarEvent event) async {
    await requestWriteAccess();
    final account = _signIn.currentUser;
    if (account == null) {
      throw const CalendarGatewayException(
        'Conecte a Agenda do Google primeiro.',
      );
    }
    final response = await _post(
      _eventsUri(event.calendarId, {'sendUpdates': 'none'}),
      token: await _accessToken(account),
      body: jsonEncode(calendarEventRequestBody(event)),
    );
    _throwForResponse(response, successCodes: const {200, 201});
    return _decodeEventResponse(response);
  }

  @override
  Future<CalendarEvent> updateEvent(CalendarEvent event) async {
    if (event.id == null || event.id!.isEmpty) {
      throw const CalendarGatewayException(
        'Este evento não possui um identificador do Google.',
      );
    }
    await requestWriteAccess();
    final account = _signIn.currentUser;
    if (account == null) {
      throw const CalendarGatewayException(
        'Conecte a Agenda do Google primeiro.',
      );
    }
    final headers = <String, String>{
      'Authorization': 'Bearer ${await _accessToken(account)}',
      'Content-Type': 'application/json',
      if (event.etag != null && event.etag!.isNotEmpty) 'If-Match': event.etag!,
    };
    final response = await _patch(
      _eventsUri(event.calendarId, {
        'sendUpdates': 'none',
        'eventId': event.id!,
      }),
      token: await _accessToken(account),
      extraHeaders: headers,
      body: jsonEncode(calendarEventRequestBody(event, includeId: false)),
    );
    _throwForResponse(response, successCodes: const {200});
    return _decodeEventResponse(response);
  }

  @override
  Future<void> deleteEvent(CalendarEvent event) async {
    if (event.id == null || event.id!.isEmpty) {
      throw const CalendarGatewayException(
        'Este evento não possui um identificador do Google.',
      );
    }
    await requestWriteAccess();
    final account = _signIn.currentUser;
    if (account == null) {
      throw const CalendarGatewayException(
        'Conecte a Agenda do Google primeiro.',
      );
    }
    final response = await _delete(
      _eventsUri(event.calendarId, {
        'sendUpdates': 'none',
        'eventId': event.id!,
      }),
      token: await _accessToken(account),
      extraHeaders: {
        if (event.etag != null && event.etag!.isNotEmpty)
          'If-Match': event.etag!,
      },
    );
    // A 404 means the event was already deleted elsewhere; making the local
    // cache converge is safer than leaving a phantom item behind.
    if (response.statusCode == 404) return;
    _throwForResponse(response, successCodes: const {200, 204});
  }

  Uri _eventsUri(String calendarId, Map<String, String> query) => Uri.https(
    'www.googleapis.com',
    '/calendar/v3/calendars/${Uri.encodeComponent(calendarId)}/events${query['eventId'] == null ? '' : '/${Uri.encodeComponent(query['eventId']!)}'}',
    Map<String, String>.from(query)..remove('eventId'),
  );

  CalendarEvent _decodeEventResponse(http.Response response) {
    final decoded = _decodeJson(response.body);
    if (decoded is! Map) {
      throw const CalendarGatewayException(
        'A Agenda retornou um evento inválido.',
      );
    }
    final event = parseCalendarEvent(Map<String, dynamic>.from(decoded));
    if (event == null) {
      throw const CalendarGatewayException(
        'A Agenda retornou um evento sem início ou fim.',
      );
    }
    return event;
  }

  Future<http.Response> _get(Uri uri, {required String token}) => _guarded(
    () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
  );

  Future<http.Response> _post(
    Uri uri, {
    required String token,
    required String body,
  }) => _guarded(
    () => _client.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    ),
  );

  Future<http.Response> _patch(
    Uri uri, {
    required String token,
    required Map<String, String> extraHeaders,
    required String body,
  }) => _guarded(
    () => _client.patch(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        ...extraHeaders,
      },
      body: body,
    ),
  );

  Future<http.Response> _delete(
    Uri uri, {
    required String token,
    Map<String, String> extraHeaders = const {},
  }) => _guarded(
    () => _client.delete(
      uri,
      headers: {'Authorization': 'Bearer $token', ...extraHeaders},
    ),
  );

  Future<http.Response> _guarded(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request();
    } catch (_) {
      throw const CalendarGatewayException(
        'Não foi possível acessar a Agenda. Verifique sua conexão e tente novamente.',
      );
    }
  }

  dynamic _decodeJson(String body) {
    try {
      return jsonDecode(body);
    } on FormatException {
      throw const CalendarGatewayException(
        'A Agenda retornou uma resposta inválida.',
      );
    }
  }

  void _throwForResponse(
    http.Response response, {
    Set<int> successCodes = const {200},
  }) {
    if (successCodes.contains(response.statusCode)) return;
    final message = switch (response.statusCode) {
      401 => 'A autorização do Google expirou. Conecte a Agenda novamente.',
      403 =>
        'O Google não permitiu esta operação. Confira as permissões da Agenda.',
      404 => 'O evento ou calendário não foi encontrado.',
      410 => 'O cache da Agenda expirou e precisa ser reconstruído.',
      412 => 'Este evento mudou no Google. Atualize a Agenda antes de salvar.',
      _ => 'A Agenda do Google respondeu com status ${response.statusCode}.',
    };
    throw CalendarGatewayException(message, statusCode: response.statusCode);
  }

  Future<String> _accessToken(GoogleSignInAccount account) async {
    final token = (await account.authentication).accessToken;
    if (token == null || token.isEmpty) {
      throw const CalendarGatewayException(
        'O Google não retornou um token de acesso válido.',
      );
    }
    return token;
  }
}

Map<String, dynamic> calendarEventRequestBody(
  CalendarEvent event, {
  bool includeId = true,
}) {
  if (event.title.trim().isEmpty) {
    throw const CalendarGatewayException('O evento precisa de um título.');
  }
  if (!event.end.isAfter(event.start)) {
    throw const CalendarGatewayException(
      'O fim do evento precisa ser depois do início.',
    );
  }
  return {
    if (includeId && event.id != null && event.id!.isNotEmpty) 'id': event.id,
    'summary': event.title.trim(),
    'description': event.description?.trim() ?? '',
    'start': _calendarDateBody(
      event.start,
      event.isAllDay,
      event.timeZone,
      !includeId,
    ),
    'end': _calendarDateBody(
      event.end,
      event.isAllDay,
      event.timeZone,
      !includeId,
    ),
    'colorId': event.colorId,
    'recurrence': event.recurrence,
    'reminders':
        event.reminderConfiguration ??
        {
          'useDefault': false,
          'overrides': [
            for (final minutes in event.reminderMinutes)
              {'method': 'popup', 'minutes': minutes},
          ],
        },
  };
}

Map<String, dynamic> _calendarDateBody(
  DateTime date,
  bool isAllDay,
  String timeZone,
  bool patch,
) {
  if (isAllDay) {
    return {
      'date': _dateOnly(date),
      if (patch) 'dateTime': null,
      if (patch) 'timeZone': null,
    };
  }
  return {
    'dateTime': date.toUtc().toIso8601String(),
    'timeZone': timeZone,
    if (patch) 'date': null,
  };
}

String _dateOnly(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

List<CalendarEvent> parseCalendarEvents(Map<String, dynamic> payload) {
  final items = payload['items'];
  if (items is! List) return const [];
  final events = <CalendarEvent>[];
  for (final item in items.whereType<Map>()) {
    final event = parseCalendarEvent(Map<String, dynamic>.from(item));
    if (event != null) events.add(event);
  }
  return List.unmodifiable(events);
}

CalendarEvent? parseCalendarEvent(Map<String, dynamic> item) {
  if (item['status'] == 'cancelled') return null;
  final start = _calendarDate(item['start']);
  final end = _calendarDate(item['end']);
  if (start == null || end == null) return null;
  final rawReminders = item['reminders'];
  final overrides = rawReminders is Map ? rawReminders['overrides'] : null;
  final reminderMinutes = overrides is List
      ? overrides
            .whereType<Map>()
            .map((item) => item['minutes'])
            .whereType<num>()
            .map((value) => value.toInt())
            .where((value) => value >= 0)
            .toList()
      : const <int>[];
  return CalendarEvent(
    reminderConfiguration: rawReminders is Map
        ? Map<String, dynamic>.from(rawReminders)
        : null,
    timeZone:
        item['start'] is Map && (item['start'] as Map)['timeZone'] is String
        ? (item['start'] as Map)['timeZone'] as String
        : 'America/Sao_Paulo',
    id: item['id'] is String ? item['id'] as String : null,
    calendarId: item['calendarId'] is String
        ? item['calendarId'] as String
        : 'primary',
    title:
        item['summary'] is String &&
            (item['summary'] as String).trim().isNotEmpty
        ? item['summary'] as String
        : 'Sem título',
    start: start.value,
    end: end.value,
    isAllDay: start.isAllDay,
    description: item['description'] is String
        ? item['description'] as String
        : null,
    colorId: item['colorId'] is String ? item['colorId'] as String : null,
    etag: item['etag'] is String ? item['etag'] as String : null,
    htmlLink: item['htmlLink'] is String ? item['htmlLink'] as String : null,
    recurrence: item['recurrence'] is List
        ? (item['recurrence'] as List).whereType<String>().toList()
        : const [],
    reminderMinutes: reminderMinutes,
  );
}

({DateTime value, bool isAllDay})? _calendarDate(Object? raw) {
  if (raw is! Map) return null;
  final dateTime = raw['dateTime'];
  if (dateTime is String) {
    final parsed = DateTime.tryParse(dateTime);
    if (parsed != null) return (value: parsed, isAllDay: false);
  }
  final date = raw['date'];
  if (date is String) {
    final parsed = DateTime.tryParse(date);
    if (parsed != null) return (value: parsed, isAllDay: true);
  }
  return null;
}
