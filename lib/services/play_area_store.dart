import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../game/play_area.dart';

/// 端末ローカルにプレイエリアを保存（サーバー非接続時の下書き・次回起動復元用）。
class PlayAreaStore {
  PlayAreaStore({this.storageKey = 'play_area_v1'});

  final String storageKey;

  Future<PlayArea?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return PlayArea.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(PlayArea area) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(area.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }
}
