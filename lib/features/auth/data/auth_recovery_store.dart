import 'package:shared_preferences/shared_preferences.dart';

abstract interface class AuthRecoveryStore {
  Future<bool> isPending(String userId);
  Future<void> setPending(String userId, {required bool pending});
}

class PreferencesAuthRecoveryStore implements AuthRecoveryStore {
  final _preferences = SharedPreferencesAsync();

  String _key(String userId) => 'mocochovisk.auth.recovery.$userId';

  @override
  Future<bool> isPending(String userId) async =>
      await _preferences.getBool(_key(userId)) ?? false;

  @override
  Future<void> setPending(String userId, {required bool pending}) async {
    if (pending) {
      await _preferences.setBool(_key(userId), true);
    } else {
      await _preferences.remove(_key(userId));
    }
  }
}
