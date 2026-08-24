import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/models.dart';
import 'package:lume/core/export/export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('creates a portable zip without raw local or auth data', () async {
    final bundle =
        await ExportService(
          temporaryDirectoryProvider: () async => Directory.systemTemp,
        ).create(
          const AppSnapshot(
            signedIn: true,
            settings: UserSettings(),
            waterLogs: [],
            bowelLogs: [],
            exerciseLogs: [],
            transactions: [],
            gratitudeEntries: [],
            books: [],
            wishlistItems: [],
            shoppingItems: [],
          ),
          now: DateTime(2026, 8, 24, 12),
        );

    final file = File(bundle.path);
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final names = archive.files.map((item) => item.name).toSet();

    expect(bundle.fileName, 'lume-export-2026-08-24.zip');
    expect(
      names,
      containsAll(const [
        'profile.json',
        'water.csv',
        'bowel.csv',
        'exercise.csv',
        'finance/periods.csv',
        'finance/transactions.csv',
        'shopping/lists.json',
        'shopping/wishlist.csv',
        'books.json',
        'gratitude.json',
        'calendar.json',
      ]),
    );
    final profileFile = archive.files.firstWhere(
      (item) => item.name == 'profile.json',
    );
    final profile = utf8.decode(profileFile.content as List<int>);
    expect(profile, isNot(contains('token')));
    expect(profile, isNot(contains('/Users/')));

    await file.delete();
  });
}
