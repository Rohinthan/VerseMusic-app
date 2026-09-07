import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/storage/database_service.dart';

class LyricsOnlineFetchNotifier extends Notifier<bool> {
  static const String _prefKey = 'lyrics_online_fetch_enabled';

  @override
  bool build() {
    _loadFromPreferences();
    return true; // Default enabled
  }

  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getBool(_prefKey);
      if (val != null) {
        state = val;
      }
    } catch (_) {}
  }

  Future<void> toggle(bool enabled) async {
    state = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, enabled);
    } catch (_) {}
  }
}

final lyricsOnlineFetchProvider =
    NotifierProvider<LyricsOnlineFetchNotifier, bool>(
        LyricsOnlineFetchNotifier.new);

class SettingsService {
  final DatabaseService _dbService;

  SettingsService({DatabaseService? dbService})
      : _dbService = dbService ?? DatabaseService();

  Future<void> clearLyricsCache() async {
    await _dbService.clearLyricsCache();
  }
}

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});
