import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../data/supabase_auth_repository.dart';
import '../../domain/auth_repository.dart';
import '../../domain/auth_validators.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(
    ref.watch(supabaseClientProvider),
    redirectUrl: ref.watch(authRedirectUrlProvider),
  );
});

final authControllerProvider = Provider<AuthController>((ref) {
  final controller = AuthController(ref.watch(authRepositoryProvider));
  ref.onDispose(controller.dispose);
  return controller;
});

class AuthController extends ChangeNotifier {
  AuthController(this._repository) : _session = _repository.currentSession {
    _subscription = _repository.sessionChanges.listen(
      (session) {
        _session = session;
        _notify();
      },
      onError: (Object error) {
        _errorMessage = _messageFor(error);
        _sessionErrorMessage = _errorMessage;
        _notify();
      },
    );
  }

  final AuthRepository _repository;
  late final StreamSubscription<AuthSession> _subscription;
  AuthSession _session;
  bool _isBusy = false;
  bool _disposed = false;
  String? _errorMessage;
  String? _sessionErrorMessage;

  bool get isAuthenticated => _session.isAuthenticated;
  bool get isRecoveringPassword =>
      _session.isAuthenticated && _session.isPasswordRecovery;
  bool get isBusy => _isBusy;
  String? get email => _session.email;
  String? get errorMessage => _errorMessage;
  String? get sessionErrorMessage => _sessionErrorMessage;

  Future<bool> signIn({required String email, required String password}) =>
      _execute(
        () => _repository.signIn(email: email.trim(), password: password),
        validation:
            AuthValidators.email(email) ?? AuthValidators.password(password),
      );

  Future<bool> signUp({required String email, required String password}) =>
      _execute(
        () => _repository.signUp(email: email.trim(), password: password),
        validation:
            AuthValidators.email(email) ?? AuthValidators.newPassword(password),
      );

  Future<bool> sendPasswordReset({required String email}) => _execute(
    () => _repository.sendPasswordReset(email: email.trim()),
    validation: AuthValidators.email(email),
  );

  Future<bool> updatePassword({required String password}) => _execute(
    () => _repository.updatePassword(password: password),
    validation: !isAuthenticated
        ? 'Abra o link enviado por e-mail para definir uma nova senha.'
        : AuthValidators.newPassword(password),
  );

  Future<bool> signOut() => _execute(_repository.signOut);

  void clearError() {
    if (_errorMessage == null && _sessionErrorMessage == null) return;
    _errorMessage = null;
    _sessionErrorMessage = null;
    _notify();
  }

  Future<bool> _execute(
    Future<void> Function() action, {
    String? validation,
  }) async {
    if (_isBusy || _disposed) return false;
    _errorMessage = validation;
    if (validation != null) {
      _notify();
      return false;
    }
    _isBusy = true;
    _notify();
    try {
      await action();
      _session = _repository.currentSession;
      return true;
    } catch (error) {
      _errorMessage = _messageFor(error);
      return false;
    } finally {
      _isBusy = false;
      _notify();
    }
  }

  String _messageFor(Object error) => error is AuthFailure
      ? error.message
      : 'Não foi possível concluir. Tente novamente em alguns instantes.';

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
