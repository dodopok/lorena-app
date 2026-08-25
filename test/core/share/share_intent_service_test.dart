import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/share/share_intent_service.dart';

void main() {
  test('aceita somente URLs http(s) com host', () {
    expect(
      ShareIntentService.validateUrl('https://loja.example/produto?id=42'),
      isNotNull,
    );
    expect(ShareIntentService.validateUrl('http://localhost/item'), isNotNull);
  });

  test('rejeita esquemas, host e credenciais inesperados', () {
    expect(ShareIntentService.validateUrl('lume://share'), isNull);
    expect(ShareIntentService.validateUrl('javascript:alert(1)'), isNull);
    expect(ShareIntentService.validateUrl('https:///sem-host'), isNull);
    expect(
      ShareIntentService.validateUrl('https://user:pass@loja.example'),
      isNull,
    );
    expect(ShareIntentService.validateUrl(null), isNull);
  });
}
