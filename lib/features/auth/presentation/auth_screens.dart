import 'package:flutter/material.dart';

import '../../../app/lume_app.dart';
import '../../../app/theme.dart';
import '../../../app/ui.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: LumeColors.brandSoft,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(
                  Icons.wb_sunny_outlined,
                  size: 40,
                  color: LumeColors.brandStrong,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Lume',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: LumeColors.brandStrong,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Um espaço calmo para cuidar do seu dia, guardar o que importa e acompanhar seus pequenos passos.',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(height: 1.3),
              ),
              const SizedBox(height: 18),
              Text(
                'Seus registros ficam disponíveis mesmo sem conexão e você escolhe quando ativar cada integração.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: LumeColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pushReplacementNamed('/auth/sign-in'),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text('Começar'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Português (Brasil) · BRL · America/Sao_Paulo',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: LumeColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _saving = false;

  Future<void> _signIn() async {
    setState(() => _saving = true);
    final controller = AppScope.read(context);
    await controller.signInOnDevice();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sua conta, do seu jeito',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Entre com a Apple para recuperar seus dados com segurança. A Agenda do Google é uma conexão separada e opcional.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.45,
                  color: LumeColors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              LumeCard(
                color: LumeColors.brandSoft.withValues(alpha: .55),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline, color: LumeColors.brandStrong),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No modo local de desenvolvimento, a sessão fica neste aparelho. A conexão Apple/Firebase entra quando as credenciais do ambiente forem configuradas.',
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _signIn,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.apple),
                  label: Text(_saving ? 'Entrando…' : 'Continuar com Apple'),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Você poderá sair ou excluir os dados em Configurações.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: LumeColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
