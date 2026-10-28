import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppAppearance { system, light, dark }

extension AppAppearanceLabel on AppAppearance {
  String get label => switch (this) {
    AppAppearance.system => 'Sistema',
    AppAppearance.light => 'Claro',
    AppAppearance.dark => 'Escuro',
  };
}

class AppearanceSettings {
  const AppearanceSettings({
    this.appearance = AppAppearance.system,
    this.reduceTransparency = false,
    this.reduceMotion = false,
    this.saveFailed = false,
  });
  final AppAppearance appearance;
  final bool reduceTransparency, reduceMotion, saveFailed;

  Brightness brightness(Brightness system) => switch (appearance) {
    AppAppearance.system => system,
    AppAppearance.light => Brightness.light,
    AppAppearance.dark => Brightness.dark,
  };
}

class AppearanceStore {
  static const key = 'mocochovisk.appearance.v1';
  Future<String?> read() => SharedPreferencesAsync().getString(key);
  Future<void> write(String value) =>
      SharedPreferencesAsync().setString(key, value);
}

final appearanceStoreProvider = Provider<AppearanceStore>(
  (ref) => AppearanceStore(),
);
final appearanceProvider =
    NotifierProvider<AppearanceController, AppearanceSettings>(
      AppearanceController.new,
    );

class AppearanceController extends Notifier<AppearanceSettings> {
  int _revision = 0;
  Future<void> _writes = Future.value();

  @override
  AppearanceSettings build() {
    unawaited(_restore());
    return const AppearanceSettings();
  }

  Future<void> _restore() async {
    try {
      final saved = await ref.read(appearanceStoreProvider).read();
      if (!ref.mounted || _revision != 0 || saved == null) return;
      final data = jsonDecode(saved) as Map<String, dynamic>;
      state = AppearanceSettings(
        appearance: AppAppearance.values.firstWhere(
          (value) => value.name == data['appearance'],
          orElse: () => AppAppearance.system,
        ),
        reduceTransparency: data['reduceTransparency'] == true,
        reduceMotion: data['reduceMotion'] == true,
      );
    } catch (_) {
      // A blocked browser storage must not prevent the app from opening.
    }
  }

  Future<void> update({
    AppAppearance? appearance,
    bool? reduceTransparency,
    bool? reduceMotion,
  }) {
    final revision = ++_revision;
    state = AppearanceSettings(
      appearance: appearance ?? state.appearance,
      reduceTransparency: reduceTransparency ?? state.reduceTransparency,
      reduceMotion: reduceMotion ?? state.reduceMotion,
    );
    final value = jsonEncode({
      'appearance': state.appearance.name,
      'reduceTransparency': state.reduceTransparency,
      'reduceMotion': state.reduceMotion,
    });
    final store = ref.read(appearanceStoreProvider);
    _writes = _writes.then((_) async {
      try {
        await store.write(value);
      } catch (_) {
        if (ref.mounted && revision == _revision) {
          state = AppearanceSettings(
            appearance: state.appearance,
            reduceTransparency: state.reduceTransparency,
            reduceMotion: state.reduceMotion,
            saveFailed: true,
          );
        }
      }
    });
    return _writes;
  }
}
