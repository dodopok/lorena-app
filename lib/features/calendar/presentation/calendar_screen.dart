import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/environment.dart';
import '../../../app/lume_app.dart';
import '../../../app/models.dart';
import '../../../app/ui.dart' as app_ui;
import '../../../core/calendar/calendar_gateway.dart';
import '../../../core/theme/lume_theme.dart';
import '../../../core/widgets/lume_widgets.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  bool _busy = false;
  CalendarView _view = CalendarView.day;
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final connected = controller.settings.calendarConnected;
    final integrationEnabled =
        LumeBuildConfig.enableCalendar &&
        LumeBuildConfig.googleCalendarIosClientId.isNotEmpty;
    final periodStart = _view == CalendarView.month
        ? DateTime(_selectedDate.year, _selectedDate.month)
        : DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final periodEnd = _view == CalendarView.month
        ? DateTime(_selectedDate.year, _selectedDate.month + 1)
        : periodStart.add(const Duration(days: 1));
    final visibleEvents = controller.calendarEvents.where((event) {
      return event.start.isBefore(periodEnd) && event.end.isAfter(periodStart);
    }).toList()..sort(_compareEvents);
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
              IconButton(
                tooltip: 'Desconectar Agenda',
                onPressed: _busy ? null : () => _disconnect(context),
                icon: const Icon(Icons.link_off),
              ),
            ]
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!integrationEnabled)
            LumeCard(
              tone: LumeCardTone.calendar,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.calendar_month_outlined, size: 32),
                  const SizedBox(height: 14),
                  Text(
                    'Agenda desativada',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Este build está sem a integração do Google Agenda. Ative LUME_ENABLE_CALENDAR para disponibilizar a conexão.',
                  ),
                ],
              ),
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
            _CalendarNavigator(
              view: _view,
              selectedDate: _selectedDate,
              onViewChanged: (view) => setState(() => _view = view),
              onPrevious: () => setState(() {
                _selectedDate = _view == CalendarView.month
                    ? DateTime(_selectedDate.year, _selectedDate.month - 1, 1)
                    : _selectedDate.subtract(const Duration(days: 1));
              }),
              onNext: () => setState(() {
                _selectedDate = _view == CalendarView.month
                    ? DateTime(_selectedDate.year, _selectedDate.month + 1, 1)
                    : _selectedDate.add(const Duration(days: 1));
              }),
            ),
            const SizedBox(height: 12),
            if (_view == CalendarView.month) ...[
              _MonthCalendar(
                month: _selectedDate,
                selectedDate: _selectedDate,
                events: controller.calendarEvents,
                eventColor: (colorId) => _eventDotColor(context, colorId),
                onDateSelected: (date) => setState(() => _selectedDate = date),
              ),
              const SizedBox(height: 24),
            ],
            LumeSectionHeader(
              title: _view == CalendarView.month
                  ? 'Eventos do mês'
                  : 'Agenda do dia',
              actionLabel: 'Novo evento',
              onAction: _busy ? null : () => _showEventForm(context),
            ),
            const SizedBox(height: 8),
            if (visibleEvents.isEmpty)
              LumeEmptyState(
                title: _view == CalendarView.month
                    ? 'Nenhum evento neste mês'
                    : 'Nenhum evento neste dia',
                description: controller.calendarEvents.isEmpty
                    ? 'Atualize a Agenda para buscar os próximos compromissos. Eventos de dia inteiro continuam sem horário inventado.'
                    : 'Use os controles acima para consultar outro período.',
                illustration: const Icon(
                  Icons.event_available_outlined,
                  size: 40,
                ),
              )
            else
              LumeCard(
                tone: LumeCardTone.calendar,
                child: Column(
                  children: visibleEvents
                      .map((event) => _eventTile(context, event))
                      .toList(),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _eventTile(BuildContext context, CalendarEvent event) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(
      event.isAllDay ? Icons.wb_sunny_outlined : Icons.event_outlined,
      color: _eventColor(context, event.colorId),
    ),
    title: Text(event.title),
    subtitle: Text(
      [
        event.isAllDay
            ? 'Dia inteiro · ${_date(event.start)}'
            : '${_date(event.start)} · ${_time(event.start)}–${_time(event.end)}',
        if (event.recurrence.isNotEmpty) 'Recorrente',
        if (event.reminderMinutes.isNotEmpty)
          'Lembrete ${event.reminderMinutes.first} min antes',
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
        if (value == 'open') _openEvent(context, event);
      },
      itemBuilder: (context) => [
        if (event.htmlLink != null && event.htmlLink!.isNotEmpty)
          const PopupMenuItem(
            value: 'open',
            child: Text('Abrir no Google Agenda'),
          ),
        const PopupMenuItem(value: 'edit', child: Text('Editar')),
        const PopupMenuItem(value: 'delete', child: Text('Excluir')),
      ],
    ),
  );

  Future<void> _openEvent(BuildContext context, CalendarEvent event) async {
    final rawLink = event.htmlLink;
    final link = rawLink == null ? null : Uri.tryParse(rawLink);
    if (link == null || (link.scheme != 'http' && link.scheme != 'https')) {
      return;
    }
    final opened = await launchUrl(link, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o evento.')),
      );
    }
  }

  Future<void> _connect(BuildContext context) async {
    setState(() => _busy = true);
    try {
      await AppScope.read(context).connectCalendar();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Agenda conectada.')));
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
    var recurrenceSelection = initial?.recurrence.firstOrNull ?? 'none';
    var reminderSelection = initial?.reminderMinutes.firstOrNull ?? 0;
    var colorSelection = initial?.colorId ?? 'default';
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
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: recurrenceSelection,
              decoration: const InputDecoration(labelText: 'Recorrência'),
              items: const [
                DropdownMenuItem(value: 'none', child: Text('Não repetir')),
                DropdownMenuItem(value: 'FREQ=DAILY', child: Text('Diário')),
                DropdownMenuItem(value: 'FREQ=WEEKLY', child: Text('Semanal')),
                DropdownMenuItem(value: 'FREQ=MONTHLY', child: Text('Mensal')),
              ],
              onChanged: saving
                  ? null
                  : (value) => setSheetState(
                      () => recurrenceSelection = value ?? 'none',
                    ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: reminderSelection,
              decoration: const InputDecoration(labelText: 'Lembrete'),
              items: const [
                DropdownMenuItem(value: 0, child: Text('Sem lembrete')),
                DropdownMenuItem(value: 10, child: Text('10 minutos antes')),
                DropdownMenuItem(value: 30, child: Text('30 minutos antes')),
                DropdownMenuItem(value: 60, child: Text('1 hora antes')),
              ],
              onChanged: saving
                  ? null
                  : (value) =>
                        setSheetState(() => reminderSelection = value ?? 0),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: colorSelection,
              decoration: const InputDecoration(labelText: 'Cor'),
              items: const [
                DropdownMenuItem(value: 'default', child: Text('Padrão')),
                DropdownMenuItem(value: '1', child: Text('Lavanda')),
                DropdownMenuItem(value: '2', child: Text('Menta')),
                DropdownMenuItem(value: '3', child: Text('Rosa')),
              ],
              onChanged: saving
                  ? null
                  : (value) => setSheetState(
                      () => colorSelection = value ?? 'default',
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
                                  recurrence: recurrenceSelection == 'none'
                                      ? const []
                                      : [recurrenceSelection],
                                  reminderMinutes: reminderSelection == 0
                                      ? const []
                                      : [reminderSelection],
                                  colorId: colorSelection == 'default'
                                      ? null
                                      : colorSelection,
                                  clearColorId: colorSelection == 'default',
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

  Color _eventColor(BuildContext context, String? colorId) => switch (colorId) {
    '1' => context.lumeColors.calendar,
    '2' => context.lumeColors.wellbeing,
    '3' => context.lumeColors.brandSoft,
    _ => Theme.of(context).colorScheme.primary,
  };

  Color _eventDotColor(BuildContext context, String? colorId) =>
      Color.lerp(_eventColor(context, colorId), context.lumeColors.text, 0.42)!;

  int _compareEvents(CalendarEvent first, CalendarEvent second) =>
      first.start.compareTo(second.start);
}

enum CalendarView { day, month }

class _CalendarNavigator extends StatelessWidget {
  const _CalendarNavigator({
    required this.view,
    required this.selectedDate,
    required this.onViewChanged,
    required this.onPrevious,
    required this.onNext,
  });

  final CalendarView view;
  final DateTime selectedDate;
  final ValueChanged<CalendarView> onViewChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SegmentedButton<CalendarView>(
        segments: const [
          ButtonSegment(
            value: CalendarView.day,
            label: Text('Dia'),
            icon: Icon(Icons.view_agenda_outlined),
          ),
          ButtonSegment(
            value: CalendarView.month,
            label: Text('Mês'),
            icon: Icon(Icons.calendar_view_month_outlined),
          ),
        ],
        selected: {view},
        onSelectionChanged: (selection) => onViewChanged(selection.first),
      ),
      Row(
        children: [
          IconButton(
            tooltip: 'Período anterior',
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Center(
              child: Text(
                view == CalendarView.month
                    ? '${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}'
                    : '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Próximo período',
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    ],
  );
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.month,
    required this.selectedDate,
    required this.events,
    required this.eventColor,
    required this.onDateSelected,
  });

  static const _weekdays = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];

  final DateTime month;
  final DateTime selectedDate;
  final List<CalendarEvent> events;
  final Color Function(String? colorId) eventColor;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final borderColor = context.lumeColors.border.withValues(alpha: 0.8);
    return LumeCard(
      tone: LumeCardTone.calendar,
      padding: const EdgeInsets.all(10),
      child: Table(
        border: TableBorder(
          horizontalInside: BorderSide(color: borderColor),
          verticalInside: BorderSide(color: borderColor),
        ),
        children: [
          TableRow(
            children: [
              for (final weekday in _weekdays)
                SizedBox(
                  height: 28,
                  child: Center(
                    child: Text(
                      weekday,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.lumeColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          for (final week in _weeks())
            TableRow(
              children: [for (final date in week) _dayCell(context, date)],
            ),
        ],
      ),
    );
  }

  List<List<DateTime?>> _weeks() {
    final firstDay = DateTime(month.year, month.month, 1);
    final leadingDays = firstDay.weekday - DateTime.monday;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final cells = <DateTime?>[
      ...List<DateTime?>.filled(leadingDays, null),
      for (var day = 1; day <= daysInMonth; day++)
        DateTime(month.year, month.month, day),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return [
      for (var index = 0; index < cells.length; index += 7)
        cells.sublist(index, index + 7),
    ];
  }

  Widget _dayCell(BuildContext context, DateTime? date) {
    if (date == null) return const SizedBox(height: 68);

    final dayEvents = _eventsForDay(date);
    final isSelected = _isSameDay(date, selectedDate);
    final isToday = _isSameDay(date, DateTime.now());
    final colors = context.lumeColors;
    final colorScheme = Theme.of(context).colorScheme;
    final numberDecoration = BoxDecoration(
      color: isSelected ? colorScheme.primary : Colors.transparent,
      shape: BoxShape.circle,
      border: isToday && !isSelected
          ? Border.all(color: colorScheme.primary, width: 1.5)
          : null,
    );

    return Semantics(
      button: true,
      label:
          '${date.day}/${date.month}/${date.year}, ${dayEvents.length} ${dayEvents.length == 1 ? 'evento' : 'eventos'}',
      child: InkWell(
        onTap: () => onDateSelected(date),
        child: SizedBox(
          height: 68,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 30,
                  height: 30,
                  decoration: numberDecoration,
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isSelected ? colorScheme.onPrimary : colors.text,
                        fontWeight: isToday || isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Wrap(
                      spacing: 3,
                      runSpacing: 3,
                      children: [
                        for (final event in dayEvents.take(4))
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: eventColor(event.colorId),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
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

  List<CalendarEvent> _eventsForDay(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return events
        .where((event) => event.start.isBefore(end) && event.end.isAfter(start))
        .toList()
      ..sort((first, second) => first.start.compareTo(second.start));
  }

  bool _isSameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
