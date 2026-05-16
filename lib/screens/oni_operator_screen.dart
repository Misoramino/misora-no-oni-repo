import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../settings/oni_operator_prefs.dart';

/// 鬼側の通知・ロール設定。逃走者向け HUD から分離して集中できるようにする。
class OniOperatorScreen extends StatefulWidget {
  const OniOperatorScreen({super.key});

  @override
  State<OniOperatorScreen> createState() => _OniOperatorScreenState();
}

class _OniOperatorScreenState extends State<OniOperatorScreen> {
  bool _loading = true;
  bool _roleEnabled = false;
  bool _vib = true;
  bool _sound = true;
  bool _aggressive = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_load);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final s = OniOperatorPrefs.fromPrefs(prefs);
    if (!mounted) return;
    setState(() {
      _roleEnabled = s.roleEnabled;
      _vib = s.notifyVibration;
      _sound = s.notifySound;
      _aggressive = s.notifyAggressive;
      _loading = false;
    });
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await OniOperatorPrefs.save(
      prefs,
      OniOperatorSnapshot(
        roleEnabled: _roleEnabled,
        notifyVibration: _vib,
        notifySound: _sound,
        notifyAggressive: _aggressive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('鬼コンソール')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'この端末を鬼役として操作するときの通知まわりです。逃走者向けの「鬼情報モード」とは別です。',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                SwitchListTile(
                  title: const Text('鬼ロール設定を有効化'),
                  subtitle: const Text('オフにすると鬼向けバイブ・サウンドの細かい設定は使いません。'),
                  value: _roleEnabled,
                  onChanged: (v) async {
                    setState(() => _roleEnabled = v);
                    await _persist();
                  },
                ),
                if (_roleEnabled) ...[
                  const Divider(height: 32),
                  SwitchListTile(
                    title: const Text('鬼向けバイブ通知'),
                    value: _vib,
                    onChanged: (v) async {
                      setState(() => _vib = v);
                      await _persist();
                    },
                  ),
                  SwitchListTile(
                    title: const Text('鬼向けサウンド通知'),
                    value: _sound,
                    onChanged: (v) async {
                      setState(() => _sound = v);
                      await _persist();
                    },
                  ),
                  SwitchListTile(
                    title: const Text('接近時に通知を高頻度化'),
                    subtitle: const Text('バッテリーと注意分散のトレードオフがあります。'),
                    value: _aggressive,
                    onChanged: (v) async {
                      setState(() => _aggressive = v);
                      await _persist();
                    },
                  ),
                ],
                const SizedBox(height: 28),
                Text(
                  '今後ここに「逃走者のおおよその位置」「捕獲補助」など鬼専用の表示を足していく想定です。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
    );
  }
}
