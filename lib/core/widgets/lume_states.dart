import 'package:flutter/material.dart';
import 'package:lume/core/theme/lume_theme.dart';
import 'package:lume/core/widgets/lume_actions.dart';
import 'package:lume/core/widgets/lume_card.dart';

class LumeEmptyState extends StatelessWidget {
  const LumeEmptyState({
    super.key,
    this.illustration,
    required this.title,
    required this.description,
    this.primaryAction,
    this.secondaryAction,
  });
  final Widget? illustration;
  final String title;
  final String description;
  final Widget? primaryAction;
  final Widget? secondaryAction;
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: '$title. $description',
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(LumeSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (illustration != null) ...[
              illustration!,
              const SizedBox(height: LumeSpacing.xxl),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: LumeSpacing.sm),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.lumeColors.textSecondary,
              ),
            ),
            if (primaryAction != null) ...[
              const SizedBox(height: LumeSpacing.xxl),
              primaryAction!,
            ],
            if (secondaryAction != null) ...[
              const SizedBox(height: LumeSpacing.sm),
              secondaryAction!,
            ],
          ],
        ),
      ),
    ),
  );
}

enum LumeLoadingVariant { screen, card, row, button }

class LumeLoadingState extends StatelessWidget {
  const LumeLoadingState({
    super.key,
    this.variant = LumeLoadingVariant.screen,
    this.label = 'Carregando',
  });
  final LumeLoadingVariant variant;
  final String label;
  @override
  Widget build(BuildContext context) {
    final indicator = Semantics(
      label: label,
      liveRegion: true,
      child: const CircularProgressIndicator(),
    );
    return switch (variant) {
      LumeLoadingVariant.screen => Center(child: indicator),
      LumeLoadingVariant.card => LumeCardLoading(child: indicator),
      LumeLoadingVariant.row => SizedBox(
        height: LumeSpacing.touchMinimum,
        child: Align(alignment: Alignment.centerLeft, child: indicator),
      ),
      LumeLoadingVariant.button => SizedBox.square(
        dimension: 20,
        child: indicator,
      ),
    };
  }
}

class LumeCardLoading extends StatelessWidget {
  const LumeCardLoading({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => LumeCard(
    child: SizedBox(height: 72, child: Center(child: child)),
  );
}

enum LumeErrorKind { generic, offline, permission }

class LumeErrorState extends StatelessWidget {
  const LumeErrorState({
    super.key,
    required this.title,
    required this.description,
    this.errorKind = LumeErrorKind.generic,
    this.onRetry,
    this.onOpenSettings,
    this.isBlocking = false,
  });
  final String title;
  final String description;
  final LumeErrorKind errorKind;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenSettings;
  final bool isBlocking;
  @override
  Widget build(BuildContext context) {
    final icon = switch (errorKind) {
      LumeErrorKind.permission => Icons.lock_outline,
      LumeErrorKind.offline => Icons.cloud_off_outlined,
      LumeErrorKind.generic => Icons.info_outline,
    };
    return Semantics(
      container: true,
      label: '$title. $description',
      child: Padding(
        padding: const EdgeInsets.all(LumeSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: context.lumeColors.error),
            const SizedBox(height: LumeSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: LumeSpacing.sm),
            Text(description, textAlign: TextAlign.center),
            if (onRetry != null || onOpenSettings != null) ...[
              const SizedBox(height: LumeSpacing.lg),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: LumeSpacing.sm,
                children: [
                  if (onRetry != null)
                    LumeButton(label: 'Tentar novamente', onPressed: onRetry),
                  if (onOpenSettings != null)
                    LumeButton(
                      label: 'Abrir Ajustes',
                      variant: LumeButtonVariant.secondary,
                      onPressed: onOpenSettings,
                    ),
                ],
              ),
            ],
            if (isBlocking) const SizedBox(height: LumeSpacing.sm),
          ],
        ),
      ),
    );
  }
}
