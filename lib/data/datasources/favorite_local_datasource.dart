import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/app_failure.dart';

class FavoriteLocalDataSource {
  FavoriteLocalDataSource(this._preferences);

  static const String _favoriteKey = 'favorite_character_url';

  final SharedPreferencesAsync _preferences;

  Future<String?> getFavoriteUrl() async {
    try {
      return await _preferences.getString(_favoriteKey);
    } catch (_) {
      throw const PersistenceFailure('Could not restore the saved favorite.');
    }
  }

  Future<void> saveFavoriteUrl(String url) async {
    try {
      await _preferences.setString(_favoriteKey, url);
    } catch (_) {
      throw const PersistenceFailure();
    }
  }

  Future<void> clearFavorite() async {
    try {
      await _preferences.remove(_favoriteKey);
    } catch (_) {
      throw const PersistenceFailure();
    }
  }
}
