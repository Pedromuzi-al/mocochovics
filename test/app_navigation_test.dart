import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocochovisk/app.dart';
import 'package:mocochovisk/core/router/app_router.dart';
import 'package:mocochovisk/core/theme/app_theme.dart';
import 'package:mocochovisk/features/auth/domain/auth_repository.dart';
import 'package:mocochovisk/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mocochovisk/features/auth/presentation/pages/login_page.dart';
import 'package:mocochovisk/features/auth/presentation/pages/reset_password_page.dart';
import 'package:mocochovisk/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:mocochovisk/features/ingredients/presentation/pages/ingredients_page.dart';
import 'package:mocochovisk/features/settings/presentation/pages/about_page.dart';
import 'package:mocochovisk/features/settings/presentation/pages/settings_page.dart';

import 'features/auth/fake_auth_repository.dart';

const _signedIn = AuthSession(email: 'dono@bar.example', isAuthenticated: true);

Future<({FakeAuthRepository repository, GoRouter router})> _pumpApp(
  WidgetTester tester, {
  AuthSession session = _signedIn,
}) async {
  final repository = FakeAuthRepository(session: session);
  final container = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await repository.dispose();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MocochoviskApp(),
    ),
  );
  await tester.pumpAndSettle();
  return (repository: repository, router: container.read(appRouterProvider));
}

Finder _tab(String label) => find.descendant(
  of: find.byType(CupertinoTabBar),
  matching: find.text(label),
);

Future<void> _tapTab(WidgetTester tester, String label) async {
  await tester.tap(_tab(label));
  await tester.pumpAndSettle();
}

double _contrast(Color first, Color second) {
  final a = first.computeLuminance();
  final b = second.computeLuminance();
  return a > b ? (a + 0.05) / (b + 0.05) : (b + 0.05) / (a + 0.05);
}

void main() {
  testWidgets('an anonymous launch and protected deep link require login', (
    tester,
  ) async {
    final app = await _pumpApp(tester, session: const AuthSession());
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(CupertinoTabBar), findsNothing);

    app.router.go('/mais/ingredientes');
    await tester.pumpAndSettle();
    expect(app.router.routeInformationProvider.value.uri.path, '/login');
    expect(find.byType(IngredientsPage), findsNothing);
  });

  testWidgets('all five native tabs open their own routes', (tester) async {
    final app = await _pumpApp(tester);
    final tabs = tester.widget<CupertinoTabBar>(find.byType(CupertinoTabBar));
    expect(tabs.items, hasLength(5));
    expect(find.byType(DashboardPage), findsOneWidget);

    for (final entry in {
      'Extrato': '/extrato',
      'Produtos': '/produtos',
      'Fornecedores': '/fornecedores',
      'Mais': '/mais',
      'Início': '/inicio',
    }.entries) {
      await _tapTab(tester, entry.key);
      expect(app.router.routeInformationProvider.value.uri.path, entry.value);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('the five-tab shell fits a narrow screen with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pumpApp(tester);
    expect(tester.takeException(), isNull);

    for (final label in ['Extrato', 'Produtos', 'Fornecedores', 'Mais']) {
      await _tapTab(tester, label);
      expect(tester.takeException(), isNull, reason: label);
    }
  });

  testWidgets(
    'settings opens ingredients and about with native back navigation',
    (tester) async {
      final app = await _pumpApp(tester);
      await _tapTab(tester, 'Mais');
      expect(find.text('dono@bar.example'), findsOneWidget);
      await tester.tap(find.text('Ingredientes'));
      await tester.pumpAndSettle();
      expect(find.byType(IngredientsPage), findsOneWidget);
      expect(
        app.router.routeInformationProvider.value.uri.path,
        '/mais/ingredientes',
      );

      await tester.tap(find.byType(CupertinoNavigationBarBackButton).first);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(app.router.routeInformationProvider.value.uri.path, '/mais');

      await tester.ensureVisible(find.text('Sobre'));
      await tester.tap(find.text('Sobre'));
      await tester.pumpAndSettle();
      expect(find.byType(AboutPage), findsOneWidget);
      expect(find.text('Versão 0.1.0'), findsOneWidget);
      await tester.tap(find.byType(CupertinoNavigationBarBackButton).first);
      await tester.pumpAndSettle();
      expect(app.router.routeInformationProvider.value.uri.path, '/mais');
    },
  );

  testWidgets('signing out can be cancelled and then confirmed', (
    tester,
  ) async {
    final app = await _pumpApp(tester);
    await _tapTab(tester, 'Mais');
    await tester.ensureVisible(find.text('Sair da conta'));
    await tester.tap(find.text('Sair da conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(app.repository.currentSession.isAuthenticated, isTrue);

    await tester.tap(find.text('Sair da conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();
    expect(app.repository.currentSession.isAuthenticated, isFalse);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(CupertinoTabBar), findsNothing);
  });

  testWidgets('a sign-out failure keeps the session and explains the failure', (
    tester,
  ) async {
    final app = await _pumpApp(tester);
    app.repository.failure = const AuthFailure('Sem conexão. Tente novamente.');
    await _tapTab(tester, 'Mais');
    await tester.ensureVisible(find.text('Sair da conta'));
    await tester.tap(find.text('Sair da conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível sair'), findsOneWidget);
    expect(find.text('Sem conexão. Tente novamente.'), findsOneWidget);
    expect(app.repository.currentSession.isAuthenticated, isTrue);
    expect(app.router.routeInformationProvider.value.uri.path, '/mais');
  });

  testWidgets('losing the session removes a protected page immediately', (
    tester,
  ) async {
    final app = await _pumpApp(tester);
    app.router.go('/mais/sobre');
    await tester.pumpAndSettle();
    expect(find.byType(AboutPage), findsOneWidget);
    app.repository.emit(const AuthSession());
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(AboutPage), findsNothing);
    expect(app.router.routeInformationProvider.value.uri.path, '/login');
  });

  testWidgets('an expired auth link is explained while already signed in', (
    tester,
  ) async {
    final app = await _pumpApp(tester);
    app.repository.emitError(
      const AuthFailure('Este link expirou. Solicite um novo e-mail.'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível concluir o acesso'), findsOneWidget);
    expect(
      find.text('Este link expirou. Solicite um novo e-mail.'),
      findsOneWidget,
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoAlertDialog), findsNothing);
    expect(find.byType(DashboardPage), findsOneWidget);
  });

  testWidgets('password recovery cannot be bypassed by navigating to a tab', (
    tester,
  ) async {
    final app = await _pumpApp(
      tester,
      session: const AuthSession(
        email: 'dono@bar.example',
        isAuthenticated: true,
        isPasswordRecovery: true,
      ),
    );
    expect(find.byType(ResetPasswordPage), findsOneWidget);
    app.router.go('/produtos');
    await tester.pumpAndSettle();
    expect(
      app.router.routeInformationProvider.value.uri.path,
      '/reset-password',
    );
    expect(find.byType(CupertinoTabBar), findsNothing);

    app.repository.emit(_signedIn);
    await tester.pumpAndSettle();
    expect(find.byType(DashboardPage), findsOneWidget);
  });

  testWidgets('the app follows system brightness with readable action colors', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await _pumpApp(tester);

    for (final brightness in [Brightness.dark, Brightness.light]) {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      await tester.pumpAndSettle();
      final theme = CupertinoTheme.of(
        tester.element(find.byType(DashboardPage)),
      );
      expect(theme.brightness, brightness);
      final context = tester.element(find.byType(DashboardPage));
      expect(
        _contrast(
          AppTheme.secondaryTextColor.resolveFrom(context),
          CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(theme.primaryColor, theme.scaffoldBackgroundColor),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(theme.primaryColor, theme.primaryContrastingColor),
        greaterThanOrEqualTo(4.5),
      );
    }
  });
}
