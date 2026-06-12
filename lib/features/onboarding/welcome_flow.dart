import 'package:flutter/material.dart';

import '../../audio/game_audio.dart';
import '../../audio/sfx_id.dart';
import '../../widgets/juicy_tap.dart';

/// ウェルカム終了後にユーザーが選んだ次の行動。
enum WelcomeResult {
  /// 「やってみる」でそのまま閉じる。
  play,

  /// 「チュートリアル」を希望（B 段階で利用）。
  tutorial,

  /// スキップ／戻る。
  skipped,
}

/// 初回起動・「遊び方」から開く、スワイプ式のかんたん紹介。
Future<WelcomeResult?> showWelcomeFlow(
  BuildContext context, {
  bool offerTutorial = false,
}) {
  GameAudio.instance.playSfx(SfxId.uiConfirm);
  return Navigator.of(context).push<WelcomeResult>(
    PageRouteBuilder<WelcomeResult>(
      opaque: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 360),
      pageBuilder: (context, animation, secondary) =>
          _WelcomeFlow(offerTutorial: offerTutorial),
      transitionsBuilder: (context, animation, secondary, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    ),
  );
}

class _WelcomePage {
  const _WelcomePage({
    required this.icon,
    required this.color,
    required this.title,
    required this.lines,
  });

  final IconData icon;
  final Color color;
  final String title;
  final List<String> lines;
}

const _pages = <_WelcomePage>[
  _WelcomePage(
    icon: Icons.my_location_rounded,
    color: Color(0xFF2E86DE),
    title: '実際の街がフィールド',
    lines: [
      'スマホのGPSで遊ぶ、リアル鬼ごっこ。',
      'ホストが決めるプレイエリア（地図の枠）の中を歩いて移動。',
      '枠の外に出すぎると位置がバレやすくなります。',
    ],
  ),
  _WelcomePage(
    icon: Icons.groups_rounded,
    color: Color(0xFF8E5BD8),
    title: '3つの役割',
    lines: [
      '🏃 逃走者：時間まで逃げ切れば勝ち。',
      '👹 鬼：逃走者に近づいて捕まえる。',
      '🌙 人狼：少ない方の味方。正体に注意。',
    ],
  ),
  _WelcomePage(
    icon: Icons.bolt_rounded,
    color: Color(0xFFF39C12),
    title: 'スキルで駆け引き',
    lines: [
      '画面下のボタンでスキルを発動。',
      '地図に置くスキルは押し続けて範囲を確認、指を離して設置。',
      '右上の×でキャンセル。まず押してみればすぐ分かる！',
    ],
  ),
  _WelcomePage(
    icon: Icons.shield_moon_outlined,
    color: Color(0xFF6C5CE7),
    title: '脱落しても第二ゲーム',
    lines: [
      '捕まっても試合は続きます。',
      '残響体：監視ジャックや告発施設の陣取り。',
      '復讐の鬼影：告発妨害やカメラ停止で逆襲。',
    ],
  ),
  _WelcomePage(
    icon: Icons.wifi_tethering_rounded,
    color: Color(0xFF5C6BC0),
    title: '友達と遊ぶ・育てる',
    lines: [
      '同じルームIDで集まり、ホストが試合を開始。',
      '途中参加は再参加、リスト外は観戦モード。',
      '勝つと連勝・称号がたまっていく。さあ、最初の1戦を！',
    ],
  ),
];

class _WelcomeFlow extends StatefulWidget {
  const _WelcomeFlow({required this.offerTutorial});

  final bool offerTutorial;

  @override
  State<_WelcomeFlow> createState() => _WelcomeFlowState();
}

class _WelcomeFlowState extends State<_WelcomeFlow> {
  final _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      _finish(WelcomeResult.play);
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _finish(WelcomeResult result) {
    GameAudio.instance.playSfx(
      result == WelcomeResult.skipped ? SfxId.uiBack : SfxId.uiConfirm,
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final page = _pages[_index];

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _finish(WelcomeResult.skipped),
                child: const Text('スキップ'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _WelcomeCard(page: _pages[i]),
              ),
            ),
            _Dots(count: _pages.length, index: _index, color: page.color),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Row(
                children: [
                  if (widget.offerTutorial && _isLast) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _finish(WelcomeResult.tutorial),
                        icon: const Icon(Icons.school_rounded),
                        label: const Text('チュートリアル'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: JuicyTap(
                      onTap: _next,
                      sfx: _isLast ? SfxId.uiConfirm : SfxId.uiTap,
                      child: IgnorePointer(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: page.color,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _next,
                          icon: Icon(
                            _isLast
                                ? Icons.play_arrow_rounded
                                : Icons.arrow_forward_rounded,
                          ),
                          label: Text(_isLast ? 'やってみる' : '次へ'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.page});

  final _WelcomePage page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  page.color.withValues(alpha: 0.32),
                  page.color.withValues(alpha: 0.05),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: page.color.withValues(alpha: 0.35),
                  blurRadius: 32,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(page.icon, size: 68, color: page.color),
          ),
          const SizedBox(height: 28),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...page.lines.map(
            (l) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index, required this.color});

  final int count;
  final int index;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? color
                : Theme.of(context).colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
