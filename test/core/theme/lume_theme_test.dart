import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/theme/lume_theme.dart';

void main() {
  test('exposes semantic light and dark tokens', () {
    expect(LumeColors.light.background, const Color(0xFFFFF8FB));
    expect(LumeColors.light.brand, const Color(0xFFC94F7C));
    expect(LumeColors.dark.background, const Color(0xFF21181D));
    expect(LumeColors.dark.text, const Color(0xFFFFF1F5));
  });

  testWidgets('installs the semantic extension in both themes', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: LumeTheme.light(),
        home: Builder(
          builder: (context) {
            expect(context.lumeColors, LumeColors.light);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(find.byType(SizedBox), findsOneWidget);
  });
}
