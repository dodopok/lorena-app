import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:lume/app/app_controller.dart';
import 'package:lume/app/local_store.dart';
import 'package:lume/app/lume_app.dart';
import 'package:lume/app/models.dart';
import 'package:lume/app/theme.dart';
import 'package:lume/core/auth/auth_gateway.dart';
import 'package:lume/features/auth/presentation/auth_screens.dart';
import 'package:lume/features/onboarding/presentation/onboarding_screen.dart';

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Future<void> _route(WidgetTester tester, String route) async {
  tester.state<NavigatorState>(find.byType(Navigator).first).pushNamed(route);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'completed steps survive restart and resume the requested editor',
    (tester) async {
      final first = AppController()
        ..isReady = true
        ..signedIn = true;
      await tester.pumpWidget(LumeApp(controller: first));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '2500');
      await _tap(tester, 'Continuar');
      await tester.enterText(find.byType(TextField).at(0), '125,00');
      await tester.enterText(find.byType(TextField).at(1), '15');
      await _tap(tester, 'Continuar');
      expect(find.text('Passo 3 de 3'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      first.dispose();

      final restored = AppController()
        ..isReady = true
        ..signedIn = true;
      await tester.pumpWidget(LumeApp(controller: restored));
      await tester.pumpAndSettle();
      await _route(tester, '/app/corner/books/new');
      expect(find.text('Passo 3 de 3'), findsOneWidget);
      await _tap(tester, 'Começar meu dia');
      expect(find.text('Adicionar livro'), findsWidgets);
      expect(find.byTooltip('Fechar'), findsOneWidget);
      expect(restored.settings.waterGoalMl, 2500);
      expect(restored.settings.allowanceAmountMinor, 12500);
      expect(restored.settings.allowanceDayOfMonth, 15);
      expect(restored.settings.onboardingComplete, isTrue);
      expect(await restored.readDraft('onboarding'), isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      restored.dispose();
    },
  );

  testWidgets(
    'failed final save keeps onboarding open and retry creates one allowance',
    (tester) async {
      final store = _FailingStore();
      await store.writeDraft('local', 'onboarding', {
        'step': 2,
        'water': '1800',
        'allowance': '50,00',
        'day': '12',
        'rollover': 'positiveOnly',
      });
      final controller = AppController(store: store)
        ..isReady = true
        ..signedIn = true;
      await tester.pumpWidget(LumeApp(controller: controller));
      await tester.pumpAndSettle();
      await _tap(tester, 'Começar meu dia');
      expect(
        find.textContaining('Não foi possível guardar suas preferências'),
        findsOneWidget,
      );
      expect(controller.settings.onboardingComplete, isFalse);
      expect(controller.transactions, isEmpty);
      store.fail = false;
      await _tap(tester, 'Começar meu dia');
      expect(controller.settings.onboardingComplete, isTrue);
      expect(controller.transactions.single.type, TransactionType.allowance);
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );

  testWidgets(
    'Apple cancellation stays on sign in; retry keeps the original destination',
    (tester) async {
      final auth = _Auth();
      final controller = AppController(authGateway: auth)
        ..isReady = true
        ..settings = const UserSettings(onboardingComplete: true);
      await tester.pumpWidget(LumeApp(controller: controller));
      await tester.pumpAndSettle();
      await _route(tester, '/app/corner/books/new');
      await _tap(tester, 'Continuar com Apple');
      expect(controller.signedIn, isFalse);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.text('Continuar com Apple'), findsOneWidget);
      auth.cancel = false;
      await _tap(tester, 'Continuar com Apple');
      expect(controller.signedIn, isTrue);
      expect(find.byTooltip('Fechar'), findsOneWidget);
      expect(find.text('Adicionar livro'), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );

  testWidgets(
    'sign in and onboarding remain scrollable with large text and keyboard',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = AppController()
        ..isReady = true
        ..signedIn = true;
      Widget host(Widget page) => AppScope(
        controller: controller,
        child: MaterialApp(
          theme: LumeTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.6),
              viewInsets: const EdgeInsets.only(bottom: 220),
            ),
            child: child!,
          ),
          home: page,
        ),
      );
      await tester.pumpWidget(host(const SignInScreen()));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Continuar neste aparelho'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(host(const OnboardingScreen()));
      await tester.pumpAndSettle();
      await _tap(tester, 'Continuar');
      expect(find.text('Passo 2 de 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Continuar'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );
}

class _FailingStore extends LocalStore {
  bool fail = true;
  @override
  Future<void> write(AppSnapshot snapshot) async {
    if (fail) throw StateError('Disk unavailable');
    await super.write(snapshot);
  }
}

class _Auth implements AuthGateway {
  bool cancel = true;
  bool active = false;
  @override
  String? get userId => active ? 'test-user' : null;
  @override
  Future<String?> getIdToken() async => null;
  @override
  Future<bool> hasSession() async => active;
  @override
  Future<void> signInWithApple() async {
    if (cancel) {
      throw const SignInWithAppleAuthorizationException(
        code: AuthorizationErrorCode.canceled,
        message: 'Canceled',
      );
    }
    active = true;
  }

  @override
  Future<void> reauthenticate() async {}
  @override
  Future<void> signOut() async {
    active = false;
  }

  @override
  Future<void> deleteAccount() async {
    active = false;
  }
}
