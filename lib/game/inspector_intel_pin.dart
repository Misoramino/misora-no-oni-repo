import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../sync/remote_member_snapshot.dart';
import '../sync/shared_match_snapshot.dart';
import 'location_reveal_event.dart';
import 'player_role.dart';

/// 観戦者向け「最終判明位置」（ライブ GPS ではなくイベント由来）。
class InspectorIntelPin {
  const InspectorIntelPin({
    required this.uid,
    required this.label,
    required this.role,
    required this.position,
    required this.updatedAt,
    required this.sourceLabel,
    this.eliminated = false,
  });

  final String uid;
  final String label;
  final PlayerRole role;
  final LatLng position;
  final DateTime updatedAt;
  final String sourceLabel;
  final bool eliminated;
}

/// 試合参加者のイベント由来位置を集約（インスペクター地図用）。
abstract final class InspectorIntelPinLogic {
  static List<InspectorIntelPin> build({
    required Map<String, SharedPlayerAssignment> assignments,
    required Map<String, RemoteMemberSnapshot> remoteMembers,
    required Iterable<LocationRevealEvent> revealLog,
    required Map<String, LatLng> hunterPositions,
    required Set<String> eliminatedUids,
    required DateTime now,
  }) {
    if (assignments.isEmpty) return const [];

    final latest = <String, ({LatLng pos, DateTime at, String source})>{};

    for (final e in revealLog) {
      final uid = e.subjectUid;
      if (uid == null || uid.isEmpty) continue;
      _upsert(latest, uid, e.position, e.timestamp, e.reasonSummary ?? '暴露');
    }

    for (final e in hunterPositions.entries) {
      _upsert(latest, e.key, e.value, now, '鬼位置');
    }

    final out = <InspectorIntelPin>[];
    for (final e in assignments.entries) {
      final uid = e.key;
      final intel = latest[uid];
      if (intel == null) continue;
      final member = remoteMembers[uid];
      final nickname = member?.nickname ?? '';
      final label = nickname.isNotEmpty ? nickname : _fallbackLabel(uid);
      out.add(
        InspectorIntelPin(
          uid: uid,
          label: label,
          role: e.value.role,
          position: intel.pos,
          updatedAt: intel.at,
          sourceLabel: intel.source,
          eliminated: eliminatedUids.contains(uid),
        ),
      );
    }
    out.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return out;
  }

  static void _upsert(
    Map<String, ({LatLng pos, DateTime at, String source})> latest,
    String uid,
    LatLng pos,
    DateTime at,
    String source,
  ) {
    final prev = latest[uid];
    if (prev == null || at.isAfter(prev.at)) {
      latest[uid] = (pos: pos, at: at, source: source);
    }
  }

  static String _fallbackLabel(String uid) {
    if (uid.length <= 6) return uid;
    return '${uid.substring(0, 6)}…';
  }
}
