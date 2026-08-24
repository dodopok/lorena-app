import 'package:flutter/material.dart';
import 'package:lume/core/theme/lume_theme.dart';
import 'package:lume/core/widgets/lume_card.dart';
import 'package:lume/core/widgets/lume_motion.dart';

class LumeProgressCard extends StatelessWidget {
  const LumeProgressCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.max,
    this.supportingText,
    this.tone = LumeCardTone.wellbeing,
    this.status,
    this.action,
    this.onAction,
  });

  final String label;
  final num value;
  final num? max;
  final String unit;
  final String? supportingText;
  final LumeCardTone tone;
  final String? status;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final motionDuration = lumeMotionDuration(
      context,
      const Duration(milliseconds: 220),
    );
    final progressDuration = lumeMotionDuration(
      context,
      const Duration(milliseconds: 420),
    );
    final safeMax = max != null && max! > 0 ? max! : null;
    final fraction = safeMax == null
        ? 0.0
        : (value / safeMax).clamp(0.0, 1.0).toDouble();
    final text =
        '$label: $value $unit${safeMax == null ? '' : ', de $safeMax $unit'}${status == null ? '' : ', $status'}';
    return Semantics(
      label: text,
      container: true,
      child: LumeCard(
        tone: tone,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                SizedBox(
                  width: 104,
                  child: AnimatedSwitcher(
                    duration: motionDuration,
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    layoutBuilder: (currentChild, previousChildren) => Stack(
                      alignment: Alignment.centerRight,
                      children: <Widget>[...previousChildren, ?currentChild],
                    ),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, .15),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: Align(
                      key: ValueKey('$value $unit'),
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$value $unit',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (safeMax != null) ...[
              const SizedBox(height: LumeSpacing.md),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(end: fraction),
                duration: progressDuration,
                curve: Curves.easeOutCubic,
                builder: (context, animatedFraction, child) => ClipRRect(
                  borderRadius: BorderRadius.circular(LumeRadii.pill),
                  child: LinearProgressIndicator(
                    value: animatedFraction,
                    minHeight: 10,
                    backgroundColor: context.lumeColors.surface.withValues(
                      alpha: .7,
                    ),
                    color: context.lumeColors.brandStrong,
                  ),
                ),
              ),
            ],
            if (supportingText != null) ...[
              const SizedBox(height: LumeSpacing.sm),
              Text(
                supportingText!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.lumeColors.textSecondary,
                ),
              ),
            ],
            if (status != null) ...[
              const SizedBox(height: LumeSpacing.sm),
              Text(status!, style: Theme.of(context).textTheme.labelMedium),
            ],
            if (action != null && onAction != null) ...[
              const SizedBox(height: LumeSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(onPressed: onAction, child: Text(action!)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LumeMoneySummaryCard extends StatelessWidget {
  const LumeMoneySummaryCard({
    super.key,
    required this.periodLabel,
    required this.balanceMinor,
    required this.currency,
    this.incomeMinor,
    this.expenseMinor,
    this.rolloverMinor,
    this.tone = LumeCardTone.finance,
    this.onTap,
  });

  final String periodLabel;
  final int balanceMinor;
  final String currency;
  final int? incomeMinor;
  final int? expenseMinor;
  final int? rolloverMinor;
  final LumeCardTone tone;
  final VoidCallback? onTap;

  String _money(int minor) {
    final negative = minor < 0;
    final absolute = minor.abs();
    final whole = absolute ~/ 100;
    final cents = (absolute % 100).toString().padLeft(2, '0');
    final symbol = switch (currency.toUpperCase()) {
      'BRL' => r'R$',
      'USD' => r'$',
      'EUR' => '€',
      _ => currency,
    };
    final decimal =
        currency.toUpperCase() == 'BRL' || currency.toUpperCase() == 'EUR'
        ? ','
        : '.';
    return '${negative ? '-' : ''}$symbol $whole$decimal$cents';
  }

  @override
  Widget build(BuildContext context) {
    final negative = balanceMinor < 0;
    final details = <Widget>[];
    if (incomeMinor != null) {
      details.add(_Detail(label: 'Entradas', value: _money(incomeMinor!)));
    }
    if (expenseMinor != null) {
      details.add(_Detail(label: 'Saídas', value: _money(expenseMinor!)));
    }
    if (rolloverMinor != null) {
      details.add(_Detail(label: 'Acumulado', value: _money(rolloverMinor!)));
    }
    return Semantics(
      label:
          'Saldo de $periodLabel: ${_money(balanceMinor)}, moeda $currency${negative ? ', saldo negativo' : ''}',
      container: true,
      child: LumeCard(
        tone: tone,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saldo de $periodLabel',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: LumeSpacing.sm),
            Text(
              _money(balanceMinor),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: negative
                    ? context.lumeColors.error
                    : context.lumeColors.text,
              ),
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: LumeSpacing.lg),
              Wrap(
                spacing: LumeSpacing.xl,
                runSpacing: LumeSpacing.sm,
                children: details,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelSmall),
      Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    ],
  );
}
