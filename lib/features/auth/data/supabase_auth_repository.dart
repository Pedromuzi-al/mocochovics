import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/auth_repository.dart';
import 'auth_recovery_store.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(SupabaseClient client, {required String redirectUrl})
    : this.withAuthClient(
        client.auth,
        redirectUrl: redirectUrl,
        recoveryStore: PreferencesAuthRecoveryStore(),
      );

  SupabaseAuthRepository.withAuthClient(
    this._auth, {
    required this._redirectUrl,
    required this._recoveryStore,
  }) : _recoveryOwnerId = _auth.currentUser?.id;

  final GoTrueClient _auth;
  final String _redirectUrl;
  final AuthRecoveryStore _recoveryStore;
  bool _isPasswordRecovery = false;
  String? _recoveryOwnerId;
  int _recoveryRevision = 0;
  Future<void> _pendingPersistence = Future.value();

  @override
  AuthSession get currentSession => AuthSession(
    email: _auth.currentUser?.email,
    isAuthenticated: _auth.currentSession != null,
    isPasswordRecovery: _isPasswordRecovery,
  );

  @override
  Stream<AuthSession> get sessionChanges => _auth.onAuthStateChange
      .asyncMap((state) async {
        final userId = state.session?.user.id;
        if (state.event == AuthChangeEvent.passwordRecovery) {
          await _setRecovery(userId, pending: true);
        } else if (state.event == AuthChangeEvent.signedOut) {
          await _setRecovery(_recoveryOwnerId, pending: false);
        } else if (userId != null) {
          final revision = _recoveryRevision;
          await _pendingPersistence;
          final pending = await _recoveryStore.isPending(userId);
          if (revision == _recoveryRevision) {
            _isPasswordRecovery = pending;
            _recoveryOwnerId = userId;
          }
        }
        return currentSession;
      })
      .handleError((Object error) => throw _friendlyFailure(error));

  @override
  Future<void> signIn({required String email, required String password}) =>
      _perform(() async {
        await _auth.signInWithPassword(email: email, password: password);
        await _setRecovery(_auth.currentUser?.id, pending: false);
      });

  @override
  Future<void> signUp({required String email, required String password}) =>
      _perform(() async {
        await _auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: _redirectUrl,
        );
      });

  @override
  Future<void> sendPasswordReset({required String email}) => _perform(() async {
    await _auth.resetPasswordForEmail(email, redirectTo: _redirectUrl);
  });

  @override
  Future<void> updatePassword({required String password}) => _perform(() async {
    await _auth.updateUser(UserAttributes(password: password));
    await _setRecovery(_auth.currentUser?.id, pending: false);
  });

  @override
  Future<void> signOut() => _perform(() async {
    final userId = _auth.currentUser?.id ?? _recoveryOwnerId;
    await _auth.signOut(scope: SignOutScope.local);
    await _setRecovery(userId, pending: false);
  });

  Future<void> _setRecovery(String? userId, {required bool pending}) async {
    _recoveryRevision++;
    _isPasswordRecovery = pending && userId != null;
    _recoveryOwnerId = pending ? userId : null;
    if (userId == null) return;
    final write = _pendingPersistence.then(
      (_) => _recoveryStore.setPending(userId, pending: pending),
    );
    _pendingPersistence = write.then<void>((_) {}, onError: (Object _) {});
    await write;
  }

  Future<void> _perform(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      throw _friendlyFailure(error);
    }
  }

  AuthFailure _friendlyFailure(Object error) {
    if (error is AuthRetryableFetchException || error is TimeoutException) {
      return const AuthFailure(
        'Não foi possível conectar. Confira sua internet e tente novamente.',
      );
    }
    if (error is AuthException) {
      final message = switch (error.code) {
        'invalid_credentials' =>
          'E-mail ou senha incorretos. Confira e tente novamente.',
        'email_not_confirmed' =>
          'Confirme seu e-mail pelo link que enviamos antes de entrar.',
        'user_already_exists' || 'email_exists' => 'Não foi possível criar a conta. Tente entrar ou recuperar sua senha.',
        'weak_password' =>
          'Escolha uma senha mais forte, com letras, números e símbolos.',
        'same_password' => 'A nova senha deve ser diferente da senha atual.',
        'over_email_send_rate_limit' ||
        'over_request_rate_limit' ||
        'over_sms_send_rate_limit' =>
          'Muitas tentativas. Aguarde alguns minutos e tente novamente.',
        'otp_expired' || 'flow_state_expired' || 'flow_state_not_found' =>
          'Este link expirou ou já foi usado. Solicite um novo e-mail.',
        'session_not_found' ||
        'refresh_token_not_found' ||
        'bad_jwt' => 'Sua sessão expirou. Entre novamente para continuar.',
        'signup_disabled' => 'O cadastro está indisponível no momento.',
        _ =>
          error.statusCode == '429'
              ? 'Muitas tentativas. Aguarde alguns minutos e tente novamente.'
              : 'Não foi possível concluir. Confira os dados e tente novamente.',
      };
      return AuthFailure(message);
    }
    return const AuthFailure(
      'Não foi possível conectar. Confira sua internet e tente novamente.',
    );
  }
}
