import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/theme/lume_theme.dart';
import 'package:lume/core/widgets/lume_motion.dart';

Widget _host(Widget child, {bool disableAnimations = false}) => MaterialApp(
  theme: LumeTheme.light(),
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('reveal keeps the child bounds stable while it enters', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const LumeReveal(
          child: SizedBox(
            key: ValueKey('stable-child'),
            width: 220,
            height: 96,
          ),
        ),
      ),
    );
    final initialSize = tester.getSize(
      find.byKey(const ValueKey('stable-child')),
    );

    await tester.pump(const Duration(milliseconds: 180));
    expect(
      tester.getSize(find.byKey(const ValueKey('stable-child'))),
      initialSize,
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester.getSize(find.byKey(const ValueKey('stable-child'))),
      initialSize,
    );
  });

  testWidgets('motion is skipped when Reduce Motion is enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const LumeReveal(child: SizedBox(key: ValueKey('reduced-child'))),
        disableAnimations: true,
      ),
    );

    expect(find.byKey(const ValueKey('reduced-child')), findsOneWidget);
    expect(find.byKey(const ValueKey('lume-reveal-fade')), findsNothing);
  });

  testWidgets(
    'press feedback keeps bounds and skips scaling with Reduce Motion',
    (tester) async {
      for (final reduce in [false, true]) {
        await tester.pumpWidget(
          _host(
            const LumePressScale(
              child: SizedBox(
                width: 120,
                height: 48,
                child: ColoredBox(color: Colors.pink),
              ),
            ),
            disableAnimations: reduce,
          ),
        );
        final before = tester.getSize(find.byType(LumePressScale));
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(LumePressScale)),
        );
        await tester.pumpAndSettle();
        expect(
          tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
          reduce ? 1 : .975,
        );
        expect(tester.getSize(find.byType(LumePressScale)), before);
        await gesture.up();
        await tester.pumpAndSettle();
        expect(
          tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
          1,
        );
      }
    },
  );
}
