import 'dart:convert';

import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseKey,
    this.redirectUrl = '',
  });

  factory AppConfig.fromEnvironment() {
    const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
    return const AppConfig(
      supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
      supabaseKey: publishableKey != ''
          ? publishableKey
          : String.fromEnvironment('SUPABASE_ANON_KEY'),
      redirectUrl: String.fromEnvironment('AUTH_REDIRECT_URL'),
    );
  }

  final String supabaseUrl;
  final String supabaseKey;
  final String redirectUrl;

  String get authRedirectUrl {
    if (redirectUrl.isNotEmpty) return redirectUrl;
    if (kIsWeb) {
      final base = Uri.base;
      return Uri(
        scheme: base.scheme,
        host: base.host,
        port: base.hasPort ? base.port : null,
        path: base.path,
      ).toString();
    }
    return 'br.com.mocochovisk.app://login-callback';
  }

  List<String> get validationErrors {
    final errors = <String>[];
    final uri = Uri.tryParse(supabaseUrl);
    if (uri == null ||
        uri.host.isEmpty ||
        !_isAllowedServer(uri) ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        supabaseUrl.contains('SEU-PROJETO')) {
      errors.add('Informe a URL do seu projeto em SUPABASE_URL.');
    }
    if (!_isPublicKey(supabaseKey)) {
      errors.add(
        'Informe uma chave publishable ou anon em SUPABASE_PUBLISHABLE_KEY. '
        'Chaves secret e service_role não são aceitas.',
      );
    }
    if (redirectUrl.isNotEmpty) {
      final redirect = Uri.tryParse(redirectUrl);
      if (redirect == null ||
          redirect.host.isEmpty ||
          !(_isAllowedServer(redirect) ||
              (redirect.scheme == 'br.com.mocochovisk.app' &&
                  redirect.host == 'login-callback'))) {
        errors.add(
          'Configure AUTH_REDIRECT_URL com um endereço de retorno válido.',
        );
      }
    }
    return errors;
  }

  static bool _isAllowedServer(Uri uri) =>
      uri.scheme == 'https' ||
      (uri.scheme == 'http' &&
          const [
            'localhost',
            '127.0.0.1',
            '10.0.2.2',
            '::1',
          ].contains(uri.host));

  static bool _isPublicKey(String key) {
    if (key.startsWith('sb_publishable_') && key.length > 20) return true;
    final parts = key.split('.');
    if (parts.length != 3) return false;
    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      return payload is Map<String, dynamic> && payload['role'] == 'anon';
    } on FormatException {
      return false;
    }
  }
}
