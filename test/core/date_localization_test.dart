import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lume/app/app_controller.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  test('formata datas em português depois do bootstrap local', () {
    final formatted = AppController().formatDate(DateTime(2026, 8, 24));
    expect(formatted, contains('agosto'));
  });
}
