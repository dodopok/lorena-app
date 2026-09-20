import 'package:flutter/material.dart';

enum AppDestination { today, calendar, wellbeing, finance, corner }

enum AppRouteAction {
  waterNew,
  bowelNew,
  exerciseNew,
  calendarConnect,
  eventNew,
  eventEdit,
  transactionNew,
  transactionEdit,
  shopping,
  wishlist,
  wishlistNew,
  wishlistEdit,
  books,
  bookNew,
  bookEdit,
  gratitude,
  gratitudeEdit,
}

@immutable
class AppRouteRequest {
  const AppRouteRequest({
    required this.location,
    required this.destination,
    this.action,
    this.id,
    this.income = false,
  });
  final String location;
  final AppDestination destination;
  final AppRouteAction? action;
  final String? id;
  final bool income;

  static AppRouteRequest? parse(String location) {
    try {
      final uri = Uri.parse(location);
      if (uri.hasScheme || uri.hasAuthority || uri.hasFragment) return null;
      final p = uri.pathSegments;
      if (p.isEmpty ||
          p.first != 'app' ||
          p.any((s) => s.isEmpty || s.contains('/') || s.contains('\u0000'))) {
        return null;
      }
      final destination = p.length == 1
          ? AppDestination.today
          : AppDestination.values.where((d) => d.name == p[1]).firstOrNull;
      if (destination == null) return null;
      if (p.length <= 2) {
        return AppRouteRequest(location: location, destination: destination);
      }
      final tail = p.skip(2).toList();
      AppRouteAction? action;
      String? id;
      switch ((destination, tail)) {
        case (AppDestination.wellbeing, ['water', 'new']):
          action = AppRouteAction.waterNew;
        case (AppDestination.wellbeing, ['bowel', 'new']):
          action = AppRouteAction.bowelNew;
        case (AppDestination.wellbeing, ['exercise', 'new']):
          action = AppRouteAction.exerciseNew;
        case (AppDestination.calendar, ['connect']):
          action = AppRouteAction.calendarConnect;
        case (AppDestination.calendar, ['event', 'new']):
          action = AppRouteAction.eventNew;
        case (AppDestination.calendar, ['event', final value, 'edit']):
          action = AppRouteAction.eventEdit;
          id = value;
        case (AppDestination.finance, ['transaction', 'new']):
          action = AppRouteAction.transactionNew;
        case (AppDestination.finance, ['transaction', final value, 'edit']):
          action = AppRouteAction.transactionEdit;
          id = value;
        case (AppDestination.finance, ['shopping', final value]):
          action = AppRouteAction.shopping;
          id = value;
        case (AppDestination.finance, ['wishlist']):
          action = AppRouteAction.wishlist;
        case (AppDestination.finance, ['wishlist', 'new']):
          action = AppRouteAction.wishlistNew;
        case (AppDestination.finance, ['wishlist', final value, 'edit']):
          action = AppRouteAction.wishlistEdit;
          id = value;
        case (AppDestination.corner, ['books']):
          action = AppRouteAction.books;
        case (AppDestination.corner, ['books', 'new']):
          action = AppRouteAction.bookNew;
        case (AppDestination.corner, ['books', final value, 'edit']):
          action = AppRouteAction.bookEdit;
          id = value;
        case (AppDestination.corner, ['gratitude']):
          action = AppRouteAction.gratitude;
        case (AppDestination.corner, ['gratitude', final value, 'edit']):
          final date = DateTime.tryParse(value);
          if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) ||
              date == null ||
              '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}' !=
                  value) {
            return null;
          }
          action = AppRouteAction.gratitudeEdit;
          id = value;
        default:
          return null;
      }
      return AppRouteRequest(
        location: location,
        destination: destination,
        action: action,
        id: id,
        income: uri.queryParameters['type'] == 'income',
      );
    } on FormatException {
      return null;
    }
  }
}

/// Route actions run once, after the authenticated destination has mounted.
mixin InitialRouteHandler<T extends StatefulWidget> on State<T> {
  AppRouteRequest? get initialRoute;
  Future<void> openInitialRoute(AppRouteRequest route);
  bool _routeOpened = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = initialRoute;
    if (_routeOpened || route?.action == null) return;
    _routeOpened = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await openInitialRoute(route!);
      } catch (_) {
        if (mounted) {
          routeMessage(
            'Não foi possível abrir agora. Volte e tente novamente.',
          );
        }
      }
    });
  }

  void routeMessage([
    String message =
        'Este registro não está disponível. Ele pode ter sido excluído.',
  ]) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
