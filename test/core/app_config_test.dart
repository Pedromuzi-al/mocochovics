import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocochovisk/core/supabase/app_config.dart';

const _projectUrl = 'https://example-project.supabase.co';
const _publicKey = 'sb_publishable_test_key_for_configuration';

String _jwtWithRole(String role) {
  String encode(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${encode({'alg': 'HS256', 'typ': 'JWT'})}.'
      '${encode({'role': role})}.test-signature';
}

void main() {
  test('missing configuration explains both required values', () {
    const config = AppConfig(supabaseUrl: '', supabaseKey: '');
    expect(config.validationErrors, hasLength(2));
    expect(config.validationErrors.first, contains('SUPABASE_URL'));
    expect(config.validationErrors.last, contains('SUPABASE_PUBLISHABLE_KEY'));
  });

  test('accepts a publishable key and a legacy anon JWT', () {
    for (final key in [_publicKey, _jwtWithRole('anon')]) {
      final config = AppConfig(supabaseUrl: _projectUrl, supabaseKey: key);
      expect(config.validationErrors, isEmpty);
    }
  });

  test('rejects secret, service-role and malformed client keys', () {
    for (final key in [
      'sb_secret_do_not_ship_this_to_a_client',
      _jwtWithRole('service_role'),
      _jwtWithRole('authenticated'),
      'malformed.key.value',
      'sb_publishable_',
    ]) {
      final config = AppConfig(supabaseUrl: _projectUrl, supabaseKey: key);
      expect(config.validationErrors, isNotEmpty);
    }
  });

  test('requires HTTPS for remote Supabase servers', () {
    for (final url in [
      'http://example-project.supabase.co',
      'ftp://example-project.supabase.co',
      'https://user:password@example-project.supabase.co',
      'https://example-project.supabase.co?token=value',
      'https://example-project.supabase.co#fragment',
      'https://SEU-PROJETO.supabase.co',
    ]) {
      final config = AppConfig(supabaseUrl: url, supabaseKey: _publicKey);
      expect(config.validationErrors, isNotEmpty, reason: url);
    }
  });

  test('allows HTTP for local Supabase development and Android emulator', () {
    for (final url in [
      'http://localhost:54321',
      'http://127.0.0.1:54321',
      'http://10.0.2.2:54321',
    ]) {
      final config = AppConfig(supabaseUrl: url, supabaseKey: _publicKey);
      expect(config.validationErrors, isEmpty, reason: url);
    }
  });

  test('uses a native callback and permits explicit web callbacks', () {
    const native = AppConfig(supabaseUrl: _projectUrl, supabaseKey: _publicKey);
    expect(native.authRedirectUrl, 'br.com.mocochovisk.app://login-callback');
    for (final redirect in [
      'br.com.mocochovisk.app://login-callback',
      'https://bar.example.com/',
      'http://localhost:8080/',
    ]) {
      final config = AppConfig(
        supabaseUrl: _projectUrl,
        supabaseKey: _publicKey,
        redirectUrl: redirect,
      );
      expect(config.validationErrors, isEmpty);
      expect(config.authRedirectUrl, redirect);
    }
  });

  test('rejects insecure remote and unrelated native callbacks', () {
    for (final redirect in [
      'http://bar.example.com/',
      'anotherapp://login-callback',
      'br.com.mocochovisk.app://unknown',
    ]) {
      final config = AppConfig(
        supabaseUrl: _projectUrl,
        supabaseKey: _publicKey,
        redirectUrl: redirect,
      );
      expect(config.validationErrors, isNotEmpty);
    }
  });
}
