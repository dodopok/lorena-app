import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lume/app/app_controller.dart';
import 'package:lume/app/lume_app.dart';
import 'package:lume/app/local_store.dart';
import 'package:lume/app/models.dart';
import 'package:lume/app/theme.dart';
import 'package:lume/core/photos/local_photo_service.dart';
import 'package:lume/features/gratitude/presentation/gratitude_editor.dart';

final _date = DateTime(2026, 9, 5);

Widget _host(AppController controller) => AppScope(
  controller: controller,
  child: MaterialApp(
    theme: LumeTheme.light(),
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showGratitudeEditor(context, date: _date),
          child: const Text('Abrir gratidão'),
        ),
      ),
    ),
  ),
);

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Abrir gratidão'));
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Guardar'));
  await tester.tap(find.text('Guardar'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('draft writes are ordered and isolated by account and date', () async {
    final store = LocalStore();
    final writes = [
      store.writeDraft('alice', 'gratitude:2026-09-05', {'text': 'a'}),
      store.writeDraft('alice', 'gratitude:2026-09-05', {'text': 'ab'}),
      store.writeDraft('bob', 'gratitude:2026-09-05', {'text': 'b'}),
      store.writeDraft('alice', 'gratitude:2026-09-04', {'text': 'ontem'}),
    ];
    await Future.wait(writes);
    expect(
      (await store.readDraft('alice', 'gratitude:2026-09-05'))?['text'],
      'ab',
    );
    await store.clearDrafts('alice');
    expect(await store.readDraft('alice', 'gratitude:2026-09-05'), isNull);
    expect(await store.readDraft('alice', 'gratitude:2026-09-04'), isNull);
    expect(
      (await store.readDraft('bob', 'gratitude:2026-09-05'))?['text'],
      'b',
    );
    await store.writeDraft('bob', 'gratitude:2026-09-05', null);
    expect(await LocalStore().readDraft('bob', 'gratitude:2026-09-05'), isNull);
  });

  testWidgets(
    'draft survives closing the editor and recreating the controller',
    (tester) async {
      final first = AppController()
        ..isReady = true
        ..signedIn = true;
      await tester.pumpWidget(_host(first));
      await _open(tester);
      await tester.enterText(
        find.byKey(const ValueKey('gratitude-text')),
        'Um café com uma amiga',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Fechar'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      first.dispose();
      final restored = AppController()
        ..isReady = true
        ..signedIn = true;
      await tester.pumpWidget(_host(restored));
      await _open(tester);
      expect(find.text('Um café com uma amiga'), findsOneWidget);
      expect(find.textContaining('Rascunho recuperado'), findsOneWidget);
      await _save(tester);
      expect(restored.gratitudeFor(_date).single.text, 'Um café com uma amiga');
      expect(await restored.readDraft('gratitude:2026-09-05'), isNull);
      await tester.pumpWidget(const SizedBox());
      restored.dispose();
    },
  );

  testWidgets(
    'editing text preserves the existing photo and allows photo-only entries',
    (tester) async {
      final photos = _Photos();
      final controller = AppController(photoService: photos)
        ..isReady = true
        ..signedIn = true;
      controller.gratitudeEntries = const [
        GratitudeEntry(
          localDate: '2026-09-05',
          text: 'Antes',
          localImagePath: '/tmp/lume-photo-fixture.jpg',
          remoteImagePaths: ['saved.jpg'],
        ),
      ];
      await tester.pumpWidget(_host(controller));
      await _open(tester);
      await tester.enterText(
        find.byKey(const ValueKey('gratitude-text')),
        'Depois',
      );
      await _save(tester);
      expect(
        controller.gratitudeFor(_date).single.localImagePath,
        '/tmp/lume-photo-fixture.jpg',
      );
      expect(controller.gratitudeFor(_date).single.remoteImagePaths, [
        'saved.jpg',
      ]);
      expect(photos.deleted, isEmpty);
      await _open(tester);
      await tester.enterText(find.byKey(const ValueKey('gratitude-text')), '');
      await _save(tester);
      expect(controller.gratitudeFor(_date).single.text, isEmpty);
      expect(controller.gratitudeFor(_date).single.localImagePath, isNotNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );

  testWidgets(
    'failed save keeps draft editable and never deletes the original photo',
    (tester) async {
      final store = _FailingStore();
      final photos = _Photos();
      final controller = AppController(store: store, photoService: photos)
        ..isReady = true
        ..signedIn = true;
      controller.gratitudeEntries = const [
        GratitudeEntry(
          localDate: '2026-09-05',
          text: 'Antes',
          localImagePath: '/tmp/lume-photo-fixture.jpg',
        ),
      ];
      await tester.pumpWidget(_host(controller));
      await _open(tester);
      await tester.tap(find.text('Remover foto'));
      await tester.enterText(
        find.byKey(const ValueKey('gratitude-text')),
        'Alteração',
      );
      await _save(tester);
      expect(find.textContaining('Não foi possível salvar'), findsOneWidget);
      expect(find.text('Alteração'), findsOneWidget);
      expect(controller.gratitudeFor(_date).single.text, 'Antes');
      expect(photos.deleted, isEmpty);
      store.fail = false;
      await _save(tester);
      expect(controller.gratitudeFor(_date).single.text, 'Alteração');
      expect(controller.gratitudeFor(_date).single.localImagePath, isNull);
      expect(photos.deleted, ['/tmp/lume-photo-fixture.jpg']);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );
}

class _Photos extends LocalPhotoService {
  final deleted = <String>[];
  @override
  Future<void> deleteStored(String path) async {
    deleted.add(path);
  }
}

class _FailingStore extends LocalStore {
  bool fail = true;
  @override
  Future<void> write(AppSnapshot snapshot) async {
    if (fail) throw StateError('Disk unavailable');
    await super.write(snapshot);
  }
}
