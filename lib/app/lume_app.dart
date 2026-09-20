import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/auth/presentation/auth_screens.dart';
import '../features/calendar/presentation/calendar_screen.dart';
import '../features/corner/presentation/corner_screen.dart';
import '../features/finance/presentation/finance_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/today/presentation/today_screen.dart';
import '../features/wellbeing/presentation/wellbeing_screen.dart';
import 'app_controller.dart';
import 'app_route.dart';
export 'app_route.dart' show AppDestination;
import '../core/biometrics/biometric_gateway.dart';
import '../core/widgets/lume_motion.dart';
import '../core/widgets/lume_navigation.dart';
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
      child: MaterialApp(
        title: 'Lume',
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        debugShowCheckedModeBanner: false,
        theme: LumeTheme.light(),
        darkTheme: LumeTheme.dark(),
        themeMode: ThemeMode.system,
        home: const AppLaunchScreen(),
        onGenerateRoute: _routes,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: AppPrivacyShield(
            controller: controller,
            biometricGateway: biometricGateway,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Route<void>? _routes(RouteSettings settings) {
    final name = settings.name ?? '/welcome';
    final request = AppRouteRequest.parse(name);
    Widget page;
    if (request != null) {
      page = AppShell(
        initialDestination: request.destination,
        initialRoute: request,
      );
    } else {
      page = switch (name) {
        '/welcome' => const AppLaunchScreen(),
        '/auth/sign-in' => const AuthenticatedPage(
          child: AppShell(initialDestination: AppDestination.today),
        ),
        '/onboarding' => _onboardingPage(settings.arguments),
        '/app/settings' => const AuthenticatedPage(child: SettingsScreen()),
        '/app/settings/privacy' => const AuthenticatedPage(
          child: PrivacyScreen(),
        ),
        _ => const NotFoundScreen(),
      };
    }
    return MaterialPageRoute<void>(settings: settings, builder: (_) => page);
  }

  Widget _onboardingPage(Object? arguments) {
    final nextRoute = arguments is String ? arguments : '/app/today';
    final request = AppRouteRequest.parse(nextRoute);
    final child = request != null
        ? AppShell(
            initialDestination: request.destination,
            initialRoute: request,
          )
        : switch (nextRoute) {
            '/app/settings' => const SettingsScreen(),
            '/app/settings/privacy' => const PrivacyScreen(),
            _ => const NotFoundScreen(),
          };
    return AuthenticatedPage(child: child);
  }
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
  const AppShell({
    required this.initialDestination,
    this.initialRoute,
    super.key,
  });

  final AppDestination initialDestination;
  final AppRouteRequest? initialRoute;

  /// Internal shortcuts select a tab without stacking a second app shell.
  static void goTo(BuildContext context, AppDestination destination) {
    final shell = context.findAncestorStateOfType<_AppShellState>();
    if (shell != null) {
      shell._select(destination);
    } else {
      Navigator.of(context).pushNamed('/app/${destination.name}');
    }
  }

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  late AppDestination _destination = widget.initialDestination;
  bool _isConsumingSharedUrl = false;
  late final Set<AppDestination> _visited = {widget.initialDestination};

  void _select(AppDestination destination) {
    if (_destination == destination) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _visited.add(destination);
      _destination = destination;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _consumeSharedUrl());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _consumeSharedUrl();
    }
  }

  Future<void> _consumeSharedUrl() async {
    if (!mounted || _isConsumingSharedUrl) return;
    _isConsumingSharedUrl = true;
    try {
      final controller = AppScope.read(context);
      await controller.consumeSharedUrl();
      if (!mounted || controller.pendingSharedUrl == null) return;
      if (_destination != AppDestination.finance) {
        _select(AppDestination.finance);
      }
    } finally {
      _isConsumingSharedUrl = false;
    }
  }

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
    return Scaffold(
      body: IndexedStack(
        index: _destination.index,
        children: [
          for (final destination in AppDestination.values)
            if (_visited.contains(destination))
              TickerMode(
                enabled: destination == _destination,
                child: LumeTabStage(
                  active: destination == _destination,
                  child: switch (destination) {
                    AppDestination.today => const TodayScreen(),
                    AppDestination.calendar => CalendarScreen(
                      initialRoute: widget.initialRoute,
                    ),
                    AppDestination.wellbeing => WellbeingScreen(
                      initialRoute: widget.initialRoute,
                    ),
                    AppDestination.finance => FinanceScreen(
                      initialRoute: widget.initialRoute,
                    ),
                    AppDestination.corner => CornerScreen(
                      initialRoute: widget.initialRoute,
                    ),
                  },
                ),
              )
            else
              const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: LumeBottomNavigation(
        currentDestination: LumeDestination.values[_destination.index],
        onDestinationSelected: (destination) =>
            _select(AppDestination.values[destination.index]),
      ),
    );
  }
}

class AuthenticatedPage extends StatelessWidget {
  const AuthenticatedPage({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    if (!controller.isReady) return const SplashScreen();
    if (!controller.signedIn) return const SignInScreen();
    if (!controller.settings.onboardingComplete) {
      return const OnboardingScreen();
    }
    return child;
  }
}

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
