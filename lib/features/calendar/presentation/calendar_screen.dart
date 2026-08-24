import 'package:flutter/material.dart';

import '../../../app/environment.dart';
import '../../../app/lume_app.dart';
import '../../../app/models.dart';
import '../../../app/ui.dart' as app_ui;
import '../../../core/calendar/calendar_gateway.dart';
import '../../../core/widgets/lume_widgets.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final connected = controller.settings.calendarConnected;
    final integrationEnabled =
        LumeBuildConfig.enableCalendar &&
        LumeBuildConfig.googleCalendarIosClientId.isNotEmpty;
    return app_ui.LumePage(
      title: 'Agenda',
      subtitle: connected ? 'Conta Google conectada' : 'Uma conexão opcional',
      actions: connected && integrationEnabled
          ? [
              IconButton(
                tooltip: 'Atualizar Agenda',
                onPressed: _busy ? null : () => _refresh(context),
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
              ),
            ]
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!integrationEnabled)
            const LumeErrorState(
              title: 'Agenda em preparação',
              description:
                  'Ative a integração somente depois de criar o OAuth iOS da Agenda no projeto lume-app-506521 e passar o client ID por LUME_GOOGLE_IOS_CLIENT_ID.',
              errorKind: LumeErrorKind.permission,
            )
          else if (!connected)
            LumeCard(
              tone: LumeCardTone.calendar,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.calendar_month_outlined, size: 32),
                  const SizedBox(height: 14),
                  Text(
                    'Veja seus compromissos quando fizer sentido',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'A Agenda do Google é separada da conta do Lume. O acesso começa somente com leitura; a permissão de edição é pedida no primeiro evento criado ou alterado.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _connect(context),
                    icon: _busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.link),
                    label: Text(
                      _busy ? 'Conectando…' : 'Conectar Google Agenda',
                    ),
                  ),
                ],
              ),
            )
          else ...[
            LumeSyncIndicator(
              state: LumeSyncState.synced,
              updatedAt: controller.calendarLastSyncedAt,
            ),
            if (controller.calendarLastSyncedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Atualizada às ${_time(controller.calendarLastSyncedAt!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 10),
            LumeCard(
              tone: LumeCardTone.calendar,
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Calendário primário selecionado. O cache local continua visível sem internet.',
                    ),
                  ),
                  IconButton(
                    tooltip: 'Desconectar Agenda',
                    onPressed: _busy ? null : () => _disconnect(context),
                    icon: const Icon(Icons.link_off),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            LumeSectionHeader(
              title: 'Eventos',
              actionLabel: 'Novo evento',
              onAction: _busy ? null : () => _showEventForm(context),
            ),
            const SizedBox(height: 8),
            if (controller.calendarEvents.isEmpty)
              const LumeEmptyState(
                title: 'Nenhum evento neste cache',
                description:
                    'Atualize a Agenda para buscar os próximos compromissos. Eventos de dia inteiro continuam sem horário inventado.',
                illustration: Icon(Icons.event_available_outlined, size: 40),
              )
            else
              LumeCard(
                tone: LumeCardTone.calendar,
                child: Column(
                  children: controller.calendarEvents
                      .map((event) => _eventTile(context, event))
                      .toList(),
                ),
              ),
          ],
          const SizedBox(height: 24),
          LumeCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Eventos do Google ficam no Google. O Lume mantém apenas o cache local necessário para exibir a Agenda offline e não envia esses eventos para o Firebase.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventTile(BuildContext context, CalendarEvent event) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(
      event.isAllDay ? Icons.wb_sunny_outlined : Icons.event_outlined,
    ),
    title: Text(event.title),
    subtitle: Text(
      [
        event.isAllDay
            ? 'Dia inteiro · ${_date(event.start)}'
            : '${_date(event.start)} · ${_time(event.start)}–${_time(event.end)}',
        if (event.description != null && event.description!.trim().isNotEmpty)
          event.description!.trim(),
      ].join(' · '),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    ),
    trailing: PopupMenuButton<String>(
      tooltip: 'Ações do evento',
      onSelected: (value) {
        if (value == 'edit') _showEventForm(context, initial: event);
        if (value == 'delete') _deleteEvent(context, event);
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'edit', child: Text('Editar')),
        PopupMenuItem(value: 'delete', child: Text('Excluir')),
      ],
    ),
  );

  Future<void> _connect(BuildContext context) async {
    setState(() => _busy = true);
    try {
      await AppScope.read(context).connectCalendar();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agenda conectada e sincronizada.')),
      );
    } on CalendarGatewayException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refresh(BuildContext context) async {
    setState(() => _busy = true);
    try {
      await AppScope.read(context).refreshCalendar();
    } on CalendarGatewayException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnect(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desconectar Agenda?'),
        content: const Text(
          'Isso remove a autorização e o cache local da integração, sem apagar seus registros do Lume nem os eventos do Google.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Desconectar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    setState(() => _busy = true);
    try {
      await AppScope.read(context).disconnectCalendar();
    } on CalendarGatewayException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showEventForm(
    BuildContext context, {
    CalendarEvent? initial,
  }) async {
    final title = TextEditingController(text: initial?.title ?? '');
    final description = TextEditingController(text: initial?.description ?? '');
    var start = initial?.start ?? _nextHour();
    var end = initial?.end ?? start.add(const Duration(hours: 1));
    var isAllDay = initial?.isAllDay ?? false;
    var saving = false;
    final controller = AppScope.read(context);
    await app_ui.showLumeSheet(
      context,
      title: initial == null ? 'Novo evento' : 'Editar evento',
      child: StatefulBuilder(
        builder: (context, setSheetState) => Column(
          children: [
            TextField(
              controller: title,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: description,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dia inteiro'),
              value: isAllDay,
              onChanged: saving
                  ? null
                  : (value) => setSheetState(() => isAllDay = value),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: saving
                    ? null
                    : () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 730),
                          ),
                          initialDate: start,
                        );
                        if (picked == null || !context.mounted) return;
                        setSheetState(
                          () => start = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            start.hour,
                            start.minute,
                          ),
                        );
                        if (!isAllDay) {
                          setSheetState(
                            () => end = start.add(const Duration(hours: 1)),
                          );
                        }
                      },
                icon: const Icon(Icons.event_outlined),
                label: Text(_date(start)),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              alignment: Alignment.topCenter,
              child: isAllDay
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: saving
                                  ? null
                                  : () async {
                                      final picked = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.fromDateTime(
                                          start,
                                        ),
                                      );
                                      if (picked == null || !context.mounted) {
                                        return;
                                      }
                                      setSheetState(
                                        () => start = DateTime(
                                          start.year,
                                          start.month,
                                          start.day,
                                          picked.hour,
                                          picked.minute,
                                        ),
                                      );
                                      if (!end.isAfter(start)) {
                                        setSheetState(
                                          () => end = start.add(
                                            const Duration(hours: 1),
                                          ),
                                        );
                                      }
                                    },
                              child: Text('Início ${_time(start)}'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: saving
                                  ? null
                                  : () async {
                                      final picked = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.fromDateTime(
                                          end,
                                        ),
                                      );
                                      if (picked == null || !context.mounted) {
                                        return;
                                      }
                                      setSheetState(
                                        () => end = DateTime(
                                          end.year,
                                          end.month,
                                          end.day,
                                          picked.hour,
                                          picked.minute,
                                        ),
                                      );
                                    },
                              child: Text('Fim ${_time(end)}'),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (title.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Informe o título do evento.'),
                            ),
                          );
                          return;
                        }
                        final event =
                            (initial ??
                                    CalendarEvent(
                                      title: title.text,
                                      start: start,
                                      end: end,
                                    ))
                                .copyWith(
                                  title: title.text,
                                  start: start,
                                  end: isAllDay
                                      ? DateTime(
                                          start.year,
                                          start.month,
                                          start.day,
                                        ).add(const Duration(days: 1))
                                      : end,
                                  isAllDay: isAllDay,
                                  description: description.text,
                                  clearDescription: description.text
                                      .trim()
                                      .isEmpty,
                                );
                        if (!event.end.isAfter(event.start)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'O fim precisa ser depois do início.',
                              ),
                            ),
                          );
                          return;
                        }
                        setSheetState(() => saving = true);
                        try {
                          if (initial == null) {
                            await controller.createCalendarEvent(event);
                          } else {
                            await controller.updateCalendarEvent(event);
                          }
                          if (context.mounted) Navigator.pop(context);
                        } on CalendarGatewayException catch (error) {
                          if (!context.mounted) return;
                          setSheetState(() => saving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.message)),
                          );
                        }
                      },
                child: Text(
                  saving
                      ? 'Salvando…'
                      : initial == null
                      ? 'Criar evento'
                      : 'Salvar alterações',
                ),
              ),
            ),
          ],
        ),
      ),
    );
    title.dispose();
    description.dispose();
  }

  Future<void> _deleteEvent(BuildContext context, CalendarEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir evento?'),
        content: Text('“${event.title}” será removido da Agenda do Google.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    setState(() => _busy = true);
    try {
      await AppScope.read(context).deleteCalendarEvent(event);
    } on CalendarGatewayException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  DateTime _nextHour() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, now.hour + 1);
  }

  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _time(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
