import 'package:flutter_test/flutter_test.dart';
import 'package:mocochovisk/core/router/auth_redirect.dart';

void main() {
  group('Access to protected routes', () {
    test('an anonymous user cannot open app or recovery routes', () {
      for (final path in [
        '/inicio',
        '/extrato',
        '/produtos',
        '/fornecedores',
        '/mais/ingredientes',
        '/reset-password',
      ]) {
        expect(
          authRedirect(
            isAuthenticated: false,
            isRecoveringPassword: false,
            path: path,
          ),
          '/login',
          reason: path,
        );
      }
    });

    test('an anonymous user can log in, register and request recovery', () {
      for (final path in ['/login', '/register', '/forgot-password']) {
        expect(
          authRedirect(
            isAuthenticated: false,
            isRecoveringPassword: false,
            path: path,
          ),
          isNull,
          reason: path,
        );
      }
    });

    test('a normal session cannot open the recovery form directly', () {
      expect(
        authRedirect(
          isAuthenticated: true,
          isRecoveringPassword: false,
          path: '/reset-password',
        ),
        '/inicio',
      );
    });

    test('a recovery session is confined to setting a new password', () {
      for (final path in ['/inicio', '/mais/sobre', '/login']) {
        expect(
          authRedirect(
            isAuthenticated: true,
            isRecoveringPassword: true,
            path: path,
          ),
          '/reset-password',
          reason: path,
        );
      }
      expect(
        authRedirect(
          isAuthenticated: true,
          isRecoveringPassword: true,
          path: '/reset-password',
        ),
        isNull,
      );
    });
  });
}
