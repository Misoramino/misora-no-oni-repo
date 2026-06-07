import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../audio/game_audio.dart';
import '../session/session_prefs.dart';
import '../sync/firebase_bootstrap.dart';
import '../sync/firestore_room_session.dart';
import '../sync/room_member_view.dart';
import '../sync/room_phase.dart';
import '../sync/shared_match_snapshot.dart';
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
  StreamSubscription<RoomMatchState>? _roomMatchSub;
  List<RoomMemberView> _members = [];
  String _roomPhase = RoomPhase.lobby;
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
    _roomMatchSub?.cancel();
    _roomPhase = session.currentPhase;
    _roomMatchSub = session.roomMatchState.listen((rm) {
      if (!mounted) return;
      setState(() => _roomPhase = rm.phase);
    });
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

  Future<void> _onProfileSelected(WorldProfile? next) async {
    if (next == null || next == _worldProfile) return;
    await WorldProfilePrefs.save(next);
    if (!mounted) return;
    setState(() => _worldProfile = next);
    GameAudio.instance.playMenuBgm(next);
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
    await _roomMatchSub?.cancel();
    _lobbySub = null;
    _roomMatchSub = null;
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

  Future<void> _claimHostIfAbsent() async {
    final fs = _session;
    if (fs == null) return;
    final err = await fs.claimHostIfAbsent();
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('あなたがホストになりました')),
      );
      setState(() {});
    }
  }

  Future<void> _copyRoomId() async {
    final id = _session?.roomId;
    if (id == null || id.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: id));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ルームID「$id」をコピーしました')),
    );
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
    _roomMatchSub?.cancel();
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
                              DropdownButtonFormField<WorldProfile>(
                                initialValue: _worldProfile,
                                decoration: const InputDecoration(
                                  labelText: '地図の世界観',
                                  border: OutlineInputBorder(),
                                ),
                                items: WorldProfile.values
                                    .map(
                                      (p) => DropdownMenuItem(
                                        value: p,
                                        child: Text(p.label),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _joining ? null : _onProfileSelected,
                              ),
                              Text(
                                'マップの見た目・BGMに反映されます（端末ごとの設定）',
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
                                    child: Semantics(
                                      button: true,
                                      label: _joined ? 'ルームに再参加' : 'ルームに参加',
                                      child: FilledButton(
                                        onPressed: _joining ? null : _join,
                                        child: _joining
                                            ? const SizedBox(
                                                height: 22,
                                                width: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : Text(
                                                _joined ? '再参加' : 'ルームに参加',
                                              ),
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
                              if (_joined && _session?.roomId != null) ...[
                                const SizedBox(height: 16),
                                _RoomIdShareCard(
                                  roomId: _session!.roomId!,
                                  isHost: _session!.isHost,
                                  onCopy: _copyRoomId,
                                ),
                                if (_roomPhase == RoomPhase.running) ...[
                                  const SizedBox(height: 10),
                                  Material(
                                    color: theme.colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(10),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.sports_esports_outlined,
                                            color: theme.colorScheme.secondary,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              '試合進行中です。'
                                              'ゲーム画面へ入ると、参加者は再参加、'
                                              'それ以外はインスペクター（観戦）として'
                                              'マップを閲覧できます。',
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                                if (_session!.isHostAbsent(DateTime.now().toUtc()) &&
                                    !_session!.isHost) ...[
                                  const SizedBox(height: 10),
                                  Material(
                                    color: theme.colorScheme.tertiaryContainer,
                                    borderRadius: BorderRadius.circular(10),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                            'ホストがオフラインです',
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          const Text(
                                            'ゲーム画面で「ホストを引き継ぐ」から開始できます。',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                          const SizedBox(height: 8),
                                          FilledButton.tonal(
                                            onPressed: _claimHostIfAbsent,
                                            child: const Text('ホストを引き継ぐ'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
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
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        _roomPhase == RoomPhase.running
                            ? 'ゲーム画面へ（再参加 / 観戦）'
                            : 'ゲーム画面へ',
                      ),
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

class _RoomIdShareCard extends StatelessWidget {
  const _RoomIdShareCard({
    required this.roomId,
    required this.isHost,
    required this.onCopy,
  });

  final String roomId;
  final bool isHost;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ルームID',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    roomId,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'コピー',
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded),
                ),
              ],
            ),
            Text(
              isHost
                  ? 'このIDを友達に送って、同じルームに参加してもらいましょう。'
                  : '友達にもこのIDを共有できます。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
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
