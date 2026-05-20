import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../game/game_state.dart';

/// 試合ティックの副作用（画面が適用する）。
sealed class MatchTickEffect {
  const MatchTickEffect();
}

final class MatchEndEffect extends MatchTickEffect {
  const MatchEndEffect({
    required this.state,
    required this.message,
    required this.heavyHaptic,
  });

  final GameState state;
  final String message;
  final bool heavyHaptic;
}

final class MatchStatusMessageEffect extends MatchTickEffect {
  const MatchStatusMessageEffect(this.message);
  final String message;
}

final class MatchConsumeSafeChargeEffect extends MatchTickEffect {
  const MatchConsumeSafeChargeEffect();
}

final class MatchAreaRevealEffect extends MatchTickEffect {
  const MatchAreaRevealEffect(this.overflowMeters);
  final double overflowMeters;
}

final class MatchResetOutsideTrackingEffect extends MatchTickEffect {
  const MatchResetOutsideTrackingEffect();
}

final class MatchOniCueEffect extends MatchTickEffect {
  const MatchOniCueEffect(this.level);
  final String level;
}

final class MatchEmitEventEffect extends MatchTickEffect {
  const MatchEmitEventEffect({
    required this.type,
    required this.message,
    required this.position,
  });

  final String type;
  final String message;
  final LatLng position;
}

final class MatchLocationRevealEmitEffect extends MatchTickEffect {
  const MatchLocationRevealEmitEffect({
    required this.type,
    required this.message,
    this.position,
  });

  final String type;
  final String message;
  /// 非 null のときこの座標を暴露（体投げ未回収＝人形位置など）。
  final LatLng? position;
}

final class MatchInfectionPulseRevealEffect extends MatchTickEffect {
  const MatchInfectionPulseRevealEffect();
}

final class MatchTouchLockStartEffect extends MatchTickEffect {
  const MatchTouchLockStartEffect({
    required this.radiusMeters,
    required this.endsAt,
  });

  final double radiusMeters;
  final DateTime endsAt;
}

final class MatchCameraSpottedEffect extends MatchTickEffect {
  const MatchCameraSpottedEffect({
    required this.index,
    required this.position,
    required this.message,
  });

  final int index;
  final LatLng position;
  final String message;
}
