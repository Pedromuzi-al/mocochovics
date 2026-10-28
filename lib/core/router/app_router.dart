import '../widgets/app_interaction.dart';
import '../widgets/app_motion.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/ingredients/presentation/pages/ingredients_page.dart';
import '../../features/products/presentation/pages/products_page.dart';
import '../../features/settings/presentation/pages/about_page.dart';
import '../../features/settings/presentation/pages/cost_settings_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/statement/presentation/pages/statement_page.dart';
import '../../features/transactions/domain/statement_filter.dart';
import '../../features/suppliers/presentation/pages/suppliers_page.dart';
import '../../features/transactions/presentation/pages/categories_page.dart';
import '../../features/transactions/presentation/pages/recurring_page.dart';
import 'app_shell.dart';
import 'auth_redirect.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);
  final router = GoRouter(
    initialLocation: '/inicio',
    refreshListenable: auth,
    redirect: (context, state) => authRedirect(
      isAuthenticated: auth.isAuthenticated,
      isRecoveringPassword: auth.isRecoveringPassword,
      path: state.uri.path,
    ),
    routes: [
      _route('/login', const LoginPage()),
      _route('/register', const RegisterPage()),
      _route('/forgot-password', const ForgotPasswordPage()),
      _route('/reset-password', const ResetPasswordPage()),
      StatefulShellRoute(
        navigatorContainerBuilder: (context, shell, children) =>
            BranchTransition(index: shell.currentIndex, children: children),
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [_route('/inicio', const DashboardPage())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/extrato',
                pageBuilder: (context, state) => CupertinoPage<void>(
                  key: state.pageKey,
                  child: StatementPage(
                    key: ValueKey((state.uri.toString(), state.extra)),
                    initialFilter: StatementFilter.fromQueryParameters(
                      state.uri.queryParameters,
                    ),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [_route('/produtos', const ProductsPage())],
          ),
          StatefulShellBranch(
            routes: [_route('/fornecedores', const SuppliersPage())],
          ),
          StatefulShellBranch(
            routes: [
              _route(
                '/mais',
                const SettingsPage(),
                routes: [
                  _route('ingredientes', const IngredientsPage()),
                  _route('categorias', const CategoriesPage()),
                  _route('recorrencias', const RecurringPage()),
                  _route('configuracoes', const CostSettingsPage()),
                  _route('sobre', const AboutPage()),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Página indisponível'),
      ),
      child: SafeArea(
        child: Center(
          child: AppButton(
            onPressed: () => context.go('/inicio'),
            child: const Text('Voltar ao início'),
          ),
        ),
      ),
    ),
  );
  ref.onDispose(router.dispose);
  return router;
});

GoRoute _route(
  String path,
  Widget child, {
  List<RouteBase> routes = const [],
}) => GoRoute(
  path: path,
  pageBuilder: (context, state) => CupertinoPage<void>(
    key: state.pageKey,
    name: state.name,
    restorationId: state.pageKey.value,
    child: child,
  ),
  routes: routes,
);
