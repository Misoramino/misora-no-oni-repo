import 'package:flutter/material.dart';

import '../../../audio/game_audio.dart';
import '../../../audio/sfx_id.dart';
import '../../../presentation/world/world_presentation_catalog.dart';
import '../../../presentation/world/world_presentation_context.dart';
import '../../../presentation/world/world_ui_helpers.dart';
import '../../../game/match_quick_preset.dart';
import '../../../game/match_setup_summary.dart';
import '../../../widgets/juicy_tap.dart';

/// ルーム作成直後：お手軽 / 標準 / じっくり の3択のみ。
Future<MatchQuickPreset?> showMatchQuickPresetPicker(BuildContext context) {
  GameAudio.instance.playSfx(SfxId.uiConfirm);
  final profile = context.worldProfile;
  final pack = WorldPresentationCatalog.of(profile);
  return showWorldSheet<MatchQuickPreset>(
    context,
    profile: profile,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: pack.mutedOnScaffold.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                '試合の長さを選ぶ',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: pack.textOnScaffold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '詳細（告発の重み・ギミック等）は後から「ルール・役職」で変更できます。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: pack.mutedOnScaffold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                MatchSetupSummary.catalogHint,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: pack.mutedOnScaffold.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 16),
              for (final preset in MatchQuickPreset.values) ...[
                _PresetTile(
                  preset: preset,
                  onTap: () {
                    GameAudio.instance.playSfx(SfxId.uiConfirm);
                    Navigator.pop(ctx, preset);
                  },
                ),
                const SizedBox(height: 10),
              ],
              TextButton(
                onPressed: () {
                  GameAudio.instance.playSfx(SfxId.uiBack);
                  Navigator.pop(ctx);
                },
                style: TextButton.styleFrom(
                  foregroundColor: pack.accentOnScaffold,
                ),
                child: const Text('あとで自分で設定する'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({required this.preset, required this.onTap});

  final MatchQuickPreset preset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pack = WorldPresentationCatalog.of(context.worldProfile);
    return JuicyTap(
      onTap: onTap,
      sfx: SfxId.uiTap,
      child: Material(
        elevation: 0,
        color: pack.panelOnScaffold,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: pack.panelBorder),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preset.label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: pack.textOnPanelOverScaffold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        preset.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: pack.mutedOnPanelOverScaffold,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: pack.accentOnScaffold),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
