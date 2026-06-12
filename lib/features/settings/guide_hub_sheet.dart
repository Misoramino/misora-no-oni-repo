import 'package:flutter/material.dart';

import '../game_map/widgets/how_to_play_sheet.dart';
import '../onboarding/onboarding_replay_sheet.dart';
import '../tutorial/tutorial_entry.dart';
import '../../game/player_role.dart';

/// ガイド・遊び方を設定とは別にまとめたハブ。
Future<void> showGuideHubSheet(
  BuildContext context, {
  PlayerRole? yourRole,
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
                leading: const Icon(Icons.auto_awesome_rounded),
                title: const Text('かんたんガイド'),
                subtitle: const Text('基本スライド・コーチマーク・初回リセット'),
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
                leading: const Icon(Icons.menu_book_outlined),
                title: const Text('作戦マニュアル'),
                subtitle: const Text('勝ち方・情報戦・告発・詳細ルール'),
                onTap: () {
                  Navigator.pop(ctx);
                  showHowToPlaySheet(
                    context,
                    yourRole: yourRole,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.school_rounded),
                title: const Text('チュートリアル'),
                subtitle: const Text('GPS不要・1〜2分で基本操作を体験'),
                onTap: () {
                  Navigator.pop(ctx);
                  openTutorialPicker(context);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
