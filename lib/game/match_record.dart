import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'game_state.dart';
import 'location_reveal_event.dart';
import 'match_event.dart';
import 'match_gimmick_layout.dart';
import 'play_area.dart';
import 'werewolf_faction_logic.dart';
import '../features/match/match_result_copy.dart';
import '../sync/firestore_room_blueprint.dart';
import '../theme/world_profile.dart';

/// 1地点・1時刻の軌跡サンプル。
class TrajectorySample {
  const TrajectorySample({
    required this.atUtc,
    required this.position,
  });

  final DateTime atUtc;
  final LatLng position;

  Map<String, dynamic> toJson() => {
        'at': atUtc.toIso8601String(),
        'lat': position.latitude,
        'lng': position.longitude,
      };

  static TrajectorySample fromJson(Map<String, dynamic> json) {
    return TrajectorySample(
      atUtc: DateTime.parse(json['at'] as String).toUtc(),
      position: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
    );
  }
}

/// 試合1回分の保存データ（端末ローカル）。将来はプレイヤーIDごとのトラックが増える。
class SavedMatchRecord {
  SavedMatchRecord({
    required this.version,
    required this.id,
    required this.startedAtUtc,
    required this.endedAtUtc,
    required this.outcome,
    required this.consentedToTrajectory,
    required this.playArea,
    required this.tracks,
    this.trackLabels = const {},
    this.trackKinds = const {},
    this.reveals = const [],
    this.events = const [],
    this.endReason,
    this.winningFaction,
    this.gimmickLayout,
    this.worldProfile,
    this.onlineRoomId,
    this.onlineSessionKey,
  });

  static const int currentVersion = 2;

  final int version;
  final String id;
  final DateTime startedAtUtc;
  final DateTime endedAtUtc;
  final GameState outcome;
  final bool consentedToTrajectory;
  final PlayArea playArea;

  /// 例: `runner_local`, `oni_local` … 同期時は Firebase uid に置き換え可能。
  final Map<String, List<TrajectorySample>> tracks;

  /// 再生 UI 用の表示名（観戦記録など）。
  final Map<String, String> trackLabels;

  /// 軌跡 ID → [ReplayTrackKind.name]（脱落後の線種・色分け用）。
  final Map<String, String> trackKinds;
  final List<LocationRevealEvent> reveals;
  final List<MatchEvent> events;
  final String? endReason;
  final FactionSide? winningFaction;
  final MatchGimmickLayout? gimmickLayout;

  /// 試合時の世界観（[WorldProfile.name]）。無い旧記録は再生時に現在設定へフォールバック。
  final String? worldProfile;

  /// ギャラリーから最新アーカイブ取得用（オンライン試合のみ）。
  final String? onlineRoomId;
  final int? onlineSessionKey;

  WorldProfile get effectiveWorldProfile =>
      WorldProfile.fromStorageName(worldProfile);

  /// ギャラリー一覧など向けの短い見出し。
  String get galleryTitle {
    if (endReason == MatchEndReason.hostAbort) return '試合中止';
    final headline = MatchResultCopy.outcomeHeadline(
      outcome: outcome,
      winningFaction: winningFaction,
      endReason: endReason,
    );
    return headline.subtitle != null &&
            headline.title != headline.subtitle &&
            headline.subtitle!.length <= 12
        ? '${headline.title}（${headline.subtitle}）'
        : headline.title;
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'id': id,
        'startedAtUtc': startedAtUtc.toIso8601String(),
        'endedAtUtc': endedAtUtc.toIso8601String(),
        'outcome': outcome.name,
        'consentedToTrajectory': consentedToTrajectory,
        'playArea': playArea.toJson(),
        'tracks': tracks.map(
          (k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()),
        ),
        if (trackLabels.isNotEmpty) 'trackLabels': trackLabels,
        if (trackKinds.isNotEmpty) 'trackKinds': trackKinds,
        'reveals': reveals.map((e) => e.toJson()).toList(),
        'events': events.map((e) => e.toJson()).toList(),
        if (endReason != null) 'endReason': endReason,
        if (winningFaction != null) 'winningFaction': winningFaction!.name,
        if (gimmickLayout != null) 'gimmickLayout': gimmickLayout!.toJson(),
        if (worldProfile != null) 'worldProfile': worldProfile,
        if (onlineRoomId != null) 'onlineRoomId': onlineRoomId,
        if (onlineSessionKey != null) 'onlineSessionKey': onlineSessionKey,
      };

  factory SavedMatchRecord.fromJson(Map<String, dynamic> json) {
    final trackMap = json['tracks'] as Map<String, dynamic>;
    final tracks = <String, List<TrajectorySample>>{};
    for (final e in trackMap.entries) {
      tracks[e.key] = (e.value as List<dynamic>)
          .map((item) => TrajectorySample.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return SavedMatchRecord(
      version: (json['version'] as num?)?.toInt() ?? 1,
      id: json['id'] as String,
      startedAtUtc: DateTime.parse(json['startedAtUtc'] as String).toUtc(),
      endedAtUtc: DateTime.parse(json['endedAtUtc'] as String).toUtc(),
      outcome: _parseOutcome(json['outcome'] as String?),
      consentedToTrajectory: json['consentedToTrajectory'] as bool,
      playArea: PlayArea.fromJson(json['playArea'] as Map<String, dynamic>),
      tracks: tracks,
      trackLabels: (json['trackLabels'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v as String)),
      trackKinds: (json['trackKinds'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v as String)),
      reveals: (json['reveals'] as List<dynamic>? ?? [])
          .map((r) => LocationRevealEvent.fromJson(r as Map<String, dynamic>))
          .toList(),
      events: (json['events'] as List<dynamic>? ?? [])
          .map((e) => MatchEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      endReason: json['endReason'] as String?,
      winningFaction: _parseFaction(json['winningFaction'] as String?),
      gimmickLayout: json['gimmickLayout'] == null
          ? null
          : MatchGimmickLayout.fromJson(
              json['gimmickLayout'] as Map<String, dynamic>,
            ),
      worldProfile: json['worldProfile'] as String?,
      onlineRoomId: json['onlineRoomId'] as String?,
      onlineSessionKey: (json['onlineSessionKey'] as num?)?.toInt(),
    );
  }

  static FactionSide? _parseFaction(String? name) {
    if (name == null) return null;
    for (final f in FactionSide.values) {
      if (f.name == name) return f;
    }
    return null;
  }

  static SavedMatchRecord decode(String raw) =>
      SavedMatchRecord.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());

  static GameState _parseOutcome(String? name) {
    if (name == null) return GameState.waiting;
    for (final s in GameState.values) {
      if (s.name == name) return s;
    }
    return GameState.waiting;
  }
}

/// 単調増加サンプル列から、時刻 t での位置を線形補間。
LatLng? interpolateAlongTrack(List<TrajectorySample> sorted, DateTime tUtc) {
  if (sorted.isEmpty) return null;
  if (!tUtc.isAfter(sorted.first.atUtc)) {
    return sorted.first.position;
  }
  if (!tUtc.isBefore(sorted.last.atUtc)) {
    return sorted.last.position;
  }
  var lo = 0;
  var hi = sorted.length - 1;
  while (hi - lo > 1) {
    final mid = (lo + hi) ~/ 2;
    if (sorted[mid].atUtc.isBefore(tUtc)) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  final a = sorted[lo];
  final b = sorted[hi];
  final span = b.atUtc.difference(a.atUtc).inMicroseconds;
  if (span <= 0) return b.position;
  final t =
      tUtc.difference(a.atUtc).inMicroseconds / span;
  final lat = a.position.latitude + (b.position.latitude - a.position.latitude) * t;
  final lng = a.position.longitude + (b.position.longitude - a.position.longitude) * t;
  return LatLng(lat, lng);
}
