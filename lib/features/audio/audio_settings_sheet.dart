import 'package:flutter/material.dart';

import '../../audio/audio_library.dart';
import '../../audio/game_audio.dart';
import '../../audio/sfx_id.dart';
import '../../session/audio_prefs.dart';
import '../../session/launch_branding_prefs.dart';

/// サウンド設定（マスター/効果音/BGM 音量・ミュート）のボトムシート。
Future<void> showAudioSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    builder: (sheetCtx) => _AudioSettingsSheet(
      onClose: () => Navigator.pop(sheetCtx),
    ),
  );
}

class _AudioSettingsSheet extends StatefulWidget {
  const _AudioSettingsSheet({required this.onClose});

  final VoidCallback onClose;

  @override
  State<_AudioSettingsSheet> createState() => _AudioSettingsSheetState();
}

class _AudioSettingsSheetState extends State<_AudioSettingsSheet> {
  bool? _launchSoundOn;

  @override
  void initState() {
    super.initState();
    LaunchBrandingPrefs.loadSoundEnabled().then((v) {
      if (mounted) setState(() => _launchSoundOn = v);
    });
  }

  Future<void> _setLaunchSound(bool next) async {
    await LaunchBrandingPrefs.saveSoundEnabled(next);
    if (!mounted) return;
    setState(() => _launchSoundOn = next);
    GameAudio.instance.playSfx(SfxId.uiTap);
  }

  @override
  Widget build(BuildContext context) {
    final audio = GameAudio.instance;
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: ValueListenableBuilder<AudioSettings>(
          valueListenable: audio.settings,
          builder: (context, s, _) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.graphic_eq_rounded,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Text('サウンド設定', style: theme.textTheme.titleLarge),
                      const Spacer(),
                      FilledButton.tonalIcon(
                        onPressed: () {
                          audio.toggleMute();
                          if (s.muted) audio.playSfx(SfxId.uiToggle);
                        },
                        icon: Icon(
                          s.muted
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                        ),
                        label: Text(s.muted ? 'ミュート中' : 'オン'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _VolumeRow(
                    label: 'マスター',
                    icon: Icons.tune_rounded,
                    value: s.masterVolume,
                    enabled: !s.muted,
                    onChanged: (v) =>
                        audio.updateSettings(s.copyWith(masterVolume: v)),
                    onChangeEnd: (_) => audio.playSfx(SfxId.uiTap),
                  ),
                  _VolumeRow(
                    label: '効果音',
                    icon: Icons.music_note_rounded,
                    value: s.sfxVolume,
                    enabled: !s.muted,
                    onChanged: (v) =>
                        audio.updateSettings(s.copyWith(sfxVolume: v)),
                    onChangeEnd: (_) => audio.playSfx(SfxId.reward),
                  ),
                  _VolumeRow(
                    label: 'BGM',
                    icon: Icons.library_music_rounded,
                    value: s.bgmVolume,
                    enabled: !s.muted && s.bgmEnabled,
                    onChanged: (v) =>
                        audio.updateSettings(s.copyWith(bgmVolume: v)),
                  ),
                  _VolumeRow(
                    label: '環境音',
                    icon: Icons.air_rounded,
                    value: s.ambientVolume,
                    enabled: !s.muted,
                    onChanged: (v) =>
                        audio.updateSettings(s.copyWith(ambientVolume: v)),
                  ),
                  const SizedBox(height: 14),
                  Text('BGMの曲', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  _BgmChoicePicker(
                    current: s.bgmChoice,
                    onPick: (choice) {
                      audio.updateSettings(s.copyWith(bgmChoice: choice));
                      audio.playSfx(SfxId.uiTap);
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('起動演出', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 4),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('起動時の効果音'),
                    subtitle: const Text('アプリ起動ロゴ表示時の短い効果音'),
                    value: _launchSoundOn ?? true,
                    onChanged: _launchSoundOn == null
                        ? null
                        : (v) => _setLaunchSound(v),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '・タイトル／ロビーは選んだ曲（おまかせ＝世界観ごとの曲）を流します。\n'
                    '・対戦中はBGMの代わりに、世界観の環境音をときどき鳴らします。\n'
                    '・OFFにすると効果音と環境音だけになり、好きな音楽を裏で流せます。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: widget.onClose,
                      child: const Text('閉じる'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BgmChoicePicker extends StatelessWidget {
  const _BgmChoicePicker({required this.current, required this.onPick});

  final String current;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget chip(String value, String label, IconData? icon) {
      final selected = current == value;
      return ChoiceChip(
        selected: selected,
        showCheckmark: false,
        avatar: icon == null
            ? null
            : Icon(
                icon,
                size: 18,
                color: selected
                    ? theme.colorScheme.onSecondaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
        label: Text(label),
        onSelected: (_) => onPick(value),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip(AudioSettings.bgmWorldDefault, 'おまかせ', Icons.auto_awesome_rounded),
        chip(AudioSettings.bgmOff, 'OFF（自分の音楽）', Icons.music_off_rounded),
        for (final b in BgmId.values) chip(b.name, b.label, null),
      ],
    );
  }
}

class _VolumeRow extends StatelessWidget {
  const _VolumeRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.onChangeEnd,
  });

  final String label;
  final IconData icon;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          SizedBox(
            width: 56,
            child: Text(label, style: theme.textTheme.labelLarge),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(0, 1),
              onChanged: enabled ? onChanged : null,
              onChangeEnd: enabled ? onChangeEnd : null,
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '${(value * 100).round()}',
              textAlign: TextAlign.end,
              style: theme.textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}
