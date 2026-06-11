import 'package:flutter/material.dart';

import '../audio/game_audio.dart';
import '../audio/sfx_id.dart';
import '../game/elimination_aftermath_rule.dart';
import '../game/game_state.dart';
import '../game/match_record.dart';
import '../game/werewolf_faction_logic.dart';
import '../sync/firestore_room_blueprint.dart';
import '../features/game_map/widgets/match_flow_timeline.dart';
import '../features/match/match_result_copy.dart';
import '../progression/player_progress.dart';
import '../progression/player_title.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/motion_helpers.dart';
import '../widgets/responsive_page.dart';

/// 試合終了後の専用リザルト画面（ギャラリー・ロビー・次の準備への導線）。
class MatchResultScreen extends StatefulWidget {
  const MatchResultScreen({
    required this.outcome,
    required this.detail,
    required this.roleSummary,
    required this.matchDurationLabel,
    required this.onPrepareNext,
    required this.onOpenGallery,
    this.endReason,
    this.afterCatchRule,
    this.factionAtDeath,
    this.playerFactionAtEnd,
    this.winningFaction,
    this.progress,
    this.newlyUnlockedTitles = const [],
    this.accusationPointsHuman = 0,
    this.contextualHint,
    this.spectatorMode = false,
    this.spectatorRecord,
    this.onOpenReplay,
    super.key,
  });

  final GameState outcome;
  final String detail;
  final String roleSummary;
  final String matchDurationLabel;
  final EliminationAftermathRule? afterCatchRule;
  final FactionSide? factionAtDeath;
  final FactionSide? playerFactionAtEnd;
  final FactionSide? winningFaction;
  final PlayerProgress? progress;
  final List<PlayerTitle> newlyUnlockedTitles;
  /// 告発ポイントモードで獲得した人陣営ポイント（0なら非表示）。
  final int accusationPointsHuman;
  /// 初勝利・初試合などの状況ヒント（null なら非表示）。
  final String? contextualHint;
  /// インスペクター（観戦）向け。個人戦績・勝敗演出を省略。
  final bool spectatorMode;
  /// 観戦中に組み立てた試合記録（全員軌跡・イベント）。
  final SavedMatchRecord? spectatorRecord;
  final VoidCallback? onOpenReplay;
  final String? endReason;
  final VoidCallback onPrepareNext;
  final VoidCallback onOpenGallery;

  @override
  State<MatchResultScreen> createState() => _MatchResultScreenState();
}

class _MatchResultScreenState extends State<MatchResultScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _showConfetti = false;
  bool _motionReduced = false;

  bool get _personalWon =>
      !widget.spectatorMode &&
      widget.winningFaction != null &&
      (widget.factionAtDeath ?? widget.playerFactionAtEnd) != null &&
      widget.winningFaction ==
          (widget.factionAtDeath ?? widget.playerFactionAtEnd);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MotionHelpers.reduceMotionOf(context);
    if (reduced && !_motionReduced) {
      _motionReduced = true;
      _intro.value = 1.0;
    }
  }

  @override
  void initState() {
    super.initState();
    _intro.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduced = MotionHelpers.reduceMotionOf(context);
      GameAudio.instance.playSfx(
        widget.spectatorMode
            ? SfxId.uiConfirm
            : (_personalWon ? SfxId.matchWin : SfxId.matchLose),
      );
      if (_personalWon && !reduced) {
        setState(() => _showConfetti = true);
        GameAudio.instance.playSfx(SfxId.confetti);
      }
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outcome = widget.outcome;
    final headline = MatchResultCopy.outcomeHeadline(
      outcome: outcome,
      winningFaction: widget.winningFaction,
      endReason: widget.endReason,
      factionAtDeath: widget.factionAtDeath,
      playerFactionAtEnd: widget.playerFactionAtEnd,
      afterCatchRule: widget.afterCatchRule,
    );
    final personalWon = _personalWon;
    final (IconData icon, Color accent) = widget.endReason ==
            MatchEndReason.hostAbort
        ? (Icons.pause_circle_outline, theme.colorScheme.outline)
        : personalWon
        ? (Icons.emoji_events_outlined, Colors.green.shade700)
        : widget.winningFaction == FactionSide.oniTeam
        ? (Icons.front_hand_outlined, Colors.red.shade700)
        : switch (outcome) {
            GameState.runnerWin => (
              Icons.flag_outlined,
              theme.colorScheme.primary,
            ),
            GameState.caughtByOni => (
              Icons.front_hand_outlined,
              Colors.red.shade700,
            ),
            _ => (Icons.flag_outlined, theme.colorScheme.primary),
          };
    final title = headline.title;

    final effectivePersonalFaction =
        widget.factionAtDeath ?? widget.playerFactionAtEnd;
    final personalFactionLabel = effectivePersonalFaction?.label;
    final iconPop = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0, 0.6, curve: Curves.elasticOut),
    );
    final bodyFade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.35, 1, curve: Curves.easeOut),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.spectatorMode ? '観戦リザルト' : 'リザルト'),
      ),
      body: Stack(
        children: [
          ResponsivePage(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ScaleTransition(
                    scale: iconPop,
                    child: _ResultBadge(icon: icon, accent: accent),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                  if (headline.subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      headline.subtitle!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  FadeTransition(
                    opacity: bodyFade,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
              if (!widget.spectatorMode && personalFactionLabel != null) ...[
                const SizedBox(height: 6),
                Text(
                  personalWon
                      ? 'あなたの陣営（$personalFactionLabel）は勝利'
                      : 'あなたの陣営（$personalFactionLabel）は敗北',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: personalWon ? Colors.green.shade700 : Colors.grey.shade700,
                  ),
                ),
              ],
              if (widget.spectatorMode) ...[
                const SizedBox(height: 6),
                Text(
                  widget.spectatorRecord != null
                      ? '観戦記録 — ${widget.spectatorRecord!.tracks.length} 人分の軌跡を保存'
                      : '観戦モード — 個人の勝敗・戦績は記録されません',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(widget.detail, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.spectatorMode ? '観戦情報' : 'あなたの役職・スキル',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(widget.roleSummary),
                      if (widget.factionAtDeath != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '脱落時の陣営: ${widget.factionAtDeath!.label}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ] else if (widget.playerFactionAtEnd != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'あなたの陣営: ${widget.playerFactionAtEnd!.label}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        '制限時間: ${widget.matchDurationLabel}',
                        style: theme.textTheme.bodySmall,
                      ),
                      if (widget.accusationPointsHuman > 0) ...[
                        const SizedBox(height: 6),
                        Text(
                          '告発ポイント: ${widget.accusationPointsHuman}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (widget.spectatorMode && widget.spectatorRecord != null) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '試合の流れ',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        MatchFlowTimeline(
                          reveals: widget.spectatorRecord!.reveals,
                          events: widget.spectatorRecord!.events,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (widget.progress != null) ...[
                const SizedBox(height: 12),
                _ProgressCard(
                  progress: widget.progress!,
                  reveal: bodyFade,
                ),
              ],
              if (widget.newlyUnlockedTitles.isNotEmpty) ...[
                const SizedBox(height: 12),
                _NewTitlesCard(titles: widget.newlyUnlockedTitles),
              ],
              if (widget.contextualHint != null &&
                  widget.contextualHint!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Card(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.45,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.tips_and_updates_outlined,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.contextualHint!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (outcome == GameState.caughtByOni &&
                  widget.afterCatchRule != null) ...[
                const SizedBox(height: 12),
                Card(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.visibility_outlined,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text('第二ゲーム', style: theme.textTheme.titleSmall),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(widget.afterCatchRule!.label),
                        const SizedBox(height: 6),
                        Text(
                          _afterCatchBlurb(widget.afterCatchRule!),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (widget.spectatorMode && widget.onOpenReplay != null)
                FilledButton.icon(
                  onPressed: widget.onOpenReplay,
                  icon: const Icon(Icons.map_outlined),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text('全員の軌跡を再生'),
                  ),
                ),
              if (widget.spectatorMode && widget.onOpenReplay != null)
                const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: widget.onOpenGallery,
                icon: const Icon(Icons.play_circle_outline),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    widget.spectatorMode ? 'ギャラリー・過去の試合' : '軌跡再生・ギャラリー',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: widget.onPrepareNext,
                icon: const Icon(Icons.restart_alt),
                label: const Text('同じルームで次の試合の準備'),
              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showConfetti)
            Positioned.fill(
              child: ConfettiOverlay(
                onFinished: () {
                  if (mounted) setState(() => _showConfetti = false);
                },
              ),
            ),
        ],
      ),
    );
  }

  String _afterCatchBlurb(EliminationAftermathRule rule) =>
      switch (rule) {
        EliminationAftermathRule.spectralOperative =>
          '地図に戻ると、残響体として監視ジャックや告発施設の陣取りができます。',
        EliminationAftermathRule.revenantOni =>
          '地図に戻ると、復讐の鬼影として告発妨害やカメラ停止ができます。',
        EliminationAftermathRule.ghostSpectator =>
          '地図に戻ると、中立の幽霊として全体のざっくり位置マーカーが表示されます。',
        EliminationAftermathRule.joinOni =>
          '地図に戻ると、鬼側合流として索敵支援用のざっくり位置が表示されます。',
      };
}

/// 累積戦績を、数字のカウントアップ付きで表示するカード。
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress, required this.reveal});

  final PlayerProgress progress;
  final Animation<double> reveal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final streak = progress.currentStreak;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('あなたの戦績', style: theme.textTheme.titleSmall),
                const Spacer(),
                if (streak >= 2)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department_rounded,
                            size: 16, color: Colors.deepOrange),
                        const SizedBox(width: 4),
                        Text(
                          '$streak 連勝中',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _Stat(reveal: reveal, value: progress.matches, label: '試合'),
                _Stat(reveal: reveal, value: progress.wins, label: '勝利'),
                _Stat(
                  reveal: reveal,
                  value: (progress.winRate * 100).round(),
                  label: '勝率%',
                ),
                _Stat(reveal: reveal, value: progress.bestStreak, label: '最高連勝'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.reveal,
    required this.value,
    required this.label,
  });

  final Animation<double> reveal;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          AnimatedBuilder(
            animation: reveal,
            builder: (context, _) {
              final shown = (value * reveal.value).round();
              return Text(
                '$shown',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              );
            },
          ),
          const SizedBox(height: 2),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

/// 新しく解放された称号を強調表示するカード。
class _NewTitlesCard extends StatelessWidget {
  const _NewTitlesCard({required this.titles});

  final List<PlayerTitle> titles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.workspace_premium_rounded,
                    color: theme.colorScheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Text(
                  '称号を獲得！',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...titles.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      t.iconData,
                      size: 20,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t.label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// リザルト見出しのアイコンを、淡い光輪付きのバッジとして表示する。
class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 108,
        height: 108,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              accent.withValues(alpha: 0.28),
              accent.withValues(alpha: 0.04),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.35),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, size: 60, color: accent),
      ),
    );
  }
}
