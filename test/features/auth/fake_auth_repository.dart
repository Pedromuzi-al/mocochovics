import 'dart:async';

import 'package:mocochovisk/features/auth/domain/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this._session = const AuthSession()});

  AuthSession _session;
  final _changes = StreamController<AuthSession>.broadcast(sync: true);
  Completer<void>? pendingSignIn;
  Object? failure;
  int signInCalls = 0;
  int signUpCalls = 0;
  int resetCalls = 0;
  int updateCalls = 0;
  String? lastEmail;

  @override
  AuthSession get currentSession => _session;

  @override
  Stream<AuthSession> get sessionChanges => _changes.stream;

  void emit(AuthSession session) {
    _session = session;
    _changes.add(session);
  }

  void emitError(Object error) => _changes.addError(error);

  @override
  Future<void> signIn({required String email, required String password}) async {
    signInCalls++;
    lastEmail = email;
    await pendingSignIn?.future;
    _throwIfNeeded();
    emit(AuthSession(email: email, isAuthenticated: true));
  }

  @override
  Future<void> signUp({required String email, required String password}) async {
    signUpCalls++;
    lastEmail = email;
    _throwIfNeeded();
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    resetCalls++;
    lastEmail = email;
    _throwIfNeeded();
  }

  @override
  Future<void> updatePassword({required String password}) async {
    updateCalls++;
    _throwIfNeeded();
    emit(AuthSession(email: _session.email, isAuthenticated: true));
  }

  @override
  Future<void> signOut() async {
    _throwIfNeeded();
    emit(const AuthSession());
  }

  void _throwIfNeeded() {
    if (failure != null) throw failure!;
  }

  Future<void> dispose() => _changes.close();
}
