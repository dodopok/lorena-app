import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class LocalStore {
  static const _snapshotKey = 'lume.snapshot.v1';
  static const _draftPrefix = 'lume.draft.v1.';
  Future<void> _draftQueue = Future<void>.value();
  Future<void> _snapshotQueue = Future<void>.value();

  String _ownerPrefix(String owner) =>
      '$_draftPrefix${Uri.encodeComponent(owner)}.';
  String _draftKey(String owner, String key) =>
      '${_ownerPrefix(owner)}${Uri.encodeComponent(key)}';

  Future<Map<String, dynamic>?> readDraft(String owner, String key) async {
    await _draftQueue;
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_draftKey(owner, key));
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } on FormatException {
      return null;
    }
  }

  // Capture the value before enqueueing: subsequent edits cannot change it.
  Future<void> writeDraft(
    String owner,
    String key,
    Map<String, dynamic>? value,
  ) {
    final encoded = value == null ? null : jsonEncode(value);
    return _enqueueDraft(() async {
      final preferences = await SharedPreferences.getInstance();
      final stored = encoded == null
          ? await preferences.remove(_draftKey(owner, key))
          : await preferences.setString(_draftKey(owner, key), encoded);
      if (!stored) throw StateError('Não foi possível guardar o rascunho.');
    });
  }

  Future<void> clearDrafts(String owner) => _enqueueDraft(() async {
    final preferences = await SharedPreferences.getInstance();
    for (final key in preferences.getKeys().where(
      (key) => key.startsWith(_ownerPrefix(owner)),
    )) {
      if (!await preferences.remove(key)) {
        throw StateError('Não foi possível remover o rascunho.');
      }
    }
  });

  Future<void> _enqueueDraft(Future<void> Function() operation) {
    final result = _draftQueue.then((_) => operation());
    _draftQueue = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return result;
  }

  Future<AppSnapshot?> read() async {
    await _snapshotQueue;
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_snapshotKey);
    if (encoded == null || encoded.isEmpty) return null;
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) return null;
      return AppSnapshot.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  Future<void> write(AppSnapshot snapshot) {
    final encoded = snapshot.encode();
    final result = _snapshotQueue.then((_) async {
      final preferences = await SharedPreferences.getInstance();
      if (!await preferences.setString(_snapshotKey, encoded)) {
        throw StateError('Não foi possível guardar seus registros.');
      }
    });
    _snapshotQueue = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return result;
  }

  Future<void> clear() async {
    await _snapshotQueue;
    final preferences = await SharedPreferences.getInstance();
    await _draftQueue;
    await preferences.remove(_snapshotKey);
    for (final key in preferences.getKeys().where(
      (key) => key.startsWith(_draftPrefix),
    )) {
      await preferences.remove(key);
    }
  }
}
