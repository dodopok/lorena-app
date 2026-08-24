import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../../app/models.dart';

abstract interface class CalendarGateway {
  Future<void> connect();

  Future<void> disconnect();

  Future<List<CalendarEvent>> fetchEvents({DateTime? from, DateTime? to});
}

class LocalCalendarGateway implements CalendarGateway {
  const LocalCalendarGateway();

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<List<CalendarEvent>> fetchEvents({
    DateTime? from,
    DateTime? to,
  }) async => const [];
}

class CalendarGatewayException implements Exception {
  const CalendarGatewayException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GoogleCalendarGateway implements CalendarGateway {
  GoogleCalendarGateway({GoogleSignIn? signIn, http.Client? client})
    : _signIn =
          signIn ??
          GoogleSignIn(
            scopes: const ['https://www.googleapis.com/auth/calendar.readonly'],
          ),
      _client = client ?? http.Client();

  final GoogleSignIn _signIn;
  final http.Client _client;

  @override
  Future<void> connect() async {
    final account = await _signIn.signIn();
    if (account == null) {
      throw const CalendarGatewayException('Conexão com o Google cancelada.');
    }
    await _accessToken(account);
  }

  @override
  Future<void> disconnect() => _signIn.disconnect();

  @override
  Future<List<CalendarEvent>> fetchEvents({
    DateTime? from,
    DateTime? to,
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
    final uri = Uri.https(
      'www.googleapis.com',
      '/calendar/v3/calendars/primary/events',
      {
        'timeMin': start.toUtc().toIso8601String(),
        'timeMax': end.toUtc().toIso8601String(),
        'singleEvents': 'true',
        'orderBy': 'startTime',
        'maxResults': '100',
      },
    );
    final response = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 401) {
      throw const CalendarGatewayException(
        'A autorização do Google expirou. Conecte a Agenda novamente.',
      );
    }
    if (response.statusCode != 200) {
      throw CalendarGatewayException(
        'A Agenda do Google respondeu com status ${response.statusCode}.',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return const [];
    return parseCalendarEvents(decoded);
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

List<CalendarEvent> parseCalendarEvents(Map<String, dynamic> payload) {
  final items = payload['items'];
  if (items is! List) return const [];
  final events = <CalendarEvent>[];
  for (final item in items.whereType<Map>()) {
    final start = _calendarDate(item['start']);
    final end = _calendarDate(item['end']);
    if (start == null || end == null) continue;
    events.add(
      CalendarEvent(
        title:
            item['summary'] is String &&
                (item['summary'] as String).trim().isNotEmpty
            ? item['summary'] as String
            : 'Sem título',
        start: start.value,
        end: end.value,
        isAllDay: start.isAllDay,
      ),
    );
  }
  return List.unmodifiable(events);
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
