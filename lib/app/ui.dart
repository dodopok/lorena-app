import 'package:flutter/material.dart';

import '../core/widgets/lume_motion.dart';
import 'theme.dart';

class LumePage extends StatelessWidget {
  const LumePage({
    required this.title,
    required this.child,
    this.subtitle,
    this.actions,
    this.showProfile = true,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 24),
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;
  final bool showProfile;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            titleSpacing: 20,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: LumeColors.textSecondary,
                    ),
                  ),
              ],
            ),
            actions: [
              if (actions != null) ...actions!,
              if (showProfile)
                IconButton(
                  tooltip: 'Abrir configurações',
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/app/settings'),
                  icon: const CircleAvatar(
                    radius: 16,
                    backgroundColor: LumeColors.brandSoft,
                    child: Icon(
                      Icons.person_outline,
                      size: 18,
                      color: LumeColors.brandStrong,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
            ],
          ),
          SliverPadding(
            padding: padding,
            sliver: SliverToBoxAdapter(
              child: LumeReveal(child: LumeAnimatedContent(child: child)),
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

class LumeSyncBadge extends StatelessWidget {
  const LumeSyncBadge({required this.state, super.key});

  final SyncBadgeState state;

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (state) {
      SyncBadgeState.synced => (
        Icons.cloud_done_outlined,
        'Sincronizado',
        LumeColors.brandStrong,
      ),
      SyncBadgeState.pending => (
        Icons.cloud_upload_outlined,
        'Salvo neste aparelho; sincronizando',
        LumeColors.brandStrong,
      ),
      SyncBadgeState.offline => (
        Icons.cloud_off_outlined,
        'Sem conexão; mostrando dados salvos',
        LumeColors.textSecondary,
      ),
    };
    return Semantics(
      label: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

enum SyncBadgeState { synced, pending, offline }

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

const _lumeSheetDismissSettleDuration = Duration(milliseconds: 250);

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
    builder: (context) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            child,
          ],
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
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: isScrollControlled,
    showDragHandle: showDragHandle,
    backgroundColor: backgroundColor,
    builder: builder,
  );
  // showModalBottomSheet completes when the route is popped, before the
  // reverse animation has fully removed the sheet's editable children.
  await Future<void>.delayed(_lumeSheetDismissSettleDuration);
}
