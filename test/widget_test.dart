import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/app_controller.dart';
import 'package:lume/app/lume_app.dart';

void main() {
  testWidgets('mostra a proposta do Lume para uma sessão nova', (tester) async {
    final controller = AppController()..isReady = true;
    await tester.pumpWidget(LumeApp(controller: controller));

    expect(find.text('Lume'), findsOneWidget);
    expect(find.text('Começar'), findsOneWidget);
    expect(find.textContaining('pequenos passos'), findsOneWidget);
  });
}
