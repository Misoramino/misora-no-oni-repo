import 'package:flutter/material.dart';

import '../../presentation/world/world_presentation_context.dart';
import '../../presentation/world/world_ui_helpers.dart';
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
  final profile = context.worldProfile;
  return showWorldSheet<void>(
    context,
    profile: profile,
    builder: (ctx) => WorldThemed(
      profile: profile,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: Text(
                  'ガイド・遊び方',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        color: ctx.worldPresentation.textOnScaffold,
                      ),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.auto_awesome_rounded,
                  color: ctx.worldPresentation.accentOnScaffold,
                ),
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
                leading: Icon(
                  Icons.menu_book_outlined,
                  color: ctx.worldPresentation.accentOnScaffold,
                ),
                title: const Text('遊び方'),
                subtitle: const Text('勝ち方・情報戦・告発・詳細ルール'),
                onTap: () {
                  Navigator.pop(ctx);
                  openHowToPlayManual(context, yourRole: yourRole);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.view_agenda_outlined,
                  color: ctx.worldPresentation.accentOnScaffold,
                ),
                title: const Text('遊び方（シート）'),
                subtitle: const Text('試合中と同じボトムシート表示'),
                onTap: () {
                  Navigator.pop(ctx);
                  openHowToPlayManual(
                    context,
                    yourRole: yourRole,
                    fullScreen: false,
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.school_rounded,
                  color: ctx.worldPresentation.accentOnScaffold,
                ),
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
      ),
    ),
  );
}
