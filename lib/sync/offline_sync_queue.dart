import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class OfflineSyncItem {
  const OfflineSyncItem({
    required this.id,
    required this.kind,
    required this.createdAtUtc,
    required this.payload,
  });

  final String id;
  final String kind;
  final String createdAtUtc;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'createdAtUtc': createdAtUtc,
        'payload': payload,
      };

  factory OfflineSyncItem.fromJson(Map<String, dynamic> json) {
    return OfflineSyncItem(
      id: json['id'] as String,
      kind: json['kind'] as String,
      createdAtUtc: json['createdAtUtc'] as String,
      payload: Map<String, dynamic>.from(json['payload'] as Map),
    );
  }
}

class OfflineSyncQueue {
  OfflineSyncQueue({this.storageKey = 'offline_sync_queue_v1'});

  final String storageKey;

  Future<List<OfflineSyncItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => OfflineSyncItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> push(OfflineSyncItem item, {int maxItems = 300}) async {
    final list = await load();
    list.add(item);
    if (list.length > maxItems) {
      list.removeRange(0, list.length - maxItems);
    }
    await _save(list);
  }

  Future<void> removeByIds(Set<String> ids) async {
    final list = await load();
    list.removeWhere((e) => ids.contains(e.id));
    await _save(list);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }

  Future<void> _save(List<OfflineSyncItem> list) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString(storageKey, raw);
  }
}
