import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../game/play_area.dart';

/// ホストが選んで適用する、名前付きプレイエリアの下書き一覧。
class SavedPlayArea {
  const SavedPlayArea({
    required this.id,
    required this.name,
    required this.area,
    required this.savedAtUtc,
  });

  final String id;
  final String name;
  final PlayArea area;
  final DateTime savedAtUtc;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'savedAtUtc': savedAtUtc.toUtc().toIso8601String(),
        'area': area.toJson(),
      };

  factory SavedPlayArea.fromJson(Map<String, dynamic> json) {
    return SavedPlayArea(
      id: json['id'] as String,
      name: json['name'] as String,
      savedAtUtc: DateTime.parse(json['savedAtUtc'] as String).toUtc(),
      area: PlayArea.fromJson(json['area'] as Map<String, dynamic>),
    );
  }
}

class PlayAreaSlotStore {
  PlayAreaSlotStore({this.storageKey = 'play_area_slots_v1'});

  final String storageKey;

  Future<List<SavedPlayArea>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => SavedPlayArea.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.savedAtUtc.compareTo(a.savedAtUtc));
    } catch (_) {
      return const [];
    }
  }

  Future<void> upsert(SavedPlayArea slot) async {
    final all = await loadAll();
    final next = [
      for (final s in all)
        if (s.id != slot.id) s,
      slot,
    ]..sort((a, b) => b.savedAtUtc.compareTo(a.savedAtUtc));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode(next.map((s) => s.toJson()).toList()),
    );
  }

  Future<void> remove(String id) async {
    final all = await loadAll();
    final next = all.where((s) => s.id != id).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode(next.map((s) => s.toJson()).toList()),
    );
  }
}
