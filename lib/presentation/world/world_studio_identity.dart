import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/world_profile.dart';
import 'world_studio_identity_catalog.dart';

/// 画面レイアウトのリズム（余白・対称性・密度）。
class WorldLayoutRhythm {
  const WorldLayoutRhythm({
    required this.screenPaddingH,
    required this.screenPaddingV,
    required this.sectionGap,
    required this.cardGap,
    required this.dialogPaddingH,
    required this.symmetric,
    required this.contentAlign,
    required this.cardFloat,
    required this.hudEdgeInset,
    required this.galleryHeroHeight,
  });

  final double screenPaddingH;
  final double screenPaddingV;
  final double sectionGap;
  final double cardGap;
  final double dialogPaddingH;
  final bool symmetric;
  final Alignment contentAlign;
  final double cardFloat;
  final double hudEdgeInset;
  final double galleryHeroHeight;

  EdgeInsets screenPadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final hPad = symmetric
        ? screenPaddingH
        : screenPaddingH + (w * 0.04).clamp(0, 24);
    return EdgeInsets.symmetric(horizontal: hPad, vertical: screenPaddingV);
  }

  EdgeInsets dialogInsets(BuildContext context) => EdgeInsets.symmetric(
        horizontal: dialogPaddingH,
        vertical: screenPaddingV + 8,
      );
}

/// アニメーションのテンポとカーブ。
class WorldMotionRhythm {
  const WorldMotionRhythm({
    required this.transitionMs,
    required this.reverseTransitionMs,
    required this.dialogMs,
    required this.buttonMs,
    required this.staggerMs,
    required this.enterCurve,
    required this.exitCurve,
    required this.emphasisCurve,
    required this.sheetCurve,
  });

  final int transitionMs;
  final int reverseTransitionMs;
  final int dialogMs;
  final int buttonMs;
  final int staggerMs;
  final Curve enterCurve;
  final Curve exitCurve;
  final Curve emphasisCurve;
  final Curve sheetCurve;

  Duration get transition => Duration(milliseconds: transitionMs);
  Duration get reverseTransition => Duration(milliseconds: reverseTransitionMs);
  Duration get dialog => Duration(milliseconds: dialogMs);
  Duration get button => Duration(milliseconds: buttonMs);
}

/// UI マイクロコピー（意味は維持、トーンのみ世界観化）。
class WorldMicrocopy {
  const WorldMicrocopy({
    required this.confirm,
    required this.cancel,
    required this.close,
    required this.next,
    required this.back,
    required this.loading,
    required this.gallerySelect,
    required this.coachNext,
    required this.coachDone,
  });

  final String confirm;
  final String cancel;
  final String close;
  final String next;
  final String back;
  final String loading;
  final String gallerySelect;
  final String coachNext;
  final String coachDone;
}

/// 触覚の性格。
enum WorldHapticCharacter {
  soft,
  refined,
  click,
  heavy,
  pulse,
  lightLong,
}

/// 無音・余韻設計（ミリ秒）。
class WorldSilenceRhythm {
  const WorldSilenceRhythm({
    required this.sfxLeadMs,
    required this.sfxTailMs,
    required this.transitionBreathMs,
    required this.resultPauseMs,
  });

  final int sfxLeadMs;
  final int sfxTailMs;
  final int transitionBreathMs;
  final int resultPauseMs;
}

/// マップシネマのカメラ気質（ゲーム性は維持、演出のみ）。
class WorldMapCameraRhythm {
  const WorldMapCameraRhythm({
    required this.tilt,
    required this.zoomOffset,
    required this.orbitScale,
    required this.shotDelayMs,
    required this.initialDelayMs,
    required this.bearingSpread,
  });

  final double tilt;
  final double zoomOffset;
  final double orbitScale;
  final int shotDelayMs;
  final int initialDelayMs;
  final double bearingSpread;
}

/// リザルト締めコピー。
class WorldResultCopy {
  const WorldResultCopy({
    required this.win,
    required this.lose,
    required this.draw,
    required this.spectator,
    required this.abort,
  });

  final String win;
  final String lose;
  final String draw;
  final String spectator;
  final String abort;
}

/// 1 世界観 = 1 スタジオの人格。
class WorldStudioIdentity {
  const WorldStudioIdentity({
    required this.profile,
    required this.layout,
    required this.motion,
    required this.microcopy,
    required this.haptic,
    required this.silence,
    required this.camera,
    required this.resultCopy,
    this.recommended = false,
    this.galleryBlurb,
  });

  final WorldProfile profile;
  final WorldLayoutRhythm layout;
  final WorldMotionRhythm motion;
  final WorldMicrocopy microcopy;
  final WorldHapticCharacter haptic;
  final WorldSilenceRhythm silence;
  final WorldMapCameraRhythm camera;
  final WorldResultCopy resultCopy;
  final bool recommended;
  final String? galleryBlurb;
}

/// 世界観別触覚（プレゼンテーション層のみ）。
abstract final class WorldHaptics {
  static void selection(WorldProfile profile) {
    _fire(WorldStudioIdentityCatalog.of(profile).haptic, light: true);
  }

  static void confirm(WorldProfile profile) {
    _fire(WorldStudioIdentityCatalog.of(profile).haptic);
  }

  static void emphasis(WorldProfile profile) {
    _fire(WorldStudioIdentityCatalog.of(profile).haptic, strong: true);
  }

  static void _fire(
    WorldHapticCharacter style, {
    bool light = false,
    bool strong = false,
  }) {
    switch (style) {
      case WorldHapticCharacter.soft:
        HapticFeedback.lightImpact();
      case WorldHapticCharacter.refined:
        if (strong) {
          HapticFeedback.mediumImpact();
        } else {
          HapticFeedback.selectionClick();
        }
      case WorldHapticCharacter.click:
        HapticFeedback.selectionClick();
      case WorldHapticCharacter.heavy:
        if (light) {
          HapticFeedback.mediumImpact();
        } else {
          HapticFeedback.heavyImpact();
        }
      case WorldHapticCharacter.pulse:
        HapticFeedback.mediumImpact();
      case WorldHapticCharacter.lightLong:
        HapticFeedback.lightImpact();
        if (!light) {
          Future<void>.delayed(const Duration(milliseconds: 48), () {
            HapticFeedback.selectionClick();
          });
        }
    }
  }
}
