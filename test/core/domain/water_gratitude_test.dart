import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/domain/domain.dart';

void main() {
  test('água soma somente os registros da data e calcula progresso', () {
    final logs = [
      WaterLog(
        id: 'a',
        userId: 'u1',
        amountMl: 300,
        occurredAt: DateTime.utc(2026, 8, 24),
        localDate: '2026-08-24',
        source: WaterSource.quickAction,
      ),
      WaterLog(
        id: 'b',
        userId: 'u1',
        amountMl: 500,
        occurredAt: DateTime.utc(2026, 8, 25),
        localDate: '2026-08-25',
        source: WaterSource.manual,
      ),
    ];
    expect(totalWaterForDate(logs, '2026-08-24'), 300);
    expect(waterProgress(600, 2000), 0.3);
  });

  test('gratidão exige texto ou imagem e mantém imagens imutáveis', () {
    final entry = GratitudeEntry(
      id: '2026-08-24',
      userId: 'u1',
      localDate: '2026-08-24',
      text: 'um dia tranquilo',
      images: ['local://photo'],
    );
    expect(entry.hasContent, isTrue);
    expect(() => entry.images.add('another'), throwsUnsupportedError);
    expect(
      () => GratitudeEntry(id: 'x', userId: 'u1', localDate: '2026-08-24'),
      throwsArgumentError,
    );
  });
}
