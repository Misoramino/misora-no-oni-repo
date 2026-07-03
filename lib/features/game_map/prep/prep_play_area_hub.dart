import 'package:flutter/material.dart';
import '../../../presentation/world/world_legibility.dart';



import '../../../game/play_area.dart';

import '../../../theme/map_hud_contrast.dart';

import '../../../theme/world_profile.dart';

import '../../../theme/world_profile_tokens.dart';



/// 準備画面「プレイエリア」タブ展開時のアクセスハブ。

class PrepPlayAreaHub extends StatelessWidget {

  const PrepPlayAreaHub({

    required this.activePlayArea,

    required this.playAreaSummary,

    required this.selectedSlotName,

    required this.savedCount,

    required this.isHost,

    required this.worldProfile,

    required this.mapStyleJson,

    required this.tokens,

    required this.onOpenMapBrowse,

    required this.onOpenMapPreview,

    required this.onOpenMapEdit,

    required this.onOpenAreaGallery,

    required this.onHostApplyArea,

    this.onProposeToHost,

    this.prepLegibility,

    super.key,

  });



  final PlayArea activePlayArea;

  final String playAreaSummary;

  final String? selectedSlotName;

  final int savedCount;

  final bool isHost;

  final WorldProfile worldProfile;

  final String? mapStyleJson;

  final WorldProfileTokens tokens;

  final VoidCallback onOpenMapBrowse;

  final VoidCallback onOpenMapPreview;

  final VoidCallback onOpenMapEdit;

  final VoidCallback onOpenAreaGallery;

  final VoidCallback onHostApplyArea;

  final VoidCallback? onProposeToHost;

  final MapHudPrepLegibility? prepLegibility;



  @override

  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    final scheme = theme.colorScheme;

    final leg = prepLegibility ?? MapHudContrast.prepLegibility(scheme, worldProfile);
    final tileBg = leg.tileSurface;



    return Column(

      crossAxisAlignment: CrossAxisAlignment.stretch,

      children: [

        Text(

          activePlayArea.coarseLocationLabel(),

          style: theme.textTheme.labelLarge?.copyWith(

            color: leg.tileValue,

            fontWeight: FontWeight.w600,

          ),

        ),

        const SizedBox(height: 4),

        Text(

          playAreaSummary,

          style: theme.textTheme.bodySmall?.copyWith(
            color: context.worldTextOn(tileBg),
          ),

        ),

        if (selectedSlotName != null) ...[

          const SizedBox(height: 4),

          Text(

            '選択: $selectedSlotName',

            style: theme.textTheme.labelSmall?.copyWith(
              color: context.worldMutedOn(tileBg),
            ),

          ),

        ],

        const SizedBox(height: 12),

        Row(

          children: [

            Expanded(

              child: _HubActionTile(

                icon: Icons.map_outlined,

                label: 'マップ',

                enabled: true,

                onTap: onOpenMapBrowse,

                leg: leg,

              ),

            ),

            const SizedBox(width: 8),

            Expanded(

              child: _HubActionTile(

                icon: Icons.layers_outlined,

                label: 'プレビュー',

                enabled: true,

                onTap: onOpenMapPreview,

                leg: leg,

              ),

            ),

          ],

        ),

        const SizedBox(height: 8),

        Row(

          children: [

            Expanded(

              child: _HubActionTile(
                icon: Icons.edit_location_alt_outlined,
                label: '編集',
                enabled: true,
                onTap: onOpenMapEdit,
                leg: leg,
              ),

            ),

            const SizedBox(width: 8),

            Expanded(

              child: _HubActionTile(

                icon: Icons.photo_library_outlined,

                label: savedCount > 0
                    ? '保存エリア一覧 ($savedCount)'
                    : '保存エリア一覧',

                enabled: true,

                onTap: onOpenAreaGallery,

                leg: leg,

              ),

            ),

          ],

        ),

        if (!isHost) ...[
          const SizedBox(height: 8),
          Text(
            '保存したエリアはこの端末のみ。試合に使う形はホストが決めます。',
            style: theme.textTheme.labelSmall?.copyWith(
              color: context.worldMutedOn(tileBg),
            ),
          ),
          if (selectedSlotName != null && onProposeToHost != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onProposeToHost,
              icon: const Icon(Icons.send_outlined, size: 18),
              label: const Text('ホストに提案'),
            ),
          ],
        ],
        if (isHost && selectedSlotName != null) ...[

          const SizedBox(height: 8),

          FilledButton.icon(

            onPressed: onHostApplyArea,

            icon: const Icon(Icons.check_circle_outline, size: 20),

            label: const Text('選択エリアを適用'),

          ),

        ],

      ],

    );

  }

}



class _HubActionTile extends StatelessWidget {

  const _HubActionTile({

    required this.icon,

    required this.label,

    required this.enabled,

    required this.onTap,

    required this.leg,

  });



  final IconData icon;

  final String label;

  final bool enabled;

  final VoidCallback onTap;

  final MapHudPrepLegibility leg;



  @override

  Widget build(BuildContext context) {

    final theme = Theme.of(context);
    final tileBg = leg.tileSurface;



    return Material(

      color: leg.tileSurface,

      borderRadius: BorderRadius.circular(10),

      child: InkWell(

        onTap: enabled ? onTap : null,

        borderRadius: BorderRadius.circular(10),

        child: Padding(

          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),

          child: Column(

            children: [

              Icon(

                icon,

                size: 26,

                color: enabled
                    ? leg.tileIcon
                    : context.worldMutedOn(tileBg).withValues(alpha: 0.5),

              ),

              const SizedBox(height: 6),

              Text(

                label,

                textAlign: TextAlign.center,

                style: theme.textTheme.labelMedium?.copyWith(

                  color: enabled ? leg.tileValue : context.worldMutedOn(tileBg),

                  fontWeight: FontWeight.w600,

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }

}


