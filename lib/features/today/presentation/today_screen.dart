import 'package:flutter/material.dart';

import '../../../app/app_controller.dart';
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
    final pending = controller.waterFor(now).any((log) => log.syncState == SyncState.pending);
    final greeting = now.hour < 12 ? 'Bom dia' : now.hour < 18 ? 'Boa tarde' : 'Boa noite';
    return app_ui.LumePage(
      title: greeting,
      subtitle: '${controller.formatDate(now)} · um passo de cada vez',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pending) ...[
            const LumeSyncIndicator(state: LumeSyncState.pending),
            const SizedBox(height: 12),
          ],
          LumeCard(
            tone: LumeCardTone.calendar,
            semanticLabel: 'Próximo compromisso',
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: Colors.white54, child: Icon(Icons.event_outlined)),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Próximo compromisso', style: TextStyle(fontWeight: FontWeight.w700)),
                      SizedBox(height: 4),
                      Text('Conecte a Agenda quando quiser visualizar seus eventos.'),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Abrir Agenda',
                  onPressed: () => Navigator.of(context).pushNamed('/app/calendar'),
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
                ? 'Meta alcançada — seu ritmo está ótimo.'
                : 'Um copo a mais também conta 💧',
            action: 'Ver histórico',
            onAction: () => Navigator.of(context).pushNamed('/app/wellbeing'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.settings.quickWaterAmountsMl.map((amount) {
              return LumeQuickAction(
                icon: Icons.water_drop_outlined,
                label: '+$amount ml',
                value: 'Adicionar água',
                tone: LumeCardTone.wellbeing,
                onPressed: () => _addWater(context, controller, amount),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const LumeSectionHeader(title: 'Ações rápidas'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _ActionTile(icon: Icons.self_improvement_outlined, label: 'Evacuação', color: context.lumeColors.wellbeing, onTap: () => _showBowel(context))),
              const SizedBox(width: 10),
              Expanded(child: _ActionTile(icon: Icons.directions_walk_outlined, label: 'Exercício', color: context.lumeColors.calendar, onTap: () => _showExercise(context))),
              const SizedBox(width: 10),
              Expanded(child: _ActionTile(icon: Icons.add_card_outlined, label: 'Gasto', color: context.lumeColors.finance, onTap: () => _showExpense(context))),
            ],
          ),
          const SizedBox(height: 24),
          LumeMoneySummaryCard(
            periodLabel: _monthLabel(now),
            balanceMinor: controller.balanceFor(currentPeriod),
            currency: 'BRL',
            incomeMinor: controller.incomeFor(currentPeriod),
            expenseMinor: controller.expensesFor(currentPeriod),
            onTap: () => Navigator.of(context).pushNamed('/app/finance'),
          ),
          const SizedBox(height: 24),
          const LumeSectionHeader(title: 'Gratidão de hoje'),
          const SizedBox(height: 10),
          LumeCard(
            tone: LumeCardTone.corner,
            onTap: () => _showGratitude(context, gratitude?.text ?? ''),
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
                      const Icon(Icons.favorite, color: Colors.pink),
                      const SizedBox(width: 12),
                      Expanded(child: Text(gratitude.text, maxLines: 4, overflow: TextOverflow.ellipsis)),
                      const Icon(Icons.edit_outlined, size: 20),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  String _monthLabel(DateTime date) => '${date.month}/${date.year}';

  Future<void> _addWater(BuildContext context, AppController controller, int amount) async {
    final id = await controller.addWater(amount);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$amount ml adicionados.'),
        action: SnackBarAction(label: 'Desfazer', onPressed: () => controller.removeWater(id)),
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
          const Align(alignment: Alignment.centerLeft, child: Text('O horário atual já está preenchido. Observações são opcionais e não geram diagnóstico.')),
          const SizedBox(height: 16),
          TextField(controller: note, maxLines: 3, decoration: const InputDecoration(labelText: 'Observação (opcional)')),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () async { await AppScope.read(context).addBowel(note: note.text); if (context.mounted) Navigator.pop(context); }, child: const Text('Salvar'))),
        ],
      ),
    );
    note.dispose();
  }

  Future<void> _showExercise(BuildContext context) async {
    final type = TextEditingController(text: 'Caminhada');
    final duration = TextEditingController();
    await app_ui.showLumeSheet(
      context,
      title: 'Novo exercício',
      child: Column(
        children: [
          TextField(controller: type, decoration: const InputDecoration(labelText: 'Atividade')),
          const SizedBox(height: 12),
          TextField(controller: duration, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Duração', suffixText: 'minutos')),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () async { final minutes = int.tryParse(duration.text); if (minutes == null || minutes <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe uma duração positiva.'))); return; } await AppScope.read(context).addExercise(activityType: type.text, durationMinutes: minutes); if (context.mounted) Navigator.pop(context); }, child: const Text('Salvar'))),
        ],
      ),
    );
    type.dispose();
    duration.dispose();
  }

  Future<void> _showExpense(BuildContext context) async {
    final amount = TextEditingController();
    final description = TextEditingController();
    final category = TextEditingController(text: 'Outros');
    await app_ui.showLumeSheet(
      context,
      title: 'Novo gasto',
      child: Column(
        children: [
          TextField(controller: amount, autofocus: true, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Valor', prefixText: 'R$ ')),
          const SizedBox(height: 12),
          TextField(controller: description, decoration: const InputDecoration(labelText: 'Descrição')),
          const SizedBox(height: 12),
          TextField(controller: category, decoration: const InputDecoration(labelText: 'Categoria')),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () async { final value = _parseMoney(amount.text); if (value == null || value <= 0 || description.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe valor e descrição.'))); return; } await AppScope.read(context).addTransaction(type: TransactionType.expense, amountMinor: value, category: category.text, description: description.text); if (context.mounted) Navigator.pop(context); }, child: const Text('Salvar gasto'))),
        ],
      ),
    );
    amount.dispose();
    description.dispose();
    category.dispose();
  }

  Future<void> _showGratitude(BuildContext context, String initial) async {
    final text = TextEditingController(text: initial);
    await app_ui.showLumeSheet(
      context,
      title: 'Gratidão de hoje',
      child: Column(
        children: [
          TextField(controller: text, autofocus: true, maxLines: 5, maxLength: 1000, decoration: const InputDecoration(labelText: 'O que foi bom hoje?', alignLabelWithHint: true)),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () async { if (text.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escreva algo antes de salvar.'))); return; } await AppScope.read(context).saveGratitude(text.text); if (context.mounted) Navigator.pop(context); }, child: const Text('Guardar'))),
        ],
      ),
    );
    text.dispose();
  }

  int? _parseMoney(String raw) {
    final normalized = raw.trim().replaceAll('.', '').replaceAll(',', '.');
    final value = double.tryParse(normalized);
    return value == null ? null : (value * 100).round();
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label, required this.color, required this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              child: Column(
                children: [Icon(icon, size: 24), const SizedBox(height: 6), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),],
              ),
            ),
          ),
        ),
      );
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

