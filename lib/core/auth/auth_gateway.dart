import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Boundary between the app session and an identity provider.
///
/// The UI and [AppController] only depend on this contract. Local mode uses
/// [LocalAuthGateway], while the iPhone dev/prod builds use Firebase + Apple.
abstract interface class AuthGateway {
  String? get userId;

  Future<bool> hasSession();

  Future<void> signInWithApple();

  Future<void> signOut();

  Future<void> deleteAccount();
}

class LocalAuthGateway implements AuthGateway {
  const LocalAuthGateway();

  @override
  String? get userId => null;

  @override
  Future<bool> hasSession() async => false;

  @override
  Future<void> signInWithApple() async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount() async {}
}

class AuthGatewayException implements Exception {
  const AuthGatewayException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Apple credential exchange for the shared Firebase Authentication project.
class FirebaseAppleAuthGateway implements AuthGateway {
  FirebaseAppleAuthGateway({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  String? get userId => _auth.currentUser?.uid;

  @override
  Future<bool> hasSession() async => _auth.currentUser != null;

  @override
  Future<void> signInWithApple() async {
    final rawNonce = generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
    final available = await SignInWithApple.isAvailable();
    if (!available) {
      throw const AuthGatewayException(
        'Sign in with Apple não está disponível neste aparelho.',
      );
    }

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );
    final identityToken = appleCredential.identityToken;
    if (identityToken == null || identityToken.isEmpty) {
      throw const AuthGatewayException(
        'A Apple não retornou um token de identidade válido.',
      );
    }

    final credential = OAuthProvider(
      'apple.com',
    ).credential(idToken: identityToken, rawNonce: rawNonce);
    await _auth.signInWithCredential(credential);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.delete();
  }
}
