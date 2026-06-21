import 'package:flutter/material.dart';

import '../../../presentation/world/world_presentation_catalog.dart';
import '../../../theme/world_profile.dart';

/// 試合進行中に後から入った観戦者（インスペクター）向けの説明バー。
class RoomInspectorBar extends StatelessWidget {
  const RoomInspectorBar({
    required this.onOpenLobby,
    required this.worldProfile,
    super.key,
  });

  final VoidCallback onOpenLobby;
  final WorldProfile worldProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pack = WorldPresentationCatalog.of(worldProfile);
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(pack.hudCornerRadius + 2),
      color: pack.panelSurface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.visibility_outlined, color: pack.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '観戦モード',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: pack.textOnPanel,
                    ),
                  ),
                  Text(
                    'マップ・暴露イベント・ギミックを閲覧できます。'
                    '参加者のライブ GPS と最終判明位置を表示します。'
                    'スキル操作や判定には参加しません。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: pack.mutedOnPanel,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onOpenLobby,
              child: Text('ロビー', style: TextStyle(color: pack.accent)),
            ),
          ],
        ),
      ),
    );
  }
}
