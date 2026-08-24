import 'package:flutter/material.dart';

import '../../../app/lume_app.dart';
import '../../../app/models.dart';
import '../../../app/ui.dart' as app_ui;
import '../../../core/widgets/lume_widgets.dart';

class WellbeingScreen extends StatelessWidget {
  const WellbeingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final now = DateTime.now();
    final water = controller.waterFor(now);
    final bowel = controller.bowelLogs
        .where((log) => log.localDate == controller.localDateFor(now))
        .toList();
    final exercise =
        controller.exerciseLogs
            .where((log) => log.localDate.startsWith(controller.periodFor(now)))
            .toList()
          ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    final waterTotal = water.fold(0, (total, item) => total + item.amountMl);
    final pending =
        water.any((item) => item.syncState == SyncState.pending) ||
        bowel.any((item) => item.syncState == SyncState.pending) ||
        exercise.any((item) => item.syncState == SyncState.pending);

    return app_ui.LumePage(
      title: 'Bem-estar',
      subtitle: 'Registros gentis, sem cobrança',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pending) ...[
            const LumeSyncIndicator(state: LumeSyncState.pending),
            const SizedBox(height: 12),
          ],
          LumeProgressCard(
            label: 'Água de hoje',
            value: waterTotal,
            max: controller.settings.waterGoalMl,
            unit: 'ml',
            tone: LumeCardTone.wellbeing,
            supportingText: 'Total derivado dos registros do dia.',
            action: 'Adicionar quantidade personalizada',
            onAction: () => _addCustomWater(context),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.settings.quickWaterAmountsMl
                .map(
                  (amount) => LumeQuickAction(
                    icon: Icons.water_drop_outlined,
                    label: '+$amount ml',
                    tone: LumeCardTone.wellbeing,
                    onPressed: () => _quickWater(context, amount),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          LumeSectionHeader(
            title: 'Registros de água',
            actionLabel: water.isEmpty ? null : 'Ver tudo',
            onAction: water.isEmpty ? null : () {},
          ),
          const SizedBox(height: 8),
          if (water.isEmpty)
            const LumeEmptyState(
              title: 'Ainda não há água registrada',
              description:
                  'Adicionar um copo agora já deixa o dia mais visível.',
              illustration: Icon(Icons.water_drop_outlined, size: 40),
            )
          else
            LumeCard(
              tone: LumeCardTone.wellbeing,
              child: Column(
                children: water
                    .take(8)
                    .map(
                      (log) => _WaterRow(
                        log: log,
                        onDelete: () => _deleteWater(context, log),
                      ),
                    )
                    .toList(),
              ),
            ),
          const SizedBox(height: 28),
          LumeSectionHeader(
            title: 'Evacuações',
            actionLabel: 'Registrar',
            onAction: () => _showBowel(context),
          ),
          const SizedBox(height: 8),
          if (bowel.isEmpty)
            const LumeCard(
              child: Text(
                'Nenhum registro hoje. Você pode registrar apenas o que fizer sentido para você.',
              ),
            )
          else
            LumeCard(
              child: Column(
                children: bowel.map((log) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule),
                    title: Text(controller.formatTime(log.occurredAt)),
                    subtitle: log.note == null ? null : Text(log.note!),
                    trailing: IconButton(
                      tooltip: 'Excluir registro',
                      onPressed: () => _deleteBowel(context, log),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 28),
          LumeSectionHeader(
            title: 'Exercícios',
            actionLabel: 'Novo exercício',
            onAction: () => _showExercise(context),
          ),
          const SizedBox(height: 8),
          LumeCard(
            tone: LumeCardTone.calendar,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${controller.exerciseMinutesForPeriod(controller.periodFor(now))} min neste mês',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                const Text('Dias sem registro não são tratados como falha.'),
                if (exercise.isNotEmpty) ...[
                  const Divider(height: 24),
                  ...exercise.take(6).map((log) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.directions_walk_outlined),
                      title: Text(log.activityType),
                      subtitle: Text(
                        '${log.durationMinutes} min · ${controller.formatDate(log.occurredAt)}',
                      ),
                      trailing: IconButton(
                        tooltip: 'Excluir sessão',
                        onPressed: () => _deleteExercise(context, log),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _quickWater(BuildContext context, int amount) async {
    final id = await AppScope.read(context).addWater(amount);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$amount ml adicionados.'),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () => AppScope.read(context).removeWater(id),
        ),
      ),
    );
  }

  Future<void> _addCustomWater(BuildContext context) async {
    final amount = TextEditingController();
    await app_ui.showLumeSheet(
      context,
      title: 'Adicionar água',
      child: Column(
        children: [
          TextField(
            controller: amount,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Quantidade',
              suffixText: 'ml',
              helperText: 'Informe um número inteiro positivo.',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                final value = int.tryParse(amount.text);
                if (value == null || value <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Informe uma quantidade positiva.'),
                    ),
                  );
                  return;
                }
                await AppScope.read(context).addWater(value);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Salvar'),
            ),
          ),
        ],
      ),
    );
    amount.dispose();
  }

  Future<void> _deleteWater(BuildContext context, WaterLog log) async {
    await AppScope.read(context).removeWater(log.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${log.amountMl} ml removidos.'),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () =>
              AppScope.read(context).addWater(log.amountMl, at: log.occurredAt),
        ),
      ),
    );
  }

  Future<void> _showBowel(BuildContext context) async {
    final note = TextEditingController();
    await app_ui.showLumeSheet(
      context,
      title: 'Registrar evacuação',
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('O horário atual será usado. Observação é opcional.'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: note,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Observação (opcional)',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                await AppScope.read(context).addBowel(note: note.text);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Salvar'),
            ),
          ),
        ],
      ),
    );
    note.dispose();
  }

  Future<void> _deleteBowel(BuildContext context, BowelLog log) async {
    final controller = AppScope.read(context);
    await controller.removeBowel(log.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Registro de ${controller.formatTime(log.occurredAt)} removido.',
        ),
      ),
    );
  }

  Future<void> _showExercise(BuildContext context) async {
    final type = TextEditingController(text: 'Caminhada');
    final duration = TextEditingController();
    final note = TextEditingController();
    await app_ui.showLumeSheet(
      context,
      title: 'Novo exercício',
      child: Column(
        children: [
          TextField(
            controller: type,
            decoration: const InputDecoration(labelText: 'Atividade'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: duration,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Duração',
              suffixText: 'minutos',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: note,
            decoration: const InputDecoration(
              labelText: 'Observação (opcional)',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                final minutes = int.tryParse(duration.text);
                if (minutes == null || minutes <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Informe uma duração positiva.'),
                    ),
                  );
                  return;
                }
                await AppScope.read(context).addExercise(
                  activityType: type.text,
                  durationMinutes: minutes,
                  note: note.text,
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Salvar'),
            ),
          ),
        ],
      ),
    );
    type.dispose();
    duration.dispose();
    note.dispose();
  }

  Future<void> _deleteExercise(BuildContext context, ExerciseLog log) async {
    final controller = AppScope.read(context);
    await controller.removeExercise(log.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${log.activityType} removido.')));
  }
}

class _WaterRow extends StatelessWidget {
  const _WaterRow({required this.log, required this.onDelete});

  final WaterLog log;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.water_drop_outlined),
    title: Text('${log.amountMl} ml'),
    subtitle: Text(
      '${log.occurredAt.hour.toString().padLeft(2, '0')}:${log.occurredAt.minute.toString().padLeft(2, '0')} · ${log.syncState == SyncState.pending ? 'pendente' : 'salvo'}',
    ),
    trailing: IconButton(
      tooltip: 'Excluir registro',
      onPressed: onDelete,
      icon: const Icon(Icons.delete_outline),
    ),
  );
}
