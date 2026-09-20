import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_controller.dart';
import '../../gratitude/presentation/gratitude_editor.dart';
import '../../../app/lume_app.dart';
import '../../../app/models.dart';
import '../../../app/ui.dart' as app_ui;
import '../../../core/theme/lume_theme.dart';
import '../../../core/widgets/lume_widgets.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final now = DateTime.now();
    final waterTotal = controller.waterTotalFor(now);
    final gratitude = controller.gratitudeFor(now).firstOrNull;
    final currentPeriod = controller.periodFor(now);
    final nextEvent =
        controller.calendarEvents
            .where((event) => event.end.isAfter(now))
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));
    final upcomingEvent = nextEvent.firstOrNull;
    final greeting = now.hour < 12
        ? 'Bom dia'
        : now.hour < 18
        ? 'Boa tarde'
        : 'Boa noite';
    return app_ui.LumePage(
      title: 'Lorena',
      eyebrow: '$greeting,',
      subtitle: '${controller.formatDate(now)} · o dia é seu',
      child: LumeStaggeredColumn(
        children: [
          LumeCard(
            tone: LumeCardTone.calendar,
            semanticLabel: 'Próximo compromisso',
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: context.lumeColors.surface,
                  child: const Icon(Icons.event_outlined),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 68),
                    child: AnimatedSwitcher(
                      duration: lumeMotionDuration(
                        context,
                        const Duration(milliseconds: 220),
                      ),
                      layoutBuilder: (currentChild, previousChildren) => Stack(
                        alignment: Alignment.centerLeft,
                        children: <Widget>[...previousChildren, ?currentChild],
                      ),
                      child: _UpcomingEventCopy(
                        key: ValueKey(
                          upcomingEvent == null
                              ? controller.settings.calendarConnected
                              : '${upcomingEvent.id}:${upcomingEvent.start}',
                        ),
                        event: upcomingEvent,
                        connected: controller.settings.calendarConnected,
                        formatDate: controller.formatDate,
                        formatTime: controller.formatTime,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Abrir Agenda',
                  onPressed: () =>
                      AppShell.goTo(context, AppDestination.calendar),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          LumeProgressCard(
            label: 'Água de hoje',
            value: waterTotal,
            max: controller.settings.waterGoalMl,
            unit: 'ml',
            tone: LumeCardTone.wellbeing,
            supportingText: waterTotal >= controller.settings.waterGoalMl
                ? 'Meta alcançada. Seu ritmo está ótimo.'
                : 'Um copo a mais também conta.',
            action: 'Ver histórico',
            onAction: () => AppShell.goTo(context, AppDestination.wellbeing),
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
                    onPressed: () => _addWater(
                      context,
                      controller,
                      controller.settings.quickWaterAmountsMl[index],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          const LumeSectionHeader(title: 'Ações rápidas'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.self_improvement_outlined,
                  label: 'Evacuação',
                  color: context.lumeColors.wellbeing,
                  onTap: () => _showBowel(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionTile(
                  icon: Icons.directions_walk_outlined,
                  label: 'Exercício',
                  color: context.lumeColors.calendar,
                  onTap: () => _showExercise(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionTile(
                  icon: Icons.add_card_outlined,
                  label: 'Gasto',
                  color: context.lumeColors.finance,
                  onTap: () => _showExpense(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LumeMoneySummaryCard(
            periodLabel: _monthLabel(now),
            balanceMinor: controller.balanceFor(currentPeriod),
            currency: 'BRL',
            incomeMinor: controller.incomeFor(currentPeriod),
            expenseMinor: controller.expensesFor(currentPeriod),
            rolloverMinor: controller.rolloverFor(currentPeriod),
            onTap: () => AppShell.goTo(context, AppDestination.finance),
          ),
          const SizedBox(height: 24),
          const LumeSectionHeader(title: 'Gratidão de hoje'),
          const SizedBox(height: 10),
          ExcludeSemantics(
            child: Image.asset(
              'assets/images/lume-editorial-still-life.png',
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 12),
          LumeCard(
            tone: LumeCardTone.corner,
            onTap: () => showGratitudeEditor(context),
            child: gratitude == null
                ? const Row(
                    children: [
                      Icon(Icons.favorite_border),
                      SizedBox(width: 12),
                      Expanded(child: Text('Quer guardar algo bom de hoje?')),
                      Icon(Icons.add_circle_outline),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.favorite, color: context.lumeColors.brand),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          gratitude.text.isEmpty
                              ? 'Uma foto para lembrar de hoje'
                              : gratitude.text,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.edit_outlined, size: 20),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  String _monthLabel(DateTime date) => '${date.month}/${date.year}';

  String _shortDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  Future<void> _addWater(
    BuildContext context,
    AppController controller,
    int amount,
  ) async {
    final id = await controller.addWater(amount);
    if (!context.mounted) return;
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$amount ml adicionados.'),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () => controller.removeWater(id),
          ),
        ),
      );
  }

  Future<void> _showBowel(BuildContext context) async {
    final note = TextEditingController();
    int? bristolType;
    BowelComfort? comfort;
    var occurredAt = DateTime.now();
    var saving = false;
    final controller = AppScope.read(context);
    await app_ui.showLumeSheet(
      context,
      title: 'Registrar evacuação',
      child: StatefulBuilder(
        builder: (context, setSheetState) => Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Os detalhes são opcionais e não representam diagnóstico.',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
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
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
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
                          await controller.addBowel(
                            note: note.text,
                            bristolType: bristolType,
                            comfort: comfort,
                            at: occurredAt,
                          );
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

  Future<void> _showExercise(BuildContext context) async {
    final type = TextEditingController(text: 'Caminhada');
    final duration = TextEditingController();
    final note = TextEditingController();
    ExerciseIntensity? intensity;
    var occurredAt = DateTime.now();
    var saving = false;
    final controller = AppScope.read(context);
    await app_ui.showLumeSheet(
      context,
      title: 'Novo exercício',
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
            OutlinedButton.icon(
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
                          await controller.addExercise(
                            activityType: type.text,
                            durationMinutes: minutes,
                            intensity: intensity,
                            note: note.text,
                            at: occurredAt,
                          );
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

  Future<void> _showExpense(BuildContext context) async {
    final amount = TextEditingController();
    final description = TextEditingController();
    final category = TextEditingController(text: 'Outros');
    final note = TextEditingController();
    var occurredAt = DateTime.now();
    var saving = false;
    final controller = AppScope.read(context);
    await app_ui.showLumeSheet(
      context,
      title: 'Novo gasto',
      child: StatefulBuilder(
        builder: (context, setSheetState) => Column(
          children: [
            TextField(
              controller: amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Valor',
                prefixText: r'R$ ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: description,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: category,
              decoration: const InputDecoration(labelText: 'Categoria'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: saving
                  ? null
                  : () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        initialDate: occurredAt,
                      );
                      if (picked != null && context.mounted) {
                        setSheetState(
                          () => occurredAt = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            occurredAt.hour,
                            occurredAt.minute,
                          ),
                        );
                      }
                    },
              icon: const Icon(Icons.event_outlined),
              label: Text('Data: ${_shortDate(occurredAt)}'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              maxLines: 2,
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
                        final value = _parseMoney(amount.text);
                        if (value == null ||
                            value <= 0 ||
                            description.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Informe valor e descrição.'),
                            ),
                          );
                          return;
                        }
                        setSheetState(() => saving = true);
                        try {
                          await controller.addTransaction(
                            type: TransactionType.expense,
                            amountMinor: value,
                            category: category.text,
                            description: description.text,
                            at: occurredAt,
                            note: note.text,
                          );
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
                child: Text(saving ? 'Salvando…' : 'Salvar gasto'),
              ),
            ),
          ],
        ),
      ),
    );
    amount.dispose();
    description.dispose();
    category.dispose();
    note.dispose();
  }

  int? _parseMoney(String raw) {
    final normalized = raw.trim().replaceAll('.', '').replaceAll(',', '.');
    final value = double.tryParse(normalized);
    return value == null ? null : (value * 100).round();
  }
}

class _UpcomingEventCopy extends StatelessWidget {
  const _UpcomingEventCopy({
    super.key,
    required this.event,
    required this.connected,
    required this.formatDate,
    required this.formatTime,
  });

  final CalendarEvent? event;
  final bool connected;
  final String Function(DateTime) formatDate;
  final String Function(DateTime) formatTime;

  @override
  Widget build(BuildContext context) {
    final currentEvent = event;
    if (currentEvent == null) {
      return Column(
        key: const ValueKey('empty-event'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Próximo compromisso',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            connected
                ? 'Sem compromissos por enquanto. Um respiro no seu dia.'
                : 'Conecte a Agenda quando quiser visualizar seus eventos.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }
    final when = currentEvent.isAllDay
        ? 'Dia inteiro · ${formatDate(currentEvent.start)}'
        : '${formatDate(currentEvent.start)} · ${formatTime(currentEvent.start)}';
    return Column(
      key: ValueKey(currentEvent.id ?? currentEvent.title),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          currentEvent.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(when, maxLines: 2, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Material(
      color: Color.alphaBlend(
        color.withValues(alpha: .52),
        context.lumeColors.surface,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Color.alphaBlend(
            color.withValues(alpha: .72),
            context.lumeColors.border,
          ),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 96),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .58),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: context.lumeColors.brandStrong,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.lumeColors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
