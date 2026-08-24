import 'package:flutter/material.dart';
import 'package:lume/core/theme/lume_theme.dart';

enum LumeSyncState { synced, pending, offline, conflict, unavailable }

class LumeSyncIndicator extends StatelessWidget {
  const LumeSyncIndicator({
    super.key,
    required this.state,
    this.updatedAt,
    this.onTap,
  });
  final LumeSyncState state;
  final DateTime? updatedAt;
  final VoidCallback? onTap;

  String get _text => switch (state) {
    LumeSyncState.synced => 'Sincronizado',
    LumeSyncState.pending =>
      'Salvo neste aparelho; sincronizando quando houver conexão',
    LumeSyncState.offline =>
      'Sem conexão. Mostrando dados salvos${updatedAt == null ? '' : ' em ${_date(updatedAt!)}'}',
    LumeSyncState.conflict => 'Este item mudou fora do app. Revisar',
    LumeSyncState.unavailable => 'Sincronização indisponível',
  };

  IconData get _icon => switch (state) {
    LumeSyncState.synced => Icons.cloud_done_outlined,
    LumeSyncState.pending => Icons.cloud_upload_outlined,
    LumeSyncState.offline => Icons.cloud_off_outlined,
    LumeSyncState.conflict => Icons.sync_problem_outlined,
    LumeSyncState.unavailable => Icons.cloud_outlined,
  };

  static String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    label: _text,
    liveRegion: state != LumeSyncState.synced,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(LumeRadii.pill),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LumeSpacing.sm,
          vertical: LumeSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 16, color: context.lumeColors.textSecondary),
            const SizedBox(width: LumeSpacing.xs),
            Flexible(
              child: Text(
                _text,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.lumeColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
