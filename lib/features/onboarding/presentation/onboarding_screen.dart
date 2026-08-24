import 'package:flutter/material.dart';

import '../../../app/lume_app.dart';
import '../../../app/models.dart';
import '../../../app/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  final _waterController = TextEditingController(text: '2000');
  final _allowanceController = TextEditingController(text: '0,00');
  final _dayController = TextEditingController(text: '1');
  RolloverMode _rolloverMode = RolloverMode.positiveOnly;
  String? _error;

  @override
  void dispose() {
    _waterController.dispose();
    _allowanceController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  void _next() {
    setState(() => _error = null);
    if (_step == 0) {
      final water = int.tryParse(_waterController.text.trim());
      if (water == null || water <= 0) {
        setState(() => _error = 'Informe uma meta de água positiva em ml.');
        return;
      }
    }
    if (_step == 1) {
      final allowance = _parseMoney(_allowanceController.text);
      final day = int.tryParse(_dayController.text.trim());
      if (allowance == null ||
          allowance < 0 ||
          day == null ||
          day < 1 ||
          day > 31) {
        setState(() => _error = 'Confira o valor e o dia (1 a 31).');
        return;
      }
    }
    if (_step < 2) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final controller = AppScope.read(context);
    await controller.saveOnboarding(
      waterGoalMl: int.parse(_waterController.text.trim()),
      allowanceAmountMinor: _parseMoney(_allowanceController.text) ?? 0,
      allowanceDayOfMonth: int.parse(_dayController.text.trim()),
      rolloverMode: _rolloverMode,
    );
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/app/today', (route) => false);
  }

  int? _parseMoney(String raw) {
    final normalized = raw.trim().replaceAll('.', '').replaceAll(',', '.');
    final value = double.tryParse(normalized);
    if (value == null) return null;
    return (value * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Uma meta possível', 'Um mês mais claro', 'Tudo pronto'];
    return Scaffold(
      appBar: AppBar(
        title: Text('Passo ${_step + 1} de 3'),
        leading: _step == 0
            ? null
            : IconButton(
                tooltip: 'Voltar',
                onPressed: () => setState(() => _step--),
                icon: const Icon(Icons.arrow_back),
              ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: (_step + 1) / 3,
                minHeight: 8,
                borderRadius: BorderRadius.circular(99),
              ),
              const SizedBox(height: 28),
              Text(
                titles[_step],
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: LumeColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              if (_step == 0) _waterStep(),
              if (_step == 1) _financeStep(),
              if (_step == 2) _readyStep(),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(_step == 2 ? 'Ir para Hoje' : 'Continuar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _description => switch (_step) {
    0 =>
      'Começamos com uma referência que pode ser ajustada depois. O total sempre vem dos registros do dia.',
    1 =>
      'Se você usa mesada, o saldo será calculado a partir dos lançamentos — sem esconder a conta.',
    _ =>
      'Você pode alterar tudo em Configurações. Lembretes e Agenda começam desligados até sua escolha.',
  };

  Widget _waterStep() => TextField(
    controller: _waterController,
    keyboardType: TextInputType.number,
    decoration: const InputDecoration(
      labelText: 'Meta diária de água',
      suffixText: 'ml',
      helperText: 'Uma sugestão inicial é 2.000 ml.',
    ),
  );

  Widget _financeStep() => Column(
    children: [
      TextField(
        controller: _allowanceController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Valor mensal da mesada',
          prefixText: r'R$ ',
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _dayController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Dia de recebimento',
          suffixText: 'de cada mês',
          helperText:
              'Se o mês for mais curto, usamos o último dia disponível.',
        ),
      ),
      const SizedBox(height: 20),
      DropdownButtonFormField<RolloverMode>(
        initialValue: _rolloverMode,
        decoration: const InputDecoration(
          labelText: 'Saldo positivo do mês anterior',
        ),
        items: const [
          DropdownMenuItem(
            value: RolloverMode.positiveOnly,
            child: Text('Acumular saldo positivo'),
          ),
          DropdownMenuItem(
            value: RolloverMode.none,
            child: Text('Não acumular'),
          ),
        ],
        onChanged: (value) =>
            setState(() => _rolloverMode = value ?? RolloverMode.positiveOnly),
      ),
    ],
  );

  Widget _readyStep() => const Column(
    children: [
      Icon(Icons.favorite_outline, size: 56, color: LumeColors.brand),
      SizedBox(height: 16),
      Text(
        'Hoje é um bom lugar para começar. Você poderá adicionar água, registrar um movimento, cuidar das finanças ou guardar uma gratidão sem preencher tudo de uma vez.',
        textAlign: TextAlign.center,
      ),
    ],
  );
}
