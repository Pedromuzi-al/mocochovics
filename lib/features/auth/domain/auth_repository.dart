class AuthSession {
  const AuthSession({
    this.email,
    this.isAuthenticated = false,
    this.isPasswordRecovery = false,
  });

  final String? email;
  final bool isAuthenticated;
  final bool isPasswordRecovery;
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;
}

abstract interface class AuthRepository {
  AuthSession get currentSession;
  Stream<AuthSession> get sessionChanges;

  Future<void> signIn({required String email, required String password});
  Future<void> signUp({required String email, required String password});
  Future<void> sendPasswordReset({required String email});
  Future<void> updatePassword({required String password});
  Future<void> signOut();
}
