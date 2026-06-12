import 'package:flutter/material.dart';

import '../../../game/player_role.dart';
import '../../how_to_play/widgets/how_to_play_guide_body.dart';

/// 作戦マニュアル（遊び方）ボトムシート。
void showHowToPlaySheet(
  BuildContext context, {
  PlayerRole? yourRole,
  String? initialSectionId,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetCtx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (_, scrollController) => HowToPlayGuideBody(
        scrollController: scrollController,
        yourRole: yourRole,
        initialSectionId: initialSectionId,
      ),
    ),
  );
}
