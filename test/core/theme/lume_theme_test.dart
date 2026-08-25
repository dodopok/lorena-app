import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/theme/lume_theme.dart';

void main() {
  test('exposes semantic light and dark tokens', () {
    expect(LumeColors.light.background, const Color(0xFFFAF8F7));
    expect(LumeColors.light.brand, const Color(0xFFA44266));
    expect(LumeColors.dark.background, const Color(0xFF1B1819));
    expect(LumeColors.dark.text, const Color(0xFFF7EFF1));
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
