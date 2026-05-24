import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../session/avatar_thumb_codec.dart';
import '../../../sync/remote_member_snapshot.dart';
import '../../../theme/world_profile_tokens.dart';
import 'avatar_pin_compositor.dart';

/// 他プレイヤーの暴露ピン用アイコン（members のサムネから非同期生成）。
class RevealAvatarIconCache {
  final Map<String, BitmapDescriptor> iconsByUid = {};
  final Map<String, Future<void>> _inFlight = {};

  BitmapDescriptor? iconFor(String? uid) {
    if (uid == null || uid.isEmpty) return null;
    return iconsByUid[uid];
  }

  Future<void> ingestMembers(
    Map<String, RemoteMemberSnapshot> members, {
    required WorldProfileTokens tokens,
    required void Function() onUpdated,
  }) async {
    final tasks = <Future<void>>[];
    for (final e in members.entries) {
      final b64 = e.value.avatarThumbB64;
      if (b64 == null || b64.isEmpty) continue;
      if (iconsByUid.containsKey(e.key)) continue;
      tasks.add(_ensure(e.key, b64, tokens, onUpdated));
    }
    if (tasks.isNotEmpty) await Future.wait(tasks);
  }

  Future<void> _ensure(
    String uid,
    String thumbB64,
    WorldProfileTokens tokens,
    void Function() onUpdated,
  ) async {
    if (iconsByUid.containsKey(uid)) return;
    final existing = _inFlight[uid];
    if (existing != null) {
      await existing;
      return;
    }
    final task = _load(uid, thumbB64, tokens, onUpdated);
    _inFlight[uid] = task;
    try {
      await task;
    } finally {
      _inFlight.remove(uid);
    }
  }

  Future<void> _load(
    String uid,
    String thumbB64,
    WorldProfileTokens tokens,
    void Function() onUpdated,
  ) async {
    try {
      final bytes = AvatarThumbCodec.decode(thumbB64);
      if (bytes == null) return;
      final icon = await AvatarPinCompositor.fromBytes(
        imageBytes: bytes,
        tokens: tokens,
        revealedStyle: true,
        iconScale: 0.85,
      );
      if (icon == null) return;
      iconsByUid[uid] = icon;
      onUpdated();
    } catch (_) {}
  }

  void clear() => iconsByUid.clear();
}
