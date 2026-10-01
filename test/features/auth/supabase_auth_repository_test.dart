import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocochovisk/features/auth/data/auth_recovery_store.dart';
import 'package:mocochovisk/features/auth/data/supabase_auth_repository.dart';
import 'package:mocochovisk/features/auth/domain/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late _FakeAuthClient client;
  late _MemoryRecoveryStore store;
  late SupabaseAuthRepository repository;
  late StreamSubscription<AuthSession> subscription;
  late List<AuthSession> events;

  setUp(() {
    client = _FakeAuthClient();
    store = _MemoryRecoveryStore();
    repository = SupabaseAuthRepository.withAuthClient(
      client,
      redirectUrl: 'br.com.mocochovisk://login-callback',
      recoveryStore: store,
    );
    events = [];
    subscription = repository.sessionChanges.listen(events.add);
  });

  tearDown(() async {
    await subscription.cancel();
    await client.close();
  });

  Future<void> emit(AuthChangeEvent event) async {
    client.emit(event);
    await Future<void>.delayed(Duration.zero);
  }

  test(
    'restores recovery from persisted marker after restarting the app',
    () async {
      await emit(AuthChangeEvent.passwordRecovery);
      expect(store.pending, contains('owner-one'));
      expect(events.last.isPasswordRecovery, isTrue);
      await subscription.cancel();

      final restarted = SupabaseAuthRepository.withAuthClient(
        client,
        redirectUrl: 'br.com.mocochovisk://login-callback',
        recoveryStore: store,
      );
      subscription = restarted.sessionChanges.listen(events.add);
      await emit(AuthChangeEvent.initialSession);
      expect(events.last.isPasswordRecovery, isTrue);
      expect(restarted.currentSession.isPasswordRecovery, isTrue);
    },
  );

  test('refresh and signedIn events do not discard pending recovery', () async {
    await emit(AuthChangeEvent.passwordRecovery);
    await emit(AuthChangeEvent.tokenRefreshed);
    await emit(AuthChangeEvent.signedIn);
    expect(events.last.isPasswordRecovery, isTrue);
    expect(store.pending, contains('owner-one'));
  });

  test('recovery marker is isolated by user', () async {
    store.pending.add('another-owner');
    await emit(AuthChangeEvent.initialSession);
    expect(events.last.isPasswordRecovery, isFalse);
  });

  test(
    'failed password update preserves recovery and translates backend error',
    () async {
      await emit(AuthChangeEvent.passwordRecovery);
      client.failure = const AuthException(
        'sensitive-server-details',
        code: 'weak_password',
      );
      await expectLater(
        repository.updatePassword(password: 'password'),
        throwsA(
          isA<AuthFailure>().having(
            (failure) => failure.message,
            'message',
            'Escolha uma senha mais forte, com letras, números e símbolos.',
          ),
        ),
      );
      expect(store.pending, contains('owner-one'));
      expect(repository.currentSession.isPasswordRecovery, isTrue);
    },
  );

  test('successful password update clears recovery on disk', () async {
    await emit(AuthChangeEvent.passwordRecovery);
    await repository.updatePassword(password: 'newPassword123');
    await Future<void>.delayed(Duration.zero);
    expect(store.pending, isEmpty);
    expect(repository.currentSession.isPasswordRecovery, isFalse);
    await emit(AuthChangeEvent.initialSession);
    expect(events.last.isPasswordRecovery, isFalse);
  });

  test(
    'explicit login clears recovery, including concurrent signedIn event',
    () async {
      await emit(AuthChangeEvent.passwordRecovery);
      await repository.signIn(email: 'dono@bar.com', password: 'password123');
      await Future<void>.delayed(Duration.zero);
      expect(store.pending, isEmpty);
      expect(repository.currentSession.isPasswordRecovery, isFalse);
      expect(events.last.isPasswordRecovery, isFalse);
    },
  );

  test('local signout removes persisted recovery marker', () async {
    await emit(AuthChangeEvent.passwordRecovery);
    await repository.signOut();
    await Future<void>.delayed(Duration.zero);
    expect(client.signOutScope, SignOutScope.local);
    expect(store.pending, isEmpty);
    expect(repository.currentSession.isAuthenticated, isFalse);
  });
}

class _MemoryRecoveryStore implements AuthRecoveryStore {
  final pending = <String>{};

  @override
  Future<bool> isPending(String userId) async => pending.contains(userId);

  @override
  Future<void> setPending(String userId, {required bool pending}) async {
    if (pending) {
      this.pending.add(userId);
    } else {
      this.pending.remove(userId);
    }
  }
}

class _FakeAuthClient implements GoTrueClient {
  final _events = StreamController<AuthState>.broadcast(sync: true);
  Session? _session = Session(
    accessToken: 'test-token',
    tokenType: 'bearer',
    user: const User(
      id: 'owner-one',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      email: 'dono@bar.com',
      createdAt: '2026-09-30T00:00:00Z',
    ),
  );
  Object? failure;
  SignOutScope? signOutScope;

  @override
  Session? get currentSession => _session;

  @override
  User? get currentUser => _session?.user;

  @override
  Stream<AuthState> get onAuthStateChange => _events.stream;

  void emit(AuthChangeEvent event) => _events.add(AuthState(event, _session));

  @override
  Future<UserResponse> updateUser(
    UserAttributes attributes, {
    String? emailRedirectTo,
  }) async {
    if (failure != null) throw failure!;
    emit(AuthChangeEvent.userUpdated);
    return UserResponse.fromJson(currentUser!.toJson());
  }

  @override
  Future<AuthResponse> signInWithPassword({
    String? email,
    String? phone,
    required String password,
    String? captchaToken,
  }) async {
    if (failure != null) throw failure!;
    emit(AuthChangeEvent.signedIn);
    return AuthResponse(session: _session);
  }

  @override
  Future<void> signOut({SignOutScope scope = SignOutScope.local}) async {
    signOutScope = scope;
    _session = null;
    emit(AuthChangeEvent.signedOut);
  }

  Future<void> close() => _events.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
