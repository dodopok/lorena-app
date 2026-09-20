import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/environment.dart';
import '../../../core/theme/lume_theme.dart';
import '../../../app/lume_app.dart';
import '../../../app/models.dart';
import '../../../app/ui.dart' as app_ui;

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final settings = controller.settings;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: app_ui.LumePage(
        title: 'Configurações',
        subtitle: 'Preferências do seu Lume',
        showProfile: false,
        actions: [
          IconButton(
            tooltip: 'Fechar',
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.close),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SettingsGroup(
              title: 'Seu dia',
              children: [
                ListTile(
                  leading: const Icon(Icons.water_drop_outlined),
                  title: const Text('Meta de água'),
                  subtitle: Text('${settings.waterGoalMl} ml por dia'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _editWaterGoal(context),
                ),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: const Text('Mesada'),
                  subtitle: Text(
                    settings.allowanceAmountMinor == 0
                        ? 'Não configurada'
                        : '${controller.formatMinor(settings.allowanceAmountMinor)} · dia ${settings.allowanceDayOfMonth}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _editAllowance(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SettingsGroup(
              title: 'Proteção e lembretes',
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.face_outlined),
                  title: const Text('Bloqueio biométrico'),
                  subtitle: const Text(
                    'Protege a abertura do app quando disponível',
                  ),
                  value: settings.biometricLockEnabled,
                  onChanged: (value) async {
                    final enabled = await controller.setBiometricLockEnabled(
                      value,
                    );
                    if (!enabled && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Este aparelho não possui biometria disponível.',
                          ),
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.schedule_outlined),
                  title: const Text('Horários dos lembretes'),
                  subtitle: Text(
                    _reminderSummary(settings.reminderPreferences),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _editReminders(context),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_none),
                  title: const Text('Lembretes'),
                  subtitle: const Text(
                    'Começam desligados até você escolher ativar',
                  ),
                  value: settings.notificationsEnabled,
                  onChanged: (value) async {
                    final enabled = await controller.setNotificationsEnabled(
                      value,
                    );
                    if (!enabled && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'A permissão de lembretes não foi concedida.',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SettingsGroup(
              title: 'Integrações',
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_month_outlined),
                  title: const Text('Google Agenda'),
                  subtitle: Text(
                    settings.calendarConnected
                        ? 'Conectada neste aparelho'
                        : 'Disponível para conectar',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pushNamed('/app/calendar'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SettingsGroup(
              title: 'Conta e privacidade',
              children: [
                ListTile(
                  leading: const Icon(Icons.ios_share_outlined),
                  title: const Text('Exportar meus dados'),
                  subtitle: const Text(
                    'Cópia legível dos registros deste aparelho',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      Navigator.of(context).pushNamed('/app/settings/privacy'),
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sair'),
                  onTap: () => _signOut(context),
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_forever_outlined,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Excluir conta e dados',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onTap: () =>
                      Navigator.of(context).pushNamed('/app/settings/privacy'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Lume · ambiente ${LumeBuildConfig.label} · dados locais + Firebase',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.lumeColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editWaterGoal(BuildContext context) async {
    final controller = AppScope.read(context);
    final value = TextEditingController(
      text: '${controller.settings.waterGoalMl}',
    );
    await app_ui.showLumeSheet(
      context,
      title: 'Meta de água',
      child: Column(
        children: [
          TextField(
            controller: value,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Meta diária',
              suffixText: 'ml',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                final goal = int.tryParse(value.text);
                if (goal == null || goal <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Informe uma meta positiva.')),
                  );
                  return;
                }
                await controller.updateSettings(
                  controller.settings.copyWith(waterGoalMl: goal),
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Salvar'),
            ),
          ),
        ],
      ),
    );
    value.dispose();
  }

  Future<void> _editAllowance(BuildContext context) async {
    final controller = AppScope.read(context);
    final amount = TextEditingController(
      text: controller.settings.allowanceAmountMinor == 0
          ? ''
          : (controller.settings.allowanceAmountMinor / 100)
                .toStringAsFixed(2)
                .replaceAll('.', ','),
    );
    final day = TextEditingController(
      text: '${controller.settings.allowanceDayOfMonth}',
    );
    await app_ui.showLumeSheet(
      context,
      title: 'Mesada',
      child: Column(
        children: [
          TextField(
            controller: amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Valor mensal',
              prefixText: r'R$ ',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: day,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Dia de recebimento',
              suffixText: '1 a 31',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                final minor = _parseMoney(amount.text);
                final dayValue = int.tryParse(day.text);
                if (minor == null ||
                    minor < 0 ||
                    dayValue == null ||
                    dayValue < 1 ||
                    dayValue > 31) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Confira o valor e o dia.')),
                  );
                  return;
                }
                await controller.updateSettings(
                  controller.settings.copyWith(
                    allowanceAmountMinor: minor,
                    allowanceDayOfMonth: dayValue,
                  ),
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Salvar'),
            ),
          ),
        ],
      ),
    );
    amount.dispose();
    day.dispose();
  }

  Future<void> _editReminders(BuildContext context) async {
    final controller = AppScope.read(context);
    final current = controller.settings.reminderPreferences;
    final selectedWater = <String>{
      ...(current.waterTimes.isEmpty
          ? const ['10:00', '15:00', '20:00']
          : current.waterTimes),
    };
    final selectedWeekdays = <int>{...current.exerciseWeekdays};
    var gratitudeTime = current.gratitudeTime;
    var exerciseTime = current.exerciseTime;
    const waterOptions = ['08:00', '10:00', '12:00', '15:00', '18:00', '20:00'];
    const weekdayLabels = {
      1: 'Seg',
      2: 'Ter',
      3: 'Qua',
      4: 'Qui',
      5: 'Sex',
      6: 'Sáb',
      7: 'Dom',
    };

    await app_ui.showLumeSheet(
      context,
      title: 'Lembretes gentis',
      child: StatefulBuilder(
        builder: (context, setSheetState) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Escolha só os momentos que ajudam. As notificações usam textos genéricos na tela bloqueada.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text('Água', style: Theme.of(context).textTheme.titleSmall),
            ...waterOptions.map(
              (time) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: selectedWater.contains(time),
                title: Text(time),
                onChanged: (value) => setSheetState(() {
                  if (value == true) {
                    selectedWater.add(time);
                  } else {
                    selectedWater.remove(time);
                  }
                }),
              ),
            ),
            const Divider(height: 24),
            Text('Exercício', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: weekdayLabels.entries
                  .map(
                    (entry) => FilterChip(
                      label: Text(entry.value),
                      selected: selectedWeekdays.contains(entry.key),
                      onSelected: (value) => setSheetState(() {
                        if (value) {
                          selectedWeekdays.add(entry.key);
                        } else {
                          selectedWeekdays.remove(entry.key);
                        }
                      }),
                    ),
                  )
                  .toList(),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Horário do exercício'),
              trailing: Text(exerciseTime),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _timeOfDay(exerciseTime),
                );
                if (picked != null) {
                  setSheetState(() => exerciseTime = _formatTime(picked));
                }
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Lembrete de gratidão'),
              trailing: Text(gratitudeTime),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _timeOfDay(gratitudeTime),
                );
                if (picked != null) {
                  setSheetState(() => gratitudeTime = _formatTime(picked));
                }
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  await controller.updateReminderPreferences(
                    ReminderPreferences(
                      waterTimes: selectedWater.toList()..sort(),
                      exerciseWeekdays: selectedWeekdays.toList()..sort(),
                      exerciseTime: exerciseTime,
                      gratitudeTime: gratitudeTime,
                      allowanceTime: current.allowanceTime,
                    ),
                  );
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Salvar horários'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair do Lume?'),
        content: const Text(
          'Seus registros permanecem neste aparelho e não serão excluídos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await AppScope.read(context).signOut();
    if (context.mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/welcome', (route) => false);
    }
  }

  int? _parseMoney(String raw) {
    final value = double.tryParse(
      raw.trim().replaceAll('.', '').replaceAll(',', '.'),
    );
    return value == null ? null : (value * 100).round();
  }

  TimeOfDay _timeOfDay(String value) {
    final parts = value.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.first) ?? 18,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0,
    );
  }

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  String _reminderSummary(ReminderPreferences preferences) {
    if (preferences.waterTimes.isEmpty &&
        preferences.exerciseWeekdays.isEmpty) {
      return 'Escolha os horários depois de ativar';
    }
    final water = preferences.waterTimes.isEmpty
        ? 'sem água'
        : 'água ${preferences.waterTimes.join(', ')}';
    return '$water · gratidão ${preferences.gratitudeTime}';
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: app_ui.LumePage(
        title: 'Privacidade',
        subtitle: 'Você tem controle sobre seus dados',
        showProfile: false,
        actions: [
          IconButton(
            tooltip: 'Fechar',
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.close),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            app_ui.LumeCard(
              color: context.lumeColors.brandSoft.withValues(alpha: .5),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'O Lume mantém uma cópia local para funcionar offline e sincroniza dados próprios com o Firebase quando a sessão estiver configurada. Mídias ficam privadas no Storage por UID.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Portabilidade',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _export(context),
                icon: const Icon(Icons.download_outlined),
                label: const Text('Exportar e compartilhar meus dados'),
              ),
            ),
            const SizedBox(height: 24),
            Text('Exclusão', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'A exclusão exige confirmação clara. O fluxo remove o snapshot local, dados remotos e mídias conhecidas do UID.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.lumeColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => _delete(context),
                icon: const Icon(Icons.delete_forever_outlined),
                label: const Text('Excluir dados deste aparelho'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    try {
      final bundle = await AppScope.read(context).createExport();
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(bundle.path, name: bundle.fileName)],
          subject: 'Exportação dos dados do Lume',
          text: 'Exportação sensível dos dados do Lume. Guarde com cuidado.',
        ),
      );
    } on Object catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível preparar a exportação.'),
        ),
      );
    }
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir todos os dados?'),
        content: const Text(
          'Esta ação remove registros locais, dados remotos, mídias conhecidas e encerra a sessão. Exporte uma cópia antes se quiser guardá-la.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context, false);
              await _export(context);
            },
            child: const Text('Exportar antes'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await AppScope.read(context).deleteAccount();
    } on Object catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível confirmar sua identidade. Nenhum dado foi excluído.',
          ),
        ),
      );
      return;
    }
    if (context.mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/welcome', (route) => false);
    }
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      Card(child: Column(children: children)),
    ],
  );
}
