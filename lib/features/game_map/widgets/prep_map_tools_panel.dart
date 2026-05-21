import 'package:flutter/material.dart';

/// 準備フェーズの「地図確認・エリア編集」専用ツール（ゲーム中 HUD とは別ウィジェット）。
class PrepMapToolsPanel extends StatelessWidget {
  const PrepMapToolsPanel({
    required this.isEditing,
    required this.onToggleAreaEdit,
    required this.onRecenterGps,
    required this.onRefreshGps,
    required this.onClearTraces,
    required this.onOpenHelp,
    required this.onDismissPrepSheet,
    super.key,
  });

  final bool isEditing;
  final VoidCallback onToggleAreaEdit;
  final VoidCallback onRecenterGps;
  final VoidCallback onRefreshGps;
  final VoidCallback onClearTraces;
  final VoidCallback onOpenHelp;
  final VoidCallback onDismissPrepSheet;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = scheme.onSurface;
    final fgMuted = scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'マップ・エリア',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'パネルを閉じる',
                onPressed: onDismissPrepSheet,
                icon: const Icon(Icons.expand_more),
              ),
            ],
          ),
          Text(
            '現在地の確認・エリアの編集・保存に使います（試合中のスキルパネルとは別）。',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: fgMuted, height: 1.35),
          ),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: onToggleAreaEdit,
            icon: Icon(
              isEditing ? Icons.check_circle : Icons.edit_location_alt,
            ),
            label: Text(isEditing ? '編集をやめる（地図のまま）' : 'エリア編集'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: MapLobbyToolButton(
                  icon: Icons.center_focus_strong,
                  label: '地図を現在地へ',
                  subtitle: 'カメラ移動',
                  onPressed: isEditing ? null : onRecenterGps,
                  lightStyle: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MapLobbyToolButton(
                  icon: Icons.gps_not_fixed,
                  label: 'GPSを再取得',
                  subtitle: '位置の更新',
                  onPressed: onRefreshGps,
                  lightStyle: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: onClearTraces,
                icon: Icon(
                  Icons.cleaning_services_outlined,
                  size: 18,
                  color: fg,
                ),
                label: Text('痕跡クリア', style: TextStyle(color: fg, fontSize: 12)),
              ),
              TextButton.icon(
                onPressed: onOpenHelp,
                icon: Icon(Icons.help_outline, size: 18, color: fg),
                label: Text('遊び方', style: TextStyle(color: fg, fontSize: 12)),
              ),
            ],
          ),
          Text(
            '時間・ルールは準備のカスタムルールから。',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: fgMuted, height: 1.35),
          ),
        ],
      ),
    );
  }
}

/// マップ準備パネルおよび試合中パネル内の地図操作ボタン。
class MapLobbyToolButton extends StatelessWidget {
  const MapLobbyToolButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onPressed,
    required this.lightStyle,
    super.key,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onPressed;
  final bool lightStyle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = lightStyle
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.12);
    final iconColor = lightStyle ? scheme.primary : Colors.white;
    final textColor = lightStyle ? scheme.onSurface : Colors.white;
    final subColor = lightStyle
        ? scheme.onSurfaceVariant
        : Colors.white.withValues(alpha: 0.65);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(color: subColor, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
