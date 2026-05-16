import 'dart:async';

import 'package:flutter/material.dart';

import '../session/session_prefs.dart';
import '../sync/firebase_bootstrap.dart';
import '../sync/firestore_room_session.dart';
import '../sync/room_member_view.dart';
import '../theme/world_profile.dart';
import '../widgets/responsive_page.dart';
import 'game_map_screen.dart';

/// ルーム参加・メンバー一覧・ゲーム画面への遷移。
class RoomLobbyScreen extends StatefulWidget {
  const RoomLobbyScreen({this.existingSession, super.key});

  /// マップ画面から戻ったときなど、既に参加済みのセッションを渡せる。
  final FirestoreRoomSession? existingSession;

  @override
  State<RoomLobbyScreen> createState() => _RoomLobbyScreenState();
}

class _RoomLobbyScreenState extends State<RoomLobbyScreen> {
  final _roomController = TextEditingController();
  final _nickController = TextEditingController();
  FirestoreRoomSession? _session;
  StreamSubscription<List<RoomMemberView>>? _lobbySub;
  List<RoomMemberView> _members = [];
  String _role = 'runner';
  bool _joining = false;
  String? _error;

  bool get _joined => _session?.roomId != null;

  @override
  void initState() {
    super.initState();
    _session = widget.existingSession;
    Future<void>.microtask(_init);
  }

  Future<void> _init() async {
    await FirebaseBootstrap.tryInit();
    final form = await SessionPrefs.loadForm();
    if (!mounted) return;
    _nickController.text = form.nickname;
    _roomController.text = form.roomId;
    setState(() => _role = form.role);
    if (_session != null && _session!.roomId != null) {
      _bindLobby(_session!);
    }
  }

  void _bindLobby(FirestoreRoomSession session) {
    _lobbySub?.cancel();
    _lobbySub = session.lobbyMembers.listen((list) {
      if (!mounted) return;
      setState(() => _members = list);
    });
  }

  Future<void> _join() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _joining = true;
      _error = null;
    });
    await FirebaseBootstrap.tryInit();
    if (!FirebaseBootstrap.isReady) {
      setState(() {
        _joining = false;
        _error = FirebaseBootstrap.lastErrorBrief ??
            'Firebase に接続できません。設定ファイルを確認してください。';
      });
      return;
    }
    final rid = _roomController.text.trim();
    final nick = _nickController.text.trim();
    if (rid.isEmpty || nick.isEmpty) {
      setState(() {
        _joining = false;
        _error = 'ルームIDと表示名を入力してください';
      });
      return;
    }
    await SessionPrefs.saveForm(
      nickname: nick,
      roomId: rid,
      role: _role,
    );
    final fs = _session ?? FirestoreRoomSession();
    final err = await fs.join(roomId: rid, nickname: nick, role: _role);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _joining = false;
        _error = err;
      });
      return;
    }
    setState(() {
      _session = fs;
      _joining = false;
    });
    _bindLobby(fs);
  }

  Future<void> _leave() async {
    await _lobbySub?.cancel();
    _lobbySub = null;
    await _session?.disconnect();
  }

  Future<void> _openMap() async {
    final fs = _session;
    if (fs == null || fs.roomId == null) return;
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => GameMapScreen(
          profile: WorldProfile.horror,
          onlineSession: fs,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _lobbySub?.cancel();
    _roomController.dispose();
    _nickController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('ルームロビー'),
        leading: BackButton(
          onPressed: () => Navigator.pop(context, _session),
        ),
      ),
      body: ResponsivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ルームに参加すると、同じルームIDの端末が一覧に表示されます。'
              '本番プレイでは鬼の位置はオンライン同期されたメンバーから取得します。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _roomController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'ルームID',
                hintText: '例: friday-night-1',
                border: OutlineInputBorder(),
              ),
              enabled: !_joining,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nickController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: '表示名',
                border: OutlineInputBorder(),
              ),
              enabled: !_joining,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              key: ValueKey(_role),
              initialValue: _role,
              decoration: const InputDecoration(
                labelText: 'ロール',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'runner', child: Text('runner（逃走）')),
                DropdownMenuItem(value: 'oni', child: Text('oni（鬼）')),
                DropdownMenuItem(
                  value: 'spectator',
                  child: Text('spectator（観戦）'),
                ),
              ],
              onChanged: _joining
                  ? null
                  : (v) {
                      if (v != null) setState(() => _role = v);
                    },
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _joining ? null : _join,
                    child: _joining
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_joined ? '再参加' : 'ルームに参加'),
                  ),
                ),
                if (_joined) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _joining
                          ? null
                          : () async {
                              await _leave();
                              if (!mounted) return;
                              setState(() {
                                _session = null;
                                _members = [];
                              });
                            },
                      child: const Text('退出'),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'メンバー (${_members.length})',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (!_joined)
              Text(
                '参加するとメンバー一覧が表示されます',
                style: theme.textTheme.bodySmall,
              )
            else if (_members.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              ..._members.map((v) => _MemberTile(view: v)),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: _joined ? _openMap : null,
              icon: const Icon(Icons.map),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('ゲーム画面へ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.view});

  final RoomMemberView view;

  @override
  Widget build(BuildContext context) {
    final m = view.member;
    final theme = Theme.of(context);
    final roleLabel = switch (m.role) {
      'oni' => '鬼',
      'spectator' => '観戦',
      _ => '逃走',
    };
    final hasPos = m.reportedAtUtc != null;
    final subtitle = hasPos
        ? '位置報告あり · ${m.proximityBand ?? "帯未設定"}'
        : '位置未報告（ゲーム画面で更新）';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: view.isSelf
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            m.role == 'oni' ? Icons.front_hand : Icons.directions_run,
            size: 20,
          ),
        ),
        title: Text(
          '${m.nickname.isEmpty ? "(名前なし)" : m.nickname}'
          '${view.isSelf ? "（あなた）" : ""}',
        ),
        subtitle: Text('$roleLabel · $subtitle'),
        trailing: view.isSelf
            ? Chip(
                label: const Text('自分'),
                visualDensity: VisualDensity.compact,
                backgroundColor: theme.colorScheme.primaryContainer,
              )
            : null,
      ),
    );
  }
}
