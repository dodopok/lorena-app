import 'package:flutter/material.dart';

import '../../../app/lume_app.dart';
import '../../../app/app_route.dart';
import '../../../app/models.dart';
import '../../../app/ui.dart' as app_ui;
import '../../../core/widgets/lume_widgets.dart';

class WellbeingScreen extends StatefulWidget {
  const WellbeingScreen({this.initialRoute, super.key});
  final AppRouteRequest? initialRoute;

  @override
  State<WellbeingScreen> createState() => _WellbeingScreenState();
}

class _WellbeingScreenState extends State<WellbeingScreen>
    with InitialRouteHandler<WellbeingScreen> {
  @override
  AppRouteRequest? get initialRoute => widget.initialRoute;

  @override
  Future<void> openInitialRoute(AppRouteRequest route) async {
    switch (route.action) {
      case AppRouteAction.waterNew:
        await _addCustomWater(context);
      case AppRouteAction.bowelNew:
        await _showBowel(context);
      case AppRouteAction.exerciseNew:
        await _showExercise(context);
      default:
        break;
    }
  }

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

    return app_ui.LumePage(
      title: 'Bem-estar',
      subtitle: 'Registros gentis, sem cobrança',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LumeProgressCard(
            label: 'Água de hoje',
            value: waterTotal,
            max: controller.settings.waterGoalMl,
            unit: 'ml',
            tone: LumeCardTone.wellbeing,
            supportingText: 'Cada copo é um pequeno cuidado com você.',
            action: 'Adicionar quantidade personalizada',
            onAction: () => _addCustomWater(context),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (
                var index = 0;
                index < controller.settings.quickWaterAmountsMl.take(3).length;
                index++
              ) ...[
                if (index > 0) const SizedBox(width: 8),
                Expanded(
                  child: LumeQuickAction(
                    icon: Icons.water_drop_outlined,
                    label:
                        '+${controller.settings.quickWaterAmountsMl[index]} ml',
                    semanticLabel:
                        'Adicionar ${controller.settings.quickWaterAmountsMl[index]} ml de água',
                    tone: LumeCardTone.wellbeing,
                    onPressed: () => _quickWater(
                      context,
                      controller.settings.quickWaterAmountsMl[index],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          LumeSectionHeader(
            title: 'Registros de água',
            actionLabel: controller.waterLogs.isEmpty ? null : 'Ver tudo',
            onAction: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _WaterHistoryScreen(onDelete: _deleteWater),
              ),
            ),
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
                    subtitle: Text(
                      [
                        if (log.bristolType != null)
                          'Escala ${log.bristolType}',
                        if (log.comfort != null) _comfortLabel(log.comfort!),
                        if (log.note != null && log.note!.isNotEmpty) log.note!,
                      ].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Ações do registro',
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showBowel(context, initial: log);
                        } else if (value == 'delete') {
                          _deleteBowel(context, log);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Editar')),
                        PopupMenuItem(value: 'delete', child: Text('Excluir')),
                      ],
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
                        [
                          '${log.durationMinutes} min',
                          controller.formatDate(log.occurredAt),
                          if (log.intensity != null)
                            _intensityLabel(log.intensity!),
                        ].join(' · '),
                      ),
                      trailing: PopupMenuButton<String>(
                        tooltip: 'Ações da sessão',
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showExercise(context, initial: log);
                          } else if (value == 'delete') {
                            _deleteExercise(context, log);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'edit', child: Text('Editar')),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Excluir'),
                          ),
                        ],
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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$amount ml adicionados.'),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () => AppScope.read(context).removeWater(id),
          ),
        ),
      );
  }

  Future<void> _addCustomWater(BuildContext context) => app_ui.showLumeSheet(
    context,
    title: 'Adicionar água',
    child: const _WaterEditor(),
  );

  Future<void> _deleteWater(BuildContext context, WaterLog log) async {
    final controller = AppScope.read(context);
    await controller.removeWater(log.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${log.amountMl} ml removidos.'),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () => controller.restoreWater(log),
        ),
      ),
    );
  }

  Future<void> _showBowel(BuildContext context, {BowelLog? initial}) async {
    final note = TextEditingController(text: initial?.note ?? '');
    var bristolType = initial?.bristolType;
    var comfort = initial?.comfort;
    var occurredAt = initial?.occurredAt ?? DateTime.now();
    var saving = false;
    final controller = AppScope.read(context);
    await app_ui.showLumeSheet(
      context,
      title: initial == null ? 'Registrar evacuação' : 'Editar evacuação',
      child: StatefulBuilder(
        builder: (context, setSheetState) => Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Classificações são opcionais e não representam diagnóstico.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: saving
                    ? null
                    : () async {
                        final date = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365),
                          ),
                          lastDate: DateTime.now(),
                          initialDate: occurredAt,
                        );
                        if (date == null || !context.mounted) return;
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(occurredAt),
                        );
                        if (time == null || !context.mounted) return;
                        setSheetState(
                          () => occurredAt = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          ),
                        );
                      },
                icon: const Icon(Icons.schedule_outlined),
                label: Text(
                  '${controller.formatDate(occurredAt)} · ${controller.formatTime(occurredAt)}',
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              isExpanded: true,
              itemHeight: null,
              initialValue: bristolType,
              decoration: const InputDecoration(
                labelText: 'Escala de Bristol (opcional)',
              ),
              items: [
                for (var value = 1; value <= 7; value++)
                  DropdownMenuItem(value: value, child: Text('$value')),
              ],
              onChanged: saving
                  ? null
                  : (value) => setSheetState(() => bristolType = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<BowelComfort>(
              isExpanded: true,
              itemHeight: null,
              initialValue: comfort,
              decoration: const InputDecoration(
                labelText: 'Conforto (opcional)',
              ),
              items: const [
                DropdownMenuItem(
                  value: BowelComfort.comfortable,
                  child: Text('Confortável'),
                ),
                DropdownMenuItem(
                  value: BowelComfort.neutral,
                  child: Text('Neutro'),
                ),
                DropdownMenuItem(
                  value: BowelComfort.uncomfortable,
                  child: Text('Desconfortável'),
                ),
              ],
              onChanged: saving
                  ? null
                  : (value) => setSheetState(() => comfort = value),
            ),
            const SizedBox(height: 12),
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
                onPressed: saving
                    ? null
                    : () async {
                        setSheetState(() => saving = true);
                        try {
                          if (initial == null) {
                            await controller.addBowel(
                              note: note.text,
                              bristolType: bristolType,
                              comfort: comfort,
                              at: occurredAt,
                            );
                          } else {
                            await controller.updateBowel(
                              id: initial.id,
                              at: occurredAt,
                              bristolType: bristolType,
                              comfort: comfort,
                              note: note.text,
                            );
                          }
                          if (context.mounted) Navigator.pop(context);
                        } on ArgumentError catch (error) {
                          if (!context.mounted) return;
                          setSheetState(() => saving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                error.message?.toString() ??
                                    'Confira os campos.',
                              ),
                            ),
                          );
                        }
                      },
                child: Text(saving ? 'Salvando…' : 'Salvar'),
              ),
            ),
          ],
        ),
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
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () => controller.restoreBowel(log),
        ),
      ),
    );
  }

  Future<void> _showExercise(
    BuildContext context, {
    ExerciseLog? initial,
  }) async {
    final type = TextEditingController(
      text: initial?.activityType ?? 'Caminhada',
    );
    final duration = TextEditingController(
      text: initial == null ? '' : '${initial.durationMinutes}',
    );
    final note = TextEditingController(text: initial?.note ?? '');
    var intensity = initial?.intensity;
    var occurredAt = initial?.occurredAt ?? DateTime.now();
    var saving = false;
    final controller = AppScope.read(context);
    await app_ui.showLumeSheet(
      context,
      title: initial == null ? 'Novo exercício' : 'Editar exercício',
      child: StatefulBuilder(
        builder: (context, setSheetState) => Column(
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
            DropdownButtonFormField<ExerciseIntensity>(
              isExpanded: true,
              itemHeight: null,
              initialValue: intensity,
              decoration: const InputDecoration(
                labelText: 'Intensidade (opcional)',
              ),
              items: const [
                DropdownMenuItem(
                  value: ExerciseIntensity.light,
                  child: Text('Leve'),
                ),
                DropdownMenuItem(
                  value: ExerciseIntensity.moderate,
                  child: Text('Moderada'),
                ),
                DropdownMenuItem(
                  value: ExerciseIntensity.intense,
                  child: Text('Intensa'),
                ),
              ],
              onChanged: saving
                  ? null
                  : (value) => setSheetState(() => intensity = value),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: saving
                    ? null
                    : () async {
                        final date = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365),
                          ),
                          lastDate: DateTime.now(),
                          initialDate: occurredAt,
                        );
                        if (date == null || !context.mounted) return;
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(occurredAt),
                        );
                        if (time == null || !context.mounted) return;
                        setSheetState(
                          () => occurredAt = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          ),
                        );
                      },
                icon: const Icon(Icons.schedule_outlined),
                label: Text(
                  '${controller.formatDate(occurredAt)} · ${controller.formatTime(occurredAt)}',
                ),
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
                onPressed: saving
                    ? null
                    : () async {
                        final minutes = int.tryParse(duration.text);
                        if (minutes == null || minutes <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Informe uma duração positiva.'),
                            ),
                          );
                          return;
                        }
                        setSheetState(() => saving = true);
                        try {
                          if (initial == null) {
                            await controller.addExercise(
                              activityType: type.text,
                              durationMinutes: minutes,
                              intensity: intensity,
                              note: note.text,
                              at: occurredAt,
                            );
                          } else {
                            await controller.updateExercise(
                              id: initial.id,
                              activityType: type.text,
                              durationMinutes: minutes,
                              at: occurredAt,
                              intensity: intensity,
                              note: note.text,
                            );
                          }
                          if (context.mounted) Navigator.pop(context);
                        } on ArgumentError catch (error) {
                          if (!context.mounted) return;
                          setSheetState(() => saving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                error.message?.toString() ??
                                    'Confira os campos.',
                              ),
                            ),
                          );
                        }
                      },
                child: Text(saving ? 'Salvando…' : 'Salvar'),
              ),
            ),
          ],
        ),
      ),
    );
    type.dispose();
    duration.dispose();
    note.dispose();
  }

  String _comfortLabel(BowelComfort comfort) => switch (comfort) {
    BowelComfort.comfortable => 'Confortável',
    BowelComfort.neutral => 'Neutro',
    BowelComfort.uncomfortable => 'Desconfortável',
  };

  String _intensityLabel(ExerciseIntensity intensity) => switch (intensity) {
    ExerciseIntensity.light => 'Leve',
    ExerciseIntensity.moderate => 'Moderada',
    ExerciseIntensity.intense => 'Intensa',
  };

  Future<void> _deleteExercise(BuildContext context, ExerciseLog log) async {
    final controller = AppScope.read(context);
    await controller.removeExercise(log.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${log.activityType} removido.'),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () => controller.restoreExercise(log),
        ),
      ),
    );
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
      '${log.occurredAt.hour.toString().padLeft(2, '0')}:${log.occurredAt.minute.toString().padLeft(2, '0')}',
    ),
    trailing: IconButton(
      tooltip: 'Excluir registro',
      onPressed: onDelete,
      icon: const Icon(Icons.delete_outline),
    ),
  );
}

class _WaterEditor extends StatefulWidget {
  const _WaterEditor();
  @override
  State<_WaterEditor> createState() => _WaterEditorState();
}

class _WaterEditorState extends State<_WaterEditor> {
  final _amount = TextEditingController();
  DateTime _at = DateTime.now();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final value = int.tryParse(_amount.text.trim());
    if (value == null || value <= 0) {
      setState(() => _error = 'Informe uma quantidade positiva em ml.');
      return;
    }
    if (_at.isAfter(DateTime.now())) {
      setState(() => _error = 'Escolha uma data e um horário que já passaram.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AppScope.read(context).addWater(value, at: _at);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error =
              'Não foi possível salvar. Seu registro está aqui para tentar novamente.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.read(context);
    return PopScope(
      canPop: !_saving,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _amount,
            enabled: !_saving,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Quantidade',
              suffixText: 'ml',
              helperText: 'Informe um número inteiro positivo.',
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.event_outlined),
            label: Text('Data: ${controller.formatDate(_at)} de ${_at.year}'),
            onPressed: _saving
                ? null
                : () async {
                    FocusScope.of(context).unfocus();
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _at,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date == null || !mounted) return;
                    setState(
                      () => _at = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        _at.hour,
                        _at.minute,
                      ),
                    );
                  },
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.schedule_outlined),
            label: Text('Horário: ${controller.formatTime(_at)}'),
            onPressed: _saving
                ? null
                : () async {
                    FocusScope.of(context).unfocus();
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_at),
                    );
                    if (time == null || !mounted) return;
                    setState(
                      () => _at = DateTime(
                        _at.year,
                        _at.month,
                        _at.day,
                        time.hour,
                        time.minute,
                      ),
                    );
                  },
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Salvando…' : 'Salvar'),
          ),
        ],
      ),
    );
  }
}

class _WaterHistoryScreen extends StatelessWidget {
  const _WaterHistoryScreen({required this.onDelete});
  final Future<void> Function(BuildContext, WaterLog) onDelete;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final logs = [...controller.waterLogs]
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    final totals = <String, int>{};
    for (final log in logs) {
      totals.update(
        log.localDate,
        (total) => total + log.amountMl,
        ifAbsent: () => log.amountMl,
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de água')),
      body: SafeArea(
        child: logs.isEmpty
            ? const LumeEmptyState(
                title: 'Seu histórico começa com um copo',
                description: 'Os próximos registros de água aparecerão aqui.',
                illustration: Icon(Icons.water_drop_outlined, size: 40),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                itemCount: logs.length,
                itemBuilder: (_, index) {
                  final log = logs[index];
                  final startsDay =
                      index == 0 || logs[index - 1].localDate != log.localDate;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (startsDay)
                        Padding(
                          padding: EdgeInsets.only(
                            top: index == 0 ? 8 : 24,
                            bottom: 12,
                          ),
                          child: LumeSectionHeader(
                            title: controller.formatDate(
                              DateTime.parse(log.localDate),
                            ),
                            subtitle: '${totals[log.localDate]} ml registrados',
                          ),
                        ),
                      _WaterRow(
                        log: log,
                        onDelete: () => onDelete(context, log),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
