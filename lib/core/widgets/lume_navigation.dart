import 'package:flutter/material.dart';
import 'package:lume/core/theme/lume_theme.dart';
import 'package:lume/core/widgets/lume_motion.dart';

enum LumeDestination { today, calendar, wellbeing, finance, corner }

class LumeBottomNavigation extends StatelessWidget {
  const LumeBottomNavigation({
    super.key,
    required this.currentDestination,
    required this.onDestinationSelected,
  });
  final LumeDestination currentDestination;
  final ValueChanged<LumeDestination> onDestinationSelected;

  static const _items = <(LumeDestination, String, IconData, String)>[
    (LumeDestination.today, 'Hoje', Icons.today_outlined, 'Hoje'),
    (
      LumeDestination.calendar,
      'Agenda',
      Icons.calendar_month_outlined,
      'Agenda',
    ),
    (LumeDestination.wellbeing, 'Bem-estar', Icons.spa_outlined, 'Bem-estar'),
    (
      LumeDestination.finance,
      'Finanças',
      Icons.account_balance_wallet_outlined,
      'Finanças',
    ),
    (
      LumeDestination.corner,
      'Cantinho',
      Icons.auto_stories_outlined,
      'Cantinho',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.lumeColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(4, 5, 4, 3),
        child: Row(
          children: [
            for (final item in _items)
              Expanded(
                child: _DestinationButton(
                  item: item,
                  selected: item.$1 == currentDestination,
                  onPressed: () {
                    if (item.$1 != currentDestination) {
                      onDestinationSelected(item.$1);
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DestinationButton extends StatelessWidget {
  const _DestinationButton({
    required this.item,
    required this.selected,
    required this.onPressed,
  });
  final (LumeDestination, String, IconData, String) item;
  final bool selected;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    final motionDuration = lumeMotionDuration(
      context,
      const Duration(milliseconds: 180),
    );
    return Semantics(
      button: true,
      selected: selected,
      container: true,
      excludeSemantics: true,
      label: '${item.$4}, aba${selected ? ' selecionada' : ''}',
      child: InkWell(
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 58),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 44,
                  height: 28,
                  child: AnimatedContainer(
                    duration: motionDuration,
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: selected
                          ? context.lumeColors.brandSoft
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(LumeRadii.pill),
                    ),
                    child: Icon(
                      item.$3,
                      color: selected
                          ? context.lumeColors.brand
                          : context.lumeColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                SizedBox(
                  height: 15,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.$2,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10.5,
                        color: selected
                            ? context.lumeColors.brand
                            : context.lumeColors.textSecondary,
                        fontWeight: selected ? FontWeight.w700 : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
