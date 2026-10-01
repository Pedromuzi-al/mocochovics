import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocochovisk/features/auth/domain/auth_repository.dart';
import 'package:mocochovisk/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mocochovisk/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:mocochovisk/features/auth/presentation/pages/login_page.dart';
import 'package:mocochovisk/features/auth/presentation/pages/register_page.dart';
import 'package:mocochovisk/features/auth/presentation/pages/reset_password_page.dart';

import 'fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late GoRouter router;

  setUp(() {
    repository = FakeAuthRepository();
    router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
        GoRoute(path: '/register', builder: (_, _) => const RegisterPage()),
        GoRoute(
          path: '/forgot-password',
          builder: (_, _) => const ForgotPasswordPage(),
        ),
        GoRoute(
          path: '/reset-password',
          builder: (_, _) => const ResetPasswordPage(),
        ),
        GoRoute(
          path: '/inicio',
          builder: (_, _) => const CupertinoPageScaffold(child: Text('Início')),
        ),
      ],
    );
  });

  tearDown(() async {
    router.dispose();
    await repository.dispose();
  });

  Future<void> pumpApp(WidgetTester tester, {double textScale = 1}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: CupertinoApp.router(
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('login displays inline validation without requesting auth', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Informe seu e-mail.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);
    expect(repository.signInCalls, 0);
  });

  testWidgets('login shows loading and opens home on success', (tester) async {
    repository.pendingSignIn = Completer<void>();
    await pumpApp(tester);
    await tester.enterText(
      find.byType(CupertinoTextFormFieldRow).at(0),
      'dono@bar.com',
    );
    await tester.enterText(
      find.byType(CupertinoTextFormFieldRow).at(1),
      'senha123',
    );
    await tester.tap(find.text('Entrar'));
    await tester.pump();
    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    expect(repository.signInCalls, 1);
    repository.pendingSignIn!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Início'), findsOneWidget);
  });

  testWidgets(
    'forgot password confirms submission without exposing account existence',
    (tester) async {
      await pumpApp(tester);
      router.go('/forgot-password');
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(CupertinoTextFormFieldRow),
        'dono@bar.com',
      );
      await tester.tap(find.text('Enviar link'));
      await tester.pumpAndSettle();
      expect(repository.resetCalls, 1);
      expect(find.text('Confira seu e-mail'), findsOneWidget);
      expect(find.textContaining('Se houver uma conta'), findsOneWidget);
    },
  );

  testWidgets('registration validates matching passwords', (tester) async {
    await pumpApp(tester);
    router.go('/register');
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(CupertinoTextFormFieldRow).at(0),
      'dono@bar.com',
    );
    await tester.enterText(
      find.byType(CupertinoTextFormFieldRow).at(1),
      'senha123',
    );
    await tester.enterText(
      find.byType(CupertinoTextFormFieldRow).at(2),
      'outraSenha',
    );
    await tester.ensureVisible(find.text('Criar conta'));
    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();
    expect(find.text('As senhas precisam ser iguais.'), findsOneWidget);
    expect(repository.signUpCalls, 0);
  });

  testWidgets('recovery password can be saved with a recovery session', (
    tester,
  ) async {
    repository.emit(
      const AuthSession(
        email: 'dono@bar.com',
        isAuthenticated: true,
        isPasswordRecovery: true,
      ),
    );
    await pumpApp(tester);
    router.go('/reset-password');
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(CupertinoTextFormFieldRow).at(0),
      'novaSenha123',
    );
    await tester.enterText(
      find.byType(CupertinoTextFormFieldRow).at(1),
      'novaSenha123',
    );
    await tester.tap(find.text('Salvar nova senha'));
    await tester.pumpAndSettle();
    expect(repository.updateCalls, 1);
    expect(find.text('Início'), findsOneWidget);
  });

  testWidgets('login fits a narrow screen with enlarged text', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpApp(tester, textScale: 2);
    await tester.ensureVisible(find.text('Criar uma conta'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Criar uma conta'), findsOneWidget);
  });
}
