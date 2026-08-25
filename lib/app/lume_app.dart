import 'package:flutter/material.dart';

import '../features/auth/presentation/auth_screens.dart';
import '../features/calendar/presentation/calendar_screen.dart';
import '../features/corner/presentation/corner_screen.dart';
import '../features/finance/presentation/finance_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/today/presentation/today_screen.dart';
import '../features/wellbeing/presentation/wellbeing_screen.dart';
import 'app_controller.dart';
import '../core/biometrics/biometric_gateway.dart';
import '../core/widgets/lume_motion.dart';
import 'privacy_shield.dart';
import 'theme.dart';

class LumeApp extends StatelessWidget {
  const LumeApp({required this.controller, this.biometricGateway, super.key});

  final AppController controller;
  final BiometricGateway? biometricGateway;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      child: AppPrivacyShield(
        controller: controller,
        biometricGateway: biometricGateway,
        child: MaterialApp(
          title: 'Lume',
          debugShowCheckedModeBanner: false,
          theme: LumeTheme.light(),
          darkTheme: LumeTheme.dark(),
          themeMode: ThemeMode.system,
          home: const AppLaunchScreen(),
          onGenerateRoute: _routes,
        ),
      ),
    );
  }

  Route<void>? _routes(RouteSettings settings) {
    final name = settings.name ?? '/welcome';
    // Keep documented deep links on a safe authenticated destination even
    // before a dedicated route-state coordinator is added. The destination
    // screen remains the source of truth for validating the identifier.
    if (name.startsWith('/app/calendar/event/')) {
      return _page(
        const AppShell(initialDestination: AppDestination.calendar),
      );
    }
    if (name.startsWith('/app/finance/transaction/') ||
        name.startsWith('/app/finance/wishlist/')) {
      return _page(const AppShell(initialDestination: AppDestination.finance));
    }
    if (name.startsWith('/app/corner/books/') ||
        name.startsWith('/app/corner/gratitude/')) {
      return _page(const AppShell(initialDestination: AppDestination.corner));
    }
    switch (name) {
      case '/welcome':
        return _page(const WelcomeScreen());
      case '/auth/sign-in':
        return _page(const SignInScreen());
      case '/onboarding':
        return _page(const OnboardingScreen());
      case '/app':
      case '/app/today':
        return _page(const AppShell(initialDestination: AppDestination.today));
      case '/app/calendar':
        return _page(
          const AppShell(initialDestination: AppDestination.calendar),
        );
      case '/app/calendar/connect':
        return _page(
          const AppShell(initialDestination: AppDestination.calendar),
        );
      case '/app/wellbeing':
        return _page(
          const AppShell(initialDestination: AppDestination.wellbeing),
        );
      case '/app/finance':
        return _page(
          const AppShell(initialDestination: AppDestination.finance),
        );
      case '/app/corner':
        return _page(const AppShell(initialDestination: AppDestination.corner));
      case '/app/settings':
        return _page(const SettingsScreen());
      case '/app/settings/privacy':
        return _page(const PrivacyScreen());
      case '/app/wellbeing/water/new':
      case '/app/wellbeing/bowel/new':
      case '/app/wellbeing/exercise/new':
        return _page(
          const AppShell(initialDestination: AppDestination.wellbeing),
        );
      case '/app/finance/transaction/new':
      case '/app/finance/shopping/default':
      case '/app/finance/wishlist':
      case '/app/finance/wishlist/new':
        return _page(
          const AppShell(initialDestination: AppDestination.finance),
        );
      case '/app/corner/books':
      case '/app/corner/books/new':
      case '/app/corner/gratitude':
        return _page(const AppShell(initialDestination: AppDestination.corner));
      default:
        return _page(const NotFoundScreen());
    }
  }

  MaterialPageRoute<void> _page(Widget child) =>
      MaterialPageRoute<void>(builder: (_) => child);
}

class AppLaunchScreen extends StatelessWidget {
  const AppLaunchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    if (!controller.isReady) {
      return const SplashScreen();
    }
    if (!controller.signedIn) {
      return const WelcomeScreen();
    }
    if (!controller.settings.onboardingComplete) {
      return const OnboardingScreen();
    }
    return const AppShell(initialDestination: AppDestination.today);
  }
}

class AppScope extends InheritedNotifier<AppController> {
  const AppScope({required this.controller, required super.child, super.key})
    : super(notifier: controller);

  final AppController controller;

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope não encontrado na árvore');
    return scope!.controller;
  }

  static AppController read(BuildContext context) {
    final element = context.getElementForInheritedWidgetOfExactType<AppScope>();
    final scope = element?.widget as AppScope?;
    assert(scope != null, 'AppScope não encontrado na árvore');
    return scope!.controller;
  }
}

class AppShell extends StatefulWidget {
  const AppShell({required this.initialDestination, super.key});

  final AppDestination initialDestination;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late AppDestination _destination = widget.initialDestination;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    if (!controller.isReady) return const SplashScreen();
    if (!controller.signedIn) {
      return const SignInScreen();
    }
    if (!controller.settings.onboardingComplete) {
      return const OnboardingScreen();
    }
    final page = switch (_destination) {
      AppDestination.today => const TodayScreen(),
      AppDestination.calendar => const CalendarScreen(),
      AppDestination.wellbeing => const WellbeingScreen(),
      AppDestination.finance => const FinanceScreen(),
      AppDestination.corner => const CornerScreen(),
    };
    final motionDuration = lumeMotionDuration(
      context,
      const Duration(milliseconds: 280),
    );
    final reverseMotionDuration = lumeMotionDuration(
      context,
      const Duration(milliseconds: 180),
    );
    return Scaffold(
      body: ClipRect(
        child: AnimatedSwitcher(
          duration: motionDuration,
          reverseDuration: reverseMotionDuration,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (currentChild, previousChildren) => Stack(
            fit: StackFit.expand,
            children: <Widget>[...previousChildren, ?currentChild],
          ),
          transitionBuilder: lumePageTransition,
          child: KeyedSubtree(key: ValueKey(_destination), child: page),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _destination.index,
        onDestinationSelected: (index) {
          setState(() => _destination = AppDestination.values[index]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Hoje',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Icon(Icons.spa_outlined),
            selectedIcon: Icon(Icons.spa),
            label: 'Bem-estar',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Finanças',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories),
            label: 'Cantinho',
          ),
        ],
      ),
    );
  }
}

enum AppDestination { today, calendar, wellbeing, finance, corner }

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: LumeReveal(
        child: Semantics(
          label: 'Carregando Lume',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.wb_sunny_outlined,
                  size: 36,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 20),
              const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Página não encontrada')),
    body: Center(
      child: FilledButton(
        onPressed: () => Navigator.of(context).pushReplacementNamed('/app'),
        child: const Text('Voltar para Hoje'),
      ),
    ),
  );
}
