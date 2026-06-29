import 'package:flutter/material.dart';

import '../../../game/player_role.dart';
import '../../../presentation/world/world_presentation_context.dart';
import '../../../presentation/world/world_ui_helpers.dart';
import '../../how_to_play/how_to_play_screen.dart';
import '../../how_to_play/widgets/how_to_play_guide_body.dart';

/// 作戦マニュアル（試合中など手早く開くボトムシート）。
Future<void> showHowToPlaySheet(
  BuildContext context, {
  PlayerRole? yourRole,
  String? initialSectionId,
  String? initialSpecCardId,
  String? initialGuideCardId,
}) {
  final profile = context.worldProfile;
  return showWorldSheet<void>(
    context,
    profile: profile,
    builder: (sheetCtx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        builder: (_, scrollController) => HowToPlayGuideBody(
          scrollController: scrollController,
          yourRole: yourRole,
          initialSectionId: initialSectionId,
          initialSpecCardId: initialSpecCardId,
          initialGuideCardId: initialGuideCardId,
        ),
      ),
  );
}

/// 作戦マニュアルを全画面で開く（ガイドハブ・タイトル向け）。
void openHowToPlayManual(
  BuildContext context, {
  PlayerRole? yourRole,
  String? initialSectionId,
  String? initialSpecCardId,
  String? initialGuideCardId,
  bool fullScreen = true,
}) {
  if (fullScreen) {
    openHowToPlayScreen(
      context,
      yourRole: yourRole,
      initialSectionId: initialSectionId,
      initialSpecCardId: initialSpecCardId,
      initialGuideCardId: initialGuideCardId,
    );
  } else {
    showHowToPlaySheet(
      context,
      yourRole: yourRole,
      initialSectionId: initialSectionId,
      initialSpecCardId: initialSpecCardId,
      initialGuideCardId: initialGuideCardId,
    );
  }
}
