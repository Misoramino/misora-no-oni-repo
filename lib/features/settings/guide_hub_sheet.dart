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
                title: const Text('はじめてガイド'),
                subtitle: const Text('ゲームの流れをスライドで・コーチマーク再生'),
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
                  Icons.school_rounded,
                  color: ctx.worldPresentation.accentOnScaffold,
                ),
                title: const Text('チュートリアル'),
                subtitle: const Text('GPS不要・1〜2分で操作を体験'),
                onTap: () {
                  Navigator.pop(ctx);
                  openTutorialPicker(context);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.menu_book_outlined,
                  color: ctx.worldPresentation.accentOnScaffold,
                ),
                title: const Text('遊び方マニュアル'),
                subtitle: const Text('勝ち方・情報戦・告発などの詳細ルール'),
                onTap: () {
                  Navigator.pop(ctx);
                  openHowToPlayManual(context, yourRole: yourRole);
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
