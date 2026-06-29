import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/game_map/settings/player_personal_settings_models.dart';
import '../features/world_selection/world_selection_sheet.dart';
import '../presentation/world/world_presentation_catalog.dart';
import '../session/avatar_image_store.dart';
import '../session/game_map_prefs.dart';
import '../session/session_prefs.dart';
import '../session/match_presentation_prefs.dart';
import '../session/world_profile_prefs.dart';
import '../settings/oni_operator_prefs.dart';
import '../theme/app_theme_factory.dart';
import '../theme/world_profile.dart';
import '../theme/world_visual_pack_factory.dart';

/// プロフィール・鬼設定・位置プライバシーを1画面にまとめた個人設定。
class PersonalSettingsScreen extends StatefulWidget {
  const PersonalSettingsScreen({
    super.key,
    this.onWorldProfileChanged,
  });

  /// 世界観を選んだ直後に呼ぶ（保存ボタンを待たない）。
  final ValueChanged<WorldProfile>? onWorldProfileChanged;

  @override
  State<PersonalSettingsScreen> createState() => _PersonalSettingsScreenState();
}

class _PersonalSettingsScreenState extends State<PersonalSettingsScreen> {
  bool _loading = true;
  bool _saving = false;

  final _nameController = TextEditingController();
  WorldProfile _profile = WorldProfile.horror;
  bool _useBle = false;
  String? _avatarPath;

  bool _oniNotifyVibration = true;
  bool _oniNotifySound = true;
  bool _oniNotifyAggressive = false;
  bool _crisisNotifyVibration = true;
  bool _crisisNotifyLocal = true;
  bool _shortMatchStartCeremony = false;

  LocationPermission? _locationPermission;
  bool _locationServiceEnabled = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_load);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final oni = OniOperatorPrefs.fromPrefs(prefs);
    final permission = await Geolocator.checkPermission();
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    final form = await SessionPrefs.loadForm();
    final profile = await WorldProfilePrefs.load();
    final shortCeremony = await MatchPresentationPrefs.shortMatchStartCeremony();
    setState(() {
      _nameController.text = form.nickname;
      _profile = profile;
      _useBle = prefs.getBool(GameMapPrefs.useBleScanProximity) ?? false;
      _avatarPath = prefs.getString(GameMapPrefs.avatarImagePath);
      _oniNotifyVibration = oni.notifyVibration;
      _oniNotifySound = oni.notifySound;
      _oniNotifyAggressive = oni.notifyAggressive;
      _crisisNotifyVibration = oni.crisisVibration;
      _crisisNotifyLocal = oni.crisisNotification;
      _shortMatchStartCeremony = shortCeremony;
      _locationPermission = permission;
      _locationServiceEnabled = serviceEnabled;
      _loading = false;
    });
  }

  Future<void> _pickAvatar() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (file == null) return;
    final stored = await AvatarImageStore.persistFromPicker(file.path);
    if (!mounted) return;
    setState(() => _avatarPath = stored);
  }

  Future<void> _applyWorldProfileSelection(WorldProfile next) async {
    if (next == _profile) return;
    setState(() => _profile = next);
    await WorldProfilePrefs.save(next);
    widget.onWorldProfileChanged?.call(next);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('表示名を入力してください')),
      );
      return;
    }
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    final form = await SessionPrefs.loadForm();
    await SessionPrefs.saveForm(
      nickname: name,
      roomId: form.roomId,
      role: form.role,
    );
    await prefs.setBool(GameMapPrefs.useBleScanProximity, _useBle);
    if (_avatarPath != null && _avatarPath!.isNotEmpty) {
      await prefs.setString(GameMapPrefs.avatarImagePath, _avatarPath!);
    } else {
      await prefs.remove(GameMapPrefs.avatarImagePath);
      await AvatarImageStore.deleteStored();
    }
    await WorldProfilePrefs.save(_profile);
    await MatchPresentationPrefs.setShortMatchStartCeremony(
      _shortMatchStartCeremony,
    );
    await OniOperatorPrefs.save(
      prefs,
      OniOperatorSnapshot(
        notifyVibration: _oniNotifyVibration,
        notifySound: _oniNotifySound,
        notifyAggressive: _oniNotifyAggressive,
        crisisVibration: _crisisNotifyVibration,
        crisisNotification: _crisisNotifyLocal,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(
      context,
      PlayerPersonalSettingsResult(
        displayName: name,
        profile: _profile,
        useBleScan: _useBle,
        avatarImagePath: _avatarPath,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 現在選択中の世界観テーマを毎回生成（画面内で世界観を変えても
    // フォント・色が即反映される）。本画面の内容はスキャフォールド上に
    // 直接並ぶため、既定の文字色をスキャフォールド向けに上書きして
    // 暗いスキャフォールドでの「暗文字 on 暗背景」を防ぐ。
    final pack = WorldPresentationCatalog.of(_profile);
    final base = AppThemeFactory.create(_profile);
    final scaffoldTextTheme = base.textTheme.apply(
      bodyColor: pack.textOnScaffold,
      displayColor: pack.textOnScaffold,
    );
    final themed = base.copyWith(
      textTheme: scaffoldTextTheme,
      primaryTextTheme: scaffoldTextTheme,
      colorScheme: base.colorScheme.copyWith(
        onSurface: pack.textOnScaffold,
        onSurfaceVariant: pack.mutedOnScaffold,
      ),
    );
    final theme = themed;
    return Theme(
      data: themed,
      child: Scaffold(
      appBar: AppBar(
        title: const Text('個人設定'),
        actions: [
          TextButton(
            onPressed: _loading || _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'この端末だけに保存されます。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: pack.mutedOnScaffold,
                  ),
                ),
                const SizedBox(height: 16),
                _sectionTitle(context, 'プロフィール'),
                const SizedBox(height: 8),
                Center(child: _avatarWidget()),
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: _pickAvatar,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('ピン用の写真を変更'),
                  ),
                ),
                if (_avatarPath != null && _avatarPath!.isNotEmpty)
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => _avatarPath = null),
                      child: const Text('写真をクリア'),
                    ),
                  ),
                Text(
                  _photoPinHelperText(_profile),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '表示名',
                    hintText: 'ルームで表示される名前',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('世界観'),
                  subtitle: Text(
                    '${_profile.label} — ${WorldPresentationCatalog.of(_profile).tagline}\n'
                    '個人設定。ルーム全員には共有されません',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final next = await showWorldSelectionSheet(
                      context,
                      current: _profile,
                    );
                    if (next != null) await _applyWorldProfileSelection(next);
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('BLE スキャン（近接推定）'),
                  subtitle: const Text('同一ルーム端末の検出。権限がない場合は GPS のみ'),
                  value: _useBle,
                  onChanged: (v) => setState(() => _useBle = v),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('試合開始演出を短く'),
                  subtitle: const Text('ロスターとエリア俯瞰を省略（カウントダウンは維持）'),
                  value: _shortMatchStartCeremony,
                  onChanged: (v) => setState(() => _shortMatchStartCeremony = v),
                ),
                const SizedBox(height: 20),
                _sectionTitle(context, '試合通知'),
                const SizedBox(height: 4),
                Text(
                  'パニック・結界拘束・バックグラウンド復帰時の危機など。端末ローカルに保存されます。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: pack.mutedOnScaffold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '危機アラート（アプリが背面のとき）',
                  style: theme.textTheme.titleSmall,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('危機時の振動'),
                  subtitle: const Text('パニック・結界拘束・自分への暴露など'),
                  value: _crisisNotifyVibration,
                  onChanged: (v) => setState(() => _crisisNotifyVibration = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('危機時のローカル通知'),
                  subtitle: const Text('画面ロック中も通知トレイに表示'),
                  value: _crisisNotifyLocal,
                  onChanged: (v) => setState(() => _crisisNotifyLocal = v),
                ),
                const SizedBox(height: 12),
                Text(
                  '接近・拘束中（アプリ前面のとき）',
                  style: theme.textTheme.titleSmall,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('振動'),
                  value: _oniNotifyVibration,
                  onChanged: (v) => setState(() => _oniNotifyVibration = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('サウンド'),
                  value: _oniNotifySound,
                  onChanged: (v) => setState(() => _oniNotifySound = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('接近時に通知を高頻度化'),
                  subtitle: const Text('バッテリー消費が増えます'),
                  value: _oniNotifyAggressive,
                  onChanged: (v) => setState(() => _oniNotifyAggressive = v),
                ),
                const SizedBox(height: 20),
                _sectionTitle(context, 'プライバシー'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: pack.panelOnScaffold,
                    borderRadius: BorderRadius.circular(pack.hudCornerRadius + 4),
                    border: Border.all(color: pack.panelBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GPSサービス: ${_locationServiceEnabled ? 'ON' : 'OFF'}',
                          style: TextStyle(color: pack.textOnPanelOverScaffold),
                        ),
                        Text(
                          '権限: ${_locationPermission?.name ?? 'unknown'}',
                          style: TextStyle(color: pack.textOnPanelOverScaffold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            FilledButton.tonal(
                              onPressed: Geolocator.openLocationSettings,
                              child: const Text('位置情報設定'),
                            ),
                            FilledButton.tonal(
                              onPressed: Geolocator.openAppSettings,
                              child: const Text('アプリ設定'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: const Text('保存して閉じる'),
                ),
              ],
            ),
      ),
    );
  }

  Widget _avatarWidget() {
    if (_avatarPath != null && _avatarPath!.isNotEmpty) {
      return ClipOval(
        child: Image.file(
          File(_avatarPath!),
          width: 88,
          height: 88,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const CircleAvatar(
            radius: 44,
            child: Icon(Icons.broken_image_outlined, size: 36),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: 44,
      child: Icon(
        Icons.person_outline,
        size: 44,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Text(text, style: Theme.of(context).textTheme.titleMedium);
  }
}

String _photoPinHelperText(WorldProfile profile) {
  final pack = WorldVisualPackFactory.of(profile);
  const base =
      '選んだ写真は自動で縮小して保存されます。オンライン中は保存時にルームへ共有し、';
  if (pack.photoOnlyOnReveal || !pack.showPhotoPinByDefault) {
    return '$base 名前付き暴露時に他プレイヤーにも写真ピンで表示（試合後に追加した場合も再保存で反映）。';
  }
  return '$base 自分のピンと名前付き暴露時に他プレイヤーへ表示（後から追加した場合も再保存で反映）。';
}
