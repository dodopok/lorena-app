import 'package:flutter/material.dart';

import '../core/widgets/lume_motion.dart';
import 'theme.dart';
import '../core/theme/lume_theme.dart' show LumeThemeContext;

class LumePage extends StatelessWidget {
  const LumePage({
    required this.title,
    required this.child,
    this.subtitle,
    this.eyebrow,
    this.actions,
    this.showProfile = true,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 24),
    super.key,
  });

  final String title;
  final String? subtitle;
  final String? eyebrow;
  final Widget child;
  final List<Widget>? actions;
  final bool showProfile;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.lumeColors;
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        key: PageStorageKey('page-$title'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverAppBar(
            pinned: true,
            toolbarHeight: eyebrow == null ? 76 : 96,
            titleSpacing: 20,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null)
                  Text(
                    eyebrow!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
              ],
            ),
            actions: [
              if (actions != null) ...actions!,
              if (showProfile)
                IconButton(
                  tooltip: 'Abrir configurações',
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/app/settings'),
                  icon: CircleAvatar(
                    radius: 19,
                    backgroundColor: colors.brandSoft,
                    child: Icon(
                      Icons.person_outline,
                      size: 21,
                      color: colors.brandStrong,
                    ),
                  ),
                ),
              const SizedBox(width: 12),
            ],
          ),
          if (subtitle != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  subtitle!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
                ),
              ),
            ),
          SliverPadding(
            padding: padding,
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: child is LumeStaggeredColumn
                      ? child
                      : LumeReveal(child: child),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LumeCard extends StatelessWidget {
  const LumeCard({
    required this.child,
    this.color,
    this.onTap,
    this.padding,
    super.key,
  });

  final Widget child;
  final Color? color;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      color: color ?? Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(18),
        child: child,
      ),
    );
    if (onTap == null) return card;
    return Semantics(
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

class LumeSectionHeader extends StatelessWidget {
  const LumeSectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
      if (actionLabel != null && onAction != null)
        TextButton(onPressed: onAction, child: Text(actionLabel!)),
    ],
  );
}

class LumeEmptyState extends StatelessWidget {
  const LumeEmptyState({
    required this.icon,
    required this.title,
    required this.description,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      children: [
        Icon(icon, size: 40, color: LumeColors.brand),
        const SizedBox(height: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(description, textAlign: TextAlign.center),
        if (action != null) ...[
          const SizedBox(height: 16),
          FilledButton(onPressed: action, child: const Text('Começar')),
        ],
      ],
    ),
  );
}

class LumeProgress extends StatelessWidget {
  const LumeProgress({
    required this.value,
    required this.goal,
    required this.label,
    required this.unit,
    super.key,
  });

  final int value;
  final int goal;
  final String label;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final progress = goal <= 0 ? 0.0 : (value / goal).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              '$value $unit',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (goal > 0)
              Text(' / $goal', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 12),
        Semantics(
          label: '$label: $value $unit de $goal',
          value: '${(progress * 100).round()}%',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
              backgroundColor: LumeColors.brandSoft,
              color: LumeColors.brand,
            ),
          ),
        ),
      ],
    );
  }
}

class LumeQuickAction extends StatelessWidget {
  const LumeQuickAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.tone,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? tone;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: tone ?? LumeColors.brandSoft,
        foregroundColor: LumeColors.brandStrong,
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    ),
  );
}

Future<void> showLumeSheet(
  BuildContext context, {
  required String title,
  required Widget child,
}) {
  return _showLumeSheetAndSettle(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (context) => ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        body: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                child,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _showLumeSheetAndSettle({
  required BuildContext context,
  required bool isScrollControlled,
  required bool showDragHandle,
  required Color backgroundColor,
  required WidgetBuilder builder,
}) async {
  final navigator = Navigator.of(context);
  final localizations = MaterialLocalizations.of(context);
  final route = ModalBottomSheetRoute<void>(
    capturedThemes: InheritedTheme.capture(
      from: context,
      to: navigator.context,
    ),
    barrierLabel: localizations.scrimLabel,
    barrierOnTapHint: localizations.scrimOnTapHint(
      localizations.bottomSheetLabel,
    ),
    modalBarrierColor: Theme.of(context).bottomSheetTheme.modalBarrierColor,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
        ? AnimationStyle.noAnimation
        : null,
    showDragHandle: showDragHandle,
    backgroundColor: backgroundColor,
    builder: builder,
  );
  await navigator.push(route);
  // Editors can dispose their controllers only after the reverse transition
  // has removed every editable child, including with slower system animations.
  await route.completed;
}
