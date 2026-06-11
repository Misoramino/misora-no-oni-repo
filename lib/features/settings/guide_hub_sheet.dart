import 'package:flutter/material.dart';

import '../game_map/widgets/how_to_play_sheet.dart';
import '../onboarding/onboarding_replay_sheet.dart';
import '../../game/player_role.dart';

/// ガイド・遊び方を設定とは別にまとめたハブ。
Future<void> showGuideHubSheet(
  BuildContext context, {
  PlayerRole? yourRole,
  bool prepPhase = false,
  Future<void> Function()? showPrepCoachMarksNow,
  Future<void> Function()? showMatchCoachMarksNow,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: Text('ガイド・遊び方', style: theme.textTheme.titleLarge),
              ),
              ListTile(
                leading: const Icon(Icons.replay_rounded),
                title: const Text('かんたんガイド'),
                subtitle: const Text('初回チュートリアル・コーチマークの再視聴'),
                onTap: () {
                  Navigator.pop(ctx);
                  showOnboardingReplaySheet(
                    context,
                    showPrepCoachMarksNow: showPrepCoachMarksNow,
                    showMatchCoachMarksNow: showMatchCoachMarksNow,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline_rounded),
                title: const Text('遊び方'),
                subtitle: const Text('ルール・スキル・ギミック'),
                onTap: () {
                  Navigator.pop(ctx);
                  showHowToPlaySheet(
                    context,
                    yourRole: yourRole,
                    prepPhase: prepPhase,
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
