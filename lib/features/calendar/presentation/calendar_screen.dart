import 'package:flutter/material.dart';

import '../../../app/environment.dart';
import '../../../app/lume_app.dart';
import '../../../app/ui.dart' as app_ui;
import '../../../core/calendar/calendar_gateway.dart';
import '../../../core/widgets/lume_widgets.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final connected = controller.settings.calendarConnected;
    final integrationEnabled = LumeBuildConfig.enableCalendar;
    return app_ui.LumePage(
      title: 'Agenda',
      subtitle: connected ? 'Conta Google conectada' : 'Uma conexão opcional',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!integrationEnabled)
            const LumeErrorState(
              title: 'Agenda em preparação',
              description:
                  'Esta integração está atrás de uma feature flag enquanto o OAuth e o cache local são validados.',
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
                    'A Agenda do Google é separada da conta do Lume. Você escolhe os calendários e pode revogar o acesso depois.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _connect(context),
                    icon: const Icon(Icons.link),
                    label: const Text('Conectar Google Agenda'),
                  ),
                ],
              ),
            )
          else ...[
            const LumeSyncIndicator(state: LumeSyncState.offline),
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
                    onPressed: () => _disconnect(context),
                    icon: const Icon(Icons.link_off),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            LumeSectionHeader(
              title: 'Hoje',
              actionLabel: 'Novo evento',
              onAction: () => _showDraftEvent(context),
            ),
            const SizedBox(height: 8),
            if (controller.calendarEvents.isEmpty)
              const LumeEmptyState(
                title: 'Nenhum evento no cache',
                description:
                    'Quando a API do Google estiver configurada, seus eventos aparecerão aqui com data, duração e calendário.',
                illustration: Icon(Icons.event_available_outlined, size: 40),
              )
            else
              ...controller.calendarEvents.map(
                (event) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    event.isAllDay
                        ? Icons.wb_sunny_outlined
                        : Icons.event_outlined,
                  ),
                  title: Text(event.title),
                  subtitle: Text(
                    event.isAllDay
                        ? 'Dia inteiro · ${_date(event.start)}'
                        : '${_date(event.start)} · ${_time(event.start)}–${_time(event.end)}',
                  ),
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
                    'A implementação de produção precisa de OAuth Google, cache SQLite e sincronização incremental. Sem essas credenciais, nenhum token é armazenado neste protótipo local.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _connect(BuildContext context) async {
    final controller = AppScope.read(context);
    try {
      await controller.connectCalendar();
    } on CalendarGatewayException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Agenda conectada e sincronizada.')),
    );
  }

  Future<void> _disconnect(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desconectar Agenda?'),
        content: const Text(
          'Isso remove o estado local da integração, sem apagar seus registros do Lume.',
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
    await AppScope.read(context).disconnectCalendar();
  }

  Future<void> _showDraftEvent(BuildContext context) async {
    final title = TextEditingController();
    await app_ui.showLumeSheet(
      context,
      title: 'Novo evento',
      child: Column(
        children: [
          TextField(
            controller: title,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Título'),
          ),
          const SizedBox(height: 14),
          const LumeErrorState(
            title: 'Integração pendente',
            description:
                'A criação de eventos exige conexão online e OAuth Google configurado. O rascunho não será enviado sem permissão.',
            errorKind: LumeErrorKind.permission,
          ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ),
        ],
      ),
    );
    title.dispose();
  }

  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

  String _time(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
