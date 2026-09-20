import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart' hide IconAlignment;

import '../../../app/lume_app.dart';
import '../../../core/theme/lume_theme.dart';
import '../../../app/ui.dart';
import '../../../core/widgets/lume_motion.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.lumeColors;
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal:
                      24 +
                      (MediaQuery.sizeOf(context).width - 560).clamp(
                            0,
                            double.infinity,
                          ) /
                          2,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LumeReveal(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          color: Color(0xFF151011),
                          image: DecorationImage(
                            image: AssetImage(
                              'assets/images/lume-editorial-still-life.png',
                            ),
                            fit: BoxFit.cover,
                            alignment: Alignment.bottomCenter,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lume',
                              style: Theme.of(context).textTheme.displayMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 0,
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Feito para os seus dias.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 200),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    LumeReveal(
                      delay: const Duration(milliseconds: 100),
                      child: Text(
                        'A vida acontece\nnos pequenos momentos.',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(height: 1.25),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Um lugar para cuidar de você e guardar o que faz seus dias valerem a pena.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(
                          context,
                        ).pushReplacementNamed('/auth/sign-in'),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                        iconAlignment: IconAlignment.end,
                        label: const Text('Começar'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 15,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Seu espaço. Seus registros. Seu ritmo.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.textSecondary),
                          ),
                        ),
                      ],
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
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _saving = false;

  Future<void> _signIn() async {
    if (_saving) return;
    setState(() => _saving = true);
    final controller = AppScope.read(context);
    try {
      await controller.signInWithApple();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      if (error.code != 'user-cancelled' &&
          error.code != 'web-context-canceled') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_authError(error))));
      }
      return;
    } on SignInWithAppleException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      if (error is! SignInWithAppleAuthorizationException ||
          error.code != AuthorizationErrorCode.canceled) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_appleError(error))));
      }
      return;
    } on Exception {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Não foi possível entrar agora. Tente novamente.',
          ),
        ),
      );
      return;
    }
    // The session gate reveals the requested destination after persistence.
  }

  String _authError(FirebaseAuthException error) => switch (error.code) {
    'user-cancelled' || 'web-context-canceled' => 'Login cancelado.',
    'credential-already-in-use' =>
      'Esta credencial Apple já está vinculada a outra conta.',
    'requires-recent-login' => 'Entre novamente para continuar.',
    _ => 'Não foi possível entrar com a Apple agora.',
  };

  String _appleError(SignInWithAppleException error) =>
      error is SignInWithAppleAuthorizationException &&
          error.code == AuthorizationErrorCode.canceled
      ? 'Login cancelado.'
      : 'Não foi possível concluir o login com a Apple.';

  @override
  Widget build(BuildContext context) {
    final usesApple = AppScope.of(context).usesAppleSignIn;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usesApple
                          ? 'Sua conta, do seu jeito'
                          : 'Seu espaço começa aqui',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      usesApple
                          ? 'Entre com a Apple para recuperar seus dados com segurança. A Agenda do Google é uma conexão separada e opcional.'
                          : 'Comece a cuidar do seu dia com registros neste aparelho.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.45,
                        color: context.lumeColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),
                    LumeCard(
                      color: context.lumeColors.brandSoft.withValues(
                        alpha: .55,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            color: context.lumeColors.brandStrong,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              usesApple
                                  ? 'Sua conta mantém seus registros pessoais juntos. Você escolhe quais conexões e lembretes ativar.'
                                  : 'Seus registros ficam salvos neste aparelho. Você pode exportar uma cópia em Configurações.',
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
                            : Icon(
                                usesApple ? Icons.apple : Icons.arrow_forward,
                              ),
                        label: Text(
                          _saving
                              ? 'Entrando…'
                              : usesApple
                              ? 'Continuar com Apple'
                              : 'Continuar neste aparelho',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Você poderá sair ou excluir os dados em Configurações.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.lumeColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
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
}
