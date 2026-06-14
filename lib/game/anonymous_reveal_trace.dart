import 'package:google_maps_flutter/google_maps_flutter.dart';

/// 不明な痕跡の発生源（アナリスト表示用。対象者名は出さない）。
enum AnonymousTraceSource {
  periodic,
  camera,
  /// パニック中の断続痕跡（旧 infection pulse）。
  panic,
  other,
}

/// 地図上の「不明な痕跡」（匿名位置暴露の結果。名前なし）。
class AnonymousRevealTrace {
  const AnonymousRevealTrace({
    required this.timestamp,
    required this.position,
    required this.reasonSummary,
    required this.narrative,
    this.source = AnonymousTraceSource.other,
    this.errorMeters = 0,
  });

  final DateTime timestamp;
  final LatLng position;
  final String reasonSummary;
  final String narrative;
  final AnonymousTraceSource source;

  /// 表示位置と実位置の距離（m）。信頼度表示に使う。
  final double errorMeters;
}
