import 'package:flutter/material.dart';
import 'package:lume/core/theme/lume_theme.dart';
import 'package:lume/core/widgets/lume_navigation.dart';

class LumeScaffold extends StatelessWidget {
  const LumeScaffold({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.bottomNavigation,
    this.safeArea = true,
    this.scrollable = false,
    this.onBack,
  });

  final String? title;
  final Widget child;
  final List<Widget>? actions;
  final LumeBottomNavigation? bottomNavigation;
  final bool safeArea;
  final bool scrollable;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    Widget body = scrollable ? SingleChildScrollView(child: child) : child;
    if (safeArea) body = SafeArea(child: body);
    return Scaffold(
      backgroundColor: context.lumeColors.background,
      appBar: title == null && actions == null && onBack == null
          ? null
          : AppBar(
              title: title == null ? null : Text(title!),
              leading: onBack == null
                  ? null
                  : IconButton(
                      onPressed: onBack,
                      tooltip: 'Voltar',
                      icon: const Icon(Icons.arrow_back),
                    ),
              actions: actions,
            ),
      body: body,
      bottomNavigationBar: bottomNavigation,
    );
  }
}
