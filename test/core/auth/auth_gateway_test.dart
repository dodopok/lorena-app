import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/auth/auth_gateway.dart';

void main() {
  test('modo local não cria sessão nem chama serviço externo', () async {
    const gateway = LocalAuthGateway();

    expect(await gateway.hasSession(), isFalse);
    await gateway.signInWithApple();
    await gateway.signOut();
    await gateway.deleteAccount();
    expect(await gateway.hasSession(), isFalse);
  });

  test('exceção de autenticação preserva mensagem amigável', () {
    const error = AuthGatewayException('A Apple cancelou o acesso.');

    expect(error.toString(), 'A Apple cancelou o acesso.');
  });
}
