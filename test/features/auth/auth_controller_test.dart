import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocochovisk/features/auth/domain/auth_repository.dart';
import 'package:mocochovisk/features/auth/presentation/controllers/auth_controller.dart';

import 'fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late AuthController controller;

  setUp(() {
    repository = FakeAuthRepository();
    controller = AuthController(repository);
  });

  tearDown(() async {
    controller.dispose();
    await repository.dispose();
  });

  test('restores an existing session immediately', () async {
    final persisted = FakeAuthRepository(
      session: const AuthSession(email: 'dono@bar.com', isAuthenticated: true),
    );
    final restored = AuthController(persisted);
    expect(restored.isAuthenticated, isTrue);
    expect(restored.email, 'dono@bar.com');
    restored.dispose();
    await persisted.dispose();
  });

  test('validates input before making a network request', () async {
    expect(
      await controller.signIn(email: 'email inválido', password: 'senha'),
      isFalse,
    );
    expect(repository.signInCalls, 0);
    expect(controller.errorMessage, 'Digite um e-mail válido.');
    expect(
      await controller.signUp(email: 'dono@bar.com', password: '123'),
      isFalse,
    );
    expect(repository.signUpCalls, 0);
  });

  test('prevents duplicate requests and publishes loading state', () async {
    repository.pendingSignIn = Completer<void>();
    final first = controller.signIn(
      email: ' dono@bar.com ',
      password: 'senha123',
    );
    expect(controller.isBusy, isTrue);
    expect(
      await controller.signIn(email: 'dono@bar.com', password: 'senha123'),
      isFalse,
    );
    expect(repository.signInCalls, 1);
    repository.pendingSignIn!.complete();
    expect(await first, isTrue);
    expect(repository.lastEmail, 'dono@bar.com');
    expect(controller.isBusy, isFalse);
    expect(controller.isAuthenticated, isTrue);
  });

  test('signup requiring confirmation does not authenticate', () async {
    expect(
      await controller.signUp(email: 'dono@bar.com', password: 'senha123'),
      isTrue,
    );
    expect(controller.isAuthenticated, isFalse);
    expect(controller.errorMessage, isNull);
  });

  test('requires a session to set a new password', () async {
    expect(await controller.updatePassword(password: 'novaSenha123'), isFalse);
    expect(repository.updateCalls, 0);
  });

  test('recovery stays active until password is updated', () async {
    repository.emit(
      const AuthSession(
        email: 'dono@bar.com',
        isAuthenticated: true,
        isPasswordRecovery: true,
      ),
    );
    expect(controller.isRecoveringPassword, isTrue);
    expect(await controller.updatePassword(password: 'novaSenha123'), isTrue);
    expect(controller.isRecoveringPassword, isFalse);
    expect(controller.isAuthenticated, isTrue);
  });

  test('signing out clears the current session and recovery state', () async {
    repository.emit(
      const AuthSession(
        email: 'dono@bar.com',
        isAuthenticated: true,
        isPasswordRecovery: true,
      ),
    );
    expect(await controller.signOut(), isTrue);
    expect(controller.isAuthenticated, isFalse);
    expect(controller.isRecoveringPassword, isFalse);
    expect(controller.email, isNull);
  });

  test('does not expose unexpected exception details', () async {
    repository.failure = StateError('secret-access-token');
    expect(
      await controller.signIn(email: 'dono@bar.com', password: 'senha123'),
      isFalse,
    );
    expect(controller.errorMessage, isNot(contains('secret-access-token')));
    expect(
      controller.errorMessage,
      'Não foi possível concluir. Tente novamente em alguns instantes.',
    );
    expect(controller.isBusy, isFalse);
  });

  test('receives session stream errors without an unhandled exception', () {
    repository.emitError(const AuthFailure('Sua sessão expirou.'));
    expect(controller.errorMessage, 'Sua sessão expirou.');
    controller.clearError();
    expect(controller.errorMessage, isNull);
  });

  test(
    'finishing a request after disposal does not notify listeners',
    () async {
      final delayed = FakeAuthRepository()..pendingSignIn = Completer<void>();
      final disposable = AuthController(delayed);
      final request = disposable.signIn(
        email: 'dono@bar.com',
        password: 'senha123',
      );
      disposable.dispose();
      delayed.pendingSignIn!.complete();
      await expectLater(request, completion(isTrue));
      await delayed.dispose();
    },
  );
}
