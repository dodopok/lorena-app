import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/domain/domain.dart';

void main() {
  test('calcula último dia e ajusta dia da mesada em fevereiro', () {
    expect(DateRules.lastDayOfMonth('2024-02'), '2024-02-29');
    expect(DateRules.lastDayOfMonth('2025-02'), '2025-02-28');
    expect(DateRules.effectiveAllowanceDay('2025-02', 31), 28);
  });

  test('calcula competência e mês anterior sem usar double ou horário', () {
    expect(DateRules.periodOf('2026-08-24'), '2026-08');
    expect(DateRules.previousPeriod('2026-01'), '2025-12');
    expect(DateRules.firstDayOfMonth('2026-08'), '2026-08-01');
  });

  test('rejeita datas e competências inválidas', () {
    expect(() => DateRules.parseDate('2026-02-30'), throwsFormatException);
    expect(() => DateRules.parsePeriod('2026-13'), throwsFormatException);
  });
}
