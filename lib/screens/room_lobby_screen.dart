import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../audio/game_audio.dart';
import '../session/session_prefs.dart';
import '../sync/firebase_bootstrap.dart';
import '../sync/firestore_room_session.dart';
import '../sync/room_member_view.dart';
import '../session/world_profile_prefs.dart';
import '../theme/world_profile.dart';
import '../widgets/scene_transitions.dart';
import '../features/game_map/prep/lobby_rules_summary_card.dart';
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
  bool _joining = false;
  String? _error;
  WorldProfile _worldProfile = WorldProfile.horror;

  bool get _joined => _session?.roomId != null;

  @override
  void initState() {
    super.initState();
    _session = widget.existingSession;
    GameAudio.instance.playMenuBgm(_worldProfile);
    Future<void>.microtask(_init);
  }

  Future<void> _init() async {
    await FirebaseBootstrap.tryInit();
    final profile = await WorldProfilePrefs.load();
    final form = await SessionPrefs.loadForm();
    if (!mounted) return;
    setState(() => _worldProfile = profile);
    GameAudio.instance.playMenuBgm(profile);
    _nickController.text = form.nickname;
    _roomController.text = form.roomId;
    if (_session != null && _session!.roomId != null) {
      _bindLobby(_session!);
    }
  }

  void _bindLobby(FirestoreRoomSession session) {
    _lobbySub?.cancel();
    final cached = session.currentLobbyMembers;
    if (mounted) {
      setState(() => _members = cached);
    } else {
      _members = cached;
    }
    _lobbySub = session.lobbyMembers.listen((list) {
      if (!mounted) return;
      setState(() => _members = list);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _members = session.currentLobbyMembers);
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
        _error =
            FirebaseBootstrap.lastErrorBrief ??
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
    await SessionPrefs.saveForm(nickname: nick, roomId: rid, role: 'runner');
    final fs = _session ?? FirestoreRoomSession();
    final err = await fs.join(roomId: rid, nickname: nick, role: 'runner');
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _joining = false;
        _error = err;
      });
      return;
    }
    final members = List<RoomMemberView>.from(fs.currentLobbyMembers);
    setState(() {
      _session = fs;
      _members = members;
      _joining = false;
    });
    _bindLobby(fs);
    if (members.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _session != fs) return;
        setState(() => _members = fs.currentLobbyMembers);
      });
    }
  }

  Future<void> _leave() async {
    await _lobbySub?.cancel();
    _lobbySub = null;
    await _session?.disconnect();
  }

  Future<void> _transferHostTo(RoomMemberView target) async {
    final fs = _session;
    if (fs == null || !fs.isHost) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ホストを譲渡'),
        content: Text(
          '「${target.nickname}」をホストにしますか？\n'
          'あなたは通常メンバーになります。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('譲渡'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final err = await fs.transferHost(target.uid);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${target.nickname} をホストにしました')));
    }
  }

  Future<void> _openMap() async {
    final fs = _session;
    if (fs == null || fs.roomId == null) return;
    if (!mounted) return;
    final profile = await WorldProfilePrefs.load();
    if (!mounted) return;
    await AppNav.push<void>(
      context,
      (_) => GameMapScreen(profile: profile, onlineSession: fs),
    );
    if (!mounted) return;
    GameAudio.instance.playMenuBgm(_worldProfile);
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
        leading: BackButton(onPressed: () => Navigator.pop(context, _session)),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'ルームに参加すると、同じルームIDの端末が一覧に表示されます。'
                                '位置は標準では秘匿され、スキルやイベントでのみ公開されます。',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 12),
                              InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: '地図の世界観',
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  _worldProfile.label,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ),
                              Text(
                                'タイトル画面の世界観設定がマップに反映されます',
                                style: theme.textTheme.bodySmall?.copyWith(
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
                              if (_error != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _error!,
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                              if (kDebugMode &&
                                  FirebaseBootstrap.isReady &&
                                  Firebase.apps.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                SelectableText(
                                  'DBG: Firebase projectId = ${Firebase.app().options.projectId}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                    fontSize: 11,
                                  ),
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
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(
                                              _joined ? '再参加' : 'ルームに参加',
                                            ),
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
                              const SizedBox(height: 16),
                              Text(
                                'メンバー (${_members.length})',
                                style: theme.textTheme.titleSmall,
                              ),
                              if (_joined)
                                LobbyRulesSummaryCard(
                                  participantCount: math.max(1, _members.length),
                                ),
                              const SizedBox(height: 6),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!_joined)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            '参加するとメンバー一覧が表示されます',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ),
                    )
                  else if (_members.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'メンバー同期中です。\n表示されない場合は再参加してください。',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      sliver: SliverList.separated(
                        itemCount: _members.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 4),
                        itemBuilder: (ctx, i) => _MemberTile(
                          view: _members[i],
                          canTransferHost:
                              _session?.isHost == true &&
                              !_members[i].isSelf &&
                              !_members[i].isHost,
                          onTransferHost: () => _transferHostTo(_members[i]),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: FilledButton.tonalIcon(
                    onPressed: _joined ? _openMap : null,
                    icon: const Icon(Icons.map),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('ゲーム画面へ'),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.view,
    this.canTransferHost = false,
    this.onTransferHost,
  });

  final RoomMemberView view;
  final bool canTransferHost;
  final VoidCallback? onTransferHost;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = view.nickname.isEmpty ? '(名前なし)' : view.nickname;
    final band = view.proximityBand;

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: view.isSelf
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              child: Icon(
                view.isHost ? Icons.star : Icons.person_outline,
                size: 16,
                color: view.isHost
                    ? theme.colorScheme.onSecondaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    [
                      if (view.isSelf) 'あなた',
                      if (view.isHost) 'ホスト',
                      if (view.isStale(DateTime.now().toUtc())) 'ハートビート遅延',
                      if (band != null && band.isNotEmpty) band,
                    ].where((s) => s.isNotEmpty).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (canTransferHost && onTransferHost != null)
              IconButton(
                tooltip: 'ホストを譲渡',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.swap_horiz, size: 20),
                onPressed: onTransferHost,
              ),
          ],
        ),
      ),
    );
  }
}
