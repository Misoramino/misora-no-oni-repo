import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../settings/oni_operator_prefs.dart';

/// 試合中の通知設定（個人設定と同じ prefs を共有）。
class OniOperatorScreen extends StatefulWidget {
  const OniOperatorScreen({super.key});

  @override
  State<OniOperatorScreen> createState() => _OniOperatorScreenState();
}

class _OniOperatorScreenState extends State<OniOperatorScreen> {
  bool _loading = true;
  bool _crisisVib = true;
  bool _crisisNotification = true;
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
      _crisisVib = s.crisisVibration;
      _crisisNotification = s.crisisNotification;
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
        roleEnabled: true,
        notifyVibration: _vib,
        notifySound: _sound,
        notifyAggressive: _aggressive,
        crisisVibration: _crisisVib,
        crisisNotification: _crisisNotification,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('試合通知')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  '個人設定の「試合通知」と同じ内容です。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Text('危機アラート（背面時）', style: theme.textTheme.titleSmall),
                SwitchListTile(
                  title: const Text('危機時の振動'),
                  value: _crisisVib,
                  onChanged: (v) async {
                    setState(() => _crisisVib = v);
                    await _persist();
                  },
                ),
                SwitchListTile(
                  title: const Text('危機時のローカル通知'),
                  value: _crisisNotification,
                  onChanged: (v) async {
                    setState(() => _crisisNotification = v);
                    await _persist();
                  },
                ),
                const Divider(height: 28),
                Text('接近・拘束中（前面時）', style: theme.textTheme.titleSmall),
                SwitchListTile(
                  title: const Text('振動'),
                  value: _vib,
                  onChanged: (v) async {
                    setState(() => _vib = v);
                    await _persist();
                  },
                ),
                SwitchListTile(
                  title: const Text('サウンド'),
                  value: _sound,
                  onChanged: (v) async {
                    setState(() => _sound = v);
                    await _persist();
                  },
                ),
                SwitchListTile(
                  title: const Text('接近時に通知を高頻度化'),
                  subtitle: const Text('バッテリー消費が増えます'),
                  value: _aggressive,
                  onChanged: (v) async {
                    setState(() => _aggressive = v);
                    await _persist();
                  },
                ),
              ],
            ),
    );
  }
}
