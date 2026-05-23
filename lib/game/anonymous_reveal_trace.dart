import 'package:google_maps_flutter/google_maps_flutter.dart';



/// 匿名痕跡の発生源（アナリスト表示用。対象者名は出さない）。

enum AnonymousTraceSource {

  periodic,

  camera,

  other,

}



/// 名前なしの位置痕跡（定期暴露・監視カメラなど）。

class AnonymousRevealTrace {

  const AnonymousRevealTrace({

    required this.timestamp,

    required this.position,

    required this.reasonSummary,

    required this.narrative,

    this.source = AnonymousTraceSource.other,

  });



  final DateTime timestamp;

  final LatLng position;

  final String reasonSummary;

  final String narrative;

  final AnonymousTraceSource source;

}

