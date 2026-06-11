import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/game/camera_shutdown_logic.dart';
import 'package:oni_game/game/elimination_aftermath_rule.dart';
import 'package:oni_game/game/facility_sabotage_logic.dart';
import 'package:oni_game/game/spectral_territory_logic.dart';
import 'package:oni_game/theme/elimination_role_copy.dart';
import 'package:oni_game/theme/world_profile.dart';

void main() {
  final now = DateTime.utc(2026, 1, 1, 12);

  group('second-game player experience', () {
    test('joinOni role title is consistent', () {
      final copy = EliminationRoleCopy.forProfile(
        WorldProfile.arg,
        EliminationAftermathRule.joinOni,
      );
      expect(copy.roleTitle, '鬼側合流');
    });

    test('spectral operative copy matches rule capabilities', () {
      final copy = EliminationRoleCopy.forProfile(
        WorldProfile.horror,
        EliminationAftermathRule.spectralOperative,
      );
      expect(copy.roleTitle, '残響体');
      expect(
        EliminationAftermathRule.spectralOperative.supportsCameraJack,
        isTrue,
      );
      expect(
        EliminationAftermathRule.spectralOperative.supportsSpectralTerritoryCharge,
        isTrue,
      );
    });

    test('revenant oni can start facility sabotage when eligible', () {
      final copy = EliminationRoleCopy.forProfile(
        WorldProfile.sciFi,
        EliminationAftermathRule.revenantOni,
      );
      expect(copy.roleTitle, '復讐の鬼影');
      expect(
        FacilitySabotageLogic.canStartCharge(
          isEliminated: true,
          isRevenantOni: true,
          matchUses: 0,
          lastPersonalAt: null,
          now: now,
          alreadyCharging: false,
        ),
        isTrue,
      );
    });

    test('camera shutdown blocked for already disabled camera', () {
      expect(
        CameraShutdownLogic.canStartShutdown(
          isEliminated: true,
          isRevenantOni: true,
          cameraIndex: 0,
          disabledCameraIndices: const {0},
          lastPersonalAt: null,
          now: now,
          alreadyCharging: false,
        ),
        isFalse,
      );
      expect(
        CameraShutdownLogic.canStartShutdown(
          isEliminated: true,
          isRevenantOni: true,
          cameraIndex: 1,
          disabledCameraIndices: const {0},
          lastPersonalAt: null,
          now: now,
          alreadyCharging: false,
        ),
        isTrue,
      );
    });

    test('spectral territory respects match use limit', () {
      expect(
        SpectralTerritoryLogic.canStartCharge(
          isEliminated: true,
          isSpectralOperative: true,
          accusationUnlocked: true,
          matchUses: 0,
          lastPersonalAt: null,
          now: now,
          alreadyCharging: false,
        ),
        isTrue,
      );
      expect(
        SpectralTerritoryLogic.canStartCharge(
          isEliminated: true,
          isSpectralOperative: true,
          accusationUnlocked: true,
          matchUses: 99,
          lastPersonalAt: null,
          now: now,
          alreadyCharging: false,
        ),
        isFalse,
      );
    });
  });
}
