import 'package:flutter/material.dart';
import 'package:lume/core/theme/lume_theme.dart';

enum LumeCardTone { neutral, wellbeing, finance, calendar, corner, danger }

class LumeCard extends StatelessWidget {
  const LumeCard({
    super.key,
    required this.child,
    this.tone = LumeCardTone.neutral,
    this.padding,
    this.semanticLabel,
    this.onTap,
    this.isEnabled = true,
  });

  final Widget child;
  final LumeCardTone tone;
  final EdgeInsetsGeometry? padding;
  final String? semanticLabel;
  final VoidCallback? onTap;
  final bool isEnabled;

  Color _toneColor(BuildContext context) {
    final c = context.lumeColors;
    return switch (tone) {
      LumeCardTone.neutral => c.surface,
      LumeCardTone.wellbeing => c.wellbeing,
      LumeCardTone.finance => c.finance,
      LumeCardTone.calendar => c.calendar,
      LumeCardTone.corner => c.brandSoft,
      LumeCardTone.danger => c.error.withValues(alpha: .10),
    };
  }

  Color _background(BuildContext context) {
    final c = context.lumeColors;
    final toneColor = _toneColor(context);
    return tone == LumeCardTone.neutral
        ? c.surface
        : Color.alphaBlend(toneColor.withValues(alpha: .52), c.surface);
  }

  Color _border(BuildContext context) {
    final c = context.lumeColors;
    final toneColor = _toneColor(context);
    return tone == LumeCardTone.neutral
        ? c.border
        : Color.alphaBlend(toneColor.withValues(alpha: .72), c.border);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = isEnabled && onTap != null;
    final content = Padding(
      padding: padding ?? const EdgeInsets.all(LumeSpacing.lg),
      child: child,
    );
    final card = Material(
      color: _background(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LumeRadii.card),
        side: BorderSide(color: _border(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(LumeRadii.card),
        child: content,
      ),
    );
    return SizedBox(
      width: double.infinity,
      child: Semantics(
        button: onTap != null,
        enabled: isEnabled,
        label: semanticLabel,
        child: Opacity(opacity: isEnabled ? 1 : .55, child: card),
      ),
    );
  }
}

class LumeSectionHeader extends StatelessWidget {
  const LumeSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.lumeColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: .1,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: LumeSpacing.xs),
                Text(
                  subtitle!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: c.textSecondary),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(44, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}
