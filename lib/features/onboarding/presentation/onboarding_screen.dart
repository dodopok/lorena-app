import 'package:flutter/material.dart';

import '../../../app/lume_app.dart';
import '../../../app/models.dart';
import '../../../core/theme/lume_theme.dart';
import '../../../core/widgets/lume_motion.dart';
import '../../../core/widgets/lume_currency_input.dart';

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
  bool _loading = true;
  bool _saving = false;
  String? _owner;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_owner != null) return;
    final controller = AppScope.read(context);
    _owner = controller.draftOwner;
    _restore();
  }

  Future<void> _restore() async {
    final controller = AppScope.read(context);
    try {
      final draft = await controller.readDraft('onboarding');
      if (!mounted) return;
      _waterController.text = draft?['water'] is String
          ? draft!['water'] as String
          : '${controller.settings.waterGoalMl}';
      _allowanceController.text = draft?['allowance'] is String
          ? draft!['allowance'] as String
          : LumeCurrencyInputFormatter.formatMinor(
              controller.settings.allowanceAmountMinor,
            );
      _dayController.text = draft?['day'] is String
          ? draft!['day'] as String
          : '${controller.settings.allowanceDayOfMonth}';
      _step = draft?['step'] is int ? (draft!['step'] as int).clamp(0, 2) : 0;
      _rolloverMode = switch (draft?['rollover']) {
        'none' => RolloverMode.none,
        'positiveOnly' => RolloverMode.positiveOnly,
        _ => controller.settings.rolloverMode,
      };
    } catch (_) {
      if (mounted) {
        _error =
            'Não foi possível recuperar suas preferências. Você pode configurá-las novamente.';
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveDraft(int step) =>
      AppScope.read(context).writeDraft('onboarding', {
        'step': step,
        'water': _waterController.text,
        'allowance': _allowanceController.text,
        'day': _dayController.text,
        'rollover': _rolloverMode.name,
      }, owner: _owner!);

  @override
  void dispose() {
    _waterController.dispose();
    _allowanceController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_saving) return;
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
    setState(() => _saving = true);
    try {
      if (_step < 2) {
        await _saveDraft(_step + 1);
        if (mounted) setState(() => _step++);
      } else {
        await _finish();
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Não foi possível guardar suas preferências. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
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
    try {
      await controller.writeDraft('onboarding', null, owner: _owner!);
    } catch (_) {
      // The completed preferences are already stored.
    }
    // The session gate reveals the requested destination after persistence.
  }

  int? _parseMoney(String raw) {
    final normalized = raw.trim().replaceAll('.', '').replaceAll(',', '.');
    final value = double.tryParse(normalized);
    if (value == null) return null;
    return (value * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final titles = ['Uma meta possível', 'Um mês mais claro', 'Tudo pronto'];
    return Scaffold(
      appBar: AppBar(
        title: Text('Passo ${_step + 1} de 3'),
        leading: _step == 0
            ? null
            : IconButton(
                tooltip: 'Voltar',
                onPressed: _saving ? null : () => setState(() => _step--),
                icon: const Icon(Icons.arrow_back),
              ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(end: (_step + 1) / 3),
                      duration: lumeMotionDuration(
                        context,
                        const Duration(milliseconds: 280),
                      ),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) =>
                          LinearProgressIndicator(
                            value: value,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(99),
                          ),
                    ),
                    const SizedBox(height: 28),
                    LumeAnimatedContent(
                      child: AnimatedSwitcher(
                        duration: lumeMotionDuration(
                          context,
                          const Duration(milliseconds: 260),
                        ),
                        layoutBuilder: (currentChild, previousChildren) =>
                            Stack(
                              alignment: Alignment.topLeft,
                              children: <Widget>[
                                ...previousChildren,
                                ?currentChild,
                              ],
                            ),
                        transitionBuilder: lumePageTransition,
                        child: SizedBox(
                          key: ValueKey('intro-$_step'),
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                titles[_step],
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _description,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: context.lumeColors.textSecondary,
                                      height: 1.4,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    LumeAnimatedContent(
                      child: AnimatedSwitcher(
                        duration: lumeMotionDuration(
                          context,
                          const Duration(milliseconds: 260),
                        ),
                        layoutBuilder: (currentChild, previousChildren) =>
                            Stack(
                              alignment: Alignment.topCenter,
                              children: <Widget>[
                                ...previousChildren,
                                ?currentChild,
                              ],
                            ),
                        transitionBuilder: lumePageTransition,
                        child: KeyedSubtree(
                          key: ValueKey('step-$_step'),
                          child: switch (_step) {
                            0 => _waterStep(),
                            1 => _financeStep(),
                            _ => _readyStep(),
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    LumeAnimatedContent(
                      child: AnimatedSwitcher(
                        duration: lumeMotionDuration(
                          context,
                          const Duration(milliseconds: 180),
                        ),
                        layoutBuilder: (currentChild, previousChildren) =>
                            Stack(
                              alignment: Alignment.topLeft,
                              children: <Widget>[
                                ...previousChildren,
                                ?currentChild,
                              ],
                            ),
                        transitionBuilder: lumePageTransition,
                        child: _error == null
                            ? const SizedBox(key: ValueKey('no-error'))
                            : SizedBox(
                                key: const ValueKey('has-error'),
                                width: double.infinity,
                                child: Text(
                                  _error!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saving ? null : _next,
                        child: Text(
                          _saving
                              ? 'Salvando…'
                              : _step == 2
                              ? 'Começar meu dia'
                              : 'Continuar',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _description => switch (_step) {
    0 =>
      'Uma meta para acompanhar seus pequenos cuidados. Você pode ajustar esse valor quando quiser.',
    1 =>
      'Organize o valor que recebe todo mês e escolha como acompanhar o saldo.',
    _ =>
      'Você pode alterar tudo em Configurações. Lembretes e Agenda começam desligados até sua escolha.',
  };

  Widget _waterStep() => TextField(
    enabled: !_saving,
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
        enabled: !_saving,
        controller: _allowanceController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Valor mensal da mesada',
          prefixText: r'R$ ',
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        enabled: !_saving,
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
        isExpanded: true,
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
        onChanged: _saving
            ? null
            : (value) => setState(
                () => _rolloverMode = value ?? RolloverMode.positiveOnly,
              ),
      ),
    ],
  );

  Widget _readyStep() => Column(
    children: [
      Icon(Icons.favorite_outline, size: 56, color: context.lumeColors.brand),
      SizedBox(height: 16),
      Text(
        'Hoje é um bom lugar para começar. Você poderá adicionar água, registrar um movimento, cuidar das finanças ou guardar uma gratidão sem preencher tudo de uma vez.',
        textAlign: TextAlign.center,
      ),
    ],
  );
}
