import 'package:flutter/material.dart';
import 'lume_motion.dart';
import 'package:lume/core/theme/lume_theme.dart';
import 'package:lume/core/widgets/lume_card.dart';

class LumeQuickAction extends StatelessWidget {
  const LumeQuickAction({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.tone = LumeCardTone.neutral,
    this.isLoading = false,
    this.isEnabled = true,
    this.onPressed,
    this.semanticLabel,
  });

  final IconData icon;
  final String label;
  final String? value;
  final LumeCardTone tone;
  final bool isLoading;
  final bool isEnabled;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.lumeColors;
    final toneColor = switch (tone) {
      LumeCardTone.wellbeing => c.wellbeing,
      LumeCardTone.finance => c.finance,
      LumeCardTone.calendar => c.calendar,
      LumeCardTone.corner => c.brandSoft,
      LumeCardTone.danger => c.error.withValues(alpha: .10),
      LumeCardTone.neutral => c.surface,
    };
    final bg = tone == LumeCardTone.neutral
        ? c.surface
        : Color.alphaBlend(toneColor.withValues(alpha: .48), c.surface);
    final border = tone == LumeCardTone.neutral
        ? c.border
        : Color.alphaBlend(toneColor.withValues(alpha: .70), c.border);
    final semantic =
        semanticLabel ??
        [label, ?value, if (isLoading) 'Carregando'].join(', ');
    return Semantics(
      button: true,
      enabled: isEnabled && !isLoading,
      label: semantic,
      child: LumePressScale(
        enabled: isEnabled && !isLoading && onPressed != null,
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LumeRadii.control),
            side: BorderSide(color: border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isEnabled && !isLoading ? onPressed : null,
            borderRadius: BorderRadius.circular(LumeRadii.control),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: LumeSpacing.touchMinimum,
                minWidth: LumeSpacing.touchMinimum,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: LumeSpacing.md,
                  vertical: LumeSpacing.sm,
                ),
                child: isLoading
                    ? const Center(
                        child: SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 20),
                          const SizedBox(width: LumeSpacing.sm),
                          Flexible(
                            child: Text(
                              value == null ? label : '$label\n$value',
                              textAlign: TextAlign.start,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum LumeButtonVariant { primary, tonal, secondary, text, destructive, icon }

class LumeButton extends StatelessWidget {
  const LumeButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = LumeButtonVariant.primary,
    this.isLoading = false,
    this.isEnabled = true,
    this.leadingIcon,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final LumeButtonVariant variant;
  final bool isLoading;
  final bool isEnabled;
  final IconData? leadingIcon;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.lumeColors;
    final enabled = isEnabled && !isLoading && onPressed != null;
    final effectiveLabel = isLoading ? 'Salvando' : label;
    final icon = isLoading
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : (leadingIcon == null ? null : Icon(leadingIcon, size: 18));
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[icon, const SizedBox(width: LumeSpacing.sm)],
        if (variant != LumeButtonVariant.icon)
          Flexible(child: Text(effectiveLabel)),
      ],
    );
    final ButtonStyle style = switch (variant) {
      LumeButtonVariant.primary => FilledButton.styleFrom(
        backgroundColor: c.brand,
        foregroundColor: c.onBrand,
      ),
      LumeButtonVariant.tonal => FilledButton.styleFrom(
        backgroundColor: c.brandSoft,
        foregroundColor: c.onSoft,
      ),
      LumeButtonVariant.secondary => OutlinedButton.styleFrom(
        foregroundColor: c.brandStrong,
        side: BorderSide(color: c.brand),
      ),
      LumeButtonVariant.text => TextButton.styleFrom(
        foregroundColor: c.brandStrong,
      ),
      LumeButtonVariant.destructive => FilledButton.styleFrom(
        backgroundColor: c.error,
        foregroundColor: Colors.white,
      ),
      LumeButtonVariant.icon => IconButton.styleFrom(
        foregroundColor: c.brandStrong,
      ),
    };
    final button = switch (variant) {
      LumeButtonVariant.primary ||
      LumeButtonVariant.tonal ||
      LumeButtonVariant.destructive => FilledButton(
        onPressed: enabled ? onPressed : null,
        style: style,
        child: child,
      ),
      LumeButtonVariant.secondary => OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: style,
        child: child,
      ),
      LumeButtonVariant.text => TextButton(
        onPressed: enabled ? onPressed : null,
        style: style,
        child: child,
      ),
      LumeButtonVariant.icon => IconButton(
        onPressed: enabled ? onPressed : null,
        style: style,
        tooltip: semanticLabel ?? label,
        icon: icon ?? const Icon(Icons.circle),
      ),
    };
    return Semantics(
      button: true,
      enabled: isEnabled && !isLoading,
      label: semanticLabel ?? effectiveLabel,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: LumeSpacing.touchMinimum),
        child: button,
      ),
    );
  }
}
