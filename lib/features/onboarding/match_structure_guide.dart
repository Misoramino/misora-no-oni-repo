import 'package:flutter/material.dart';

import '../../audio/game_audio.dart';
import '../../audio/sfx_id.dart';
import '../../widgets/juicy_tap.dart';

/// 第2段階：試合の構造と駆け引き（初回準備画面など）。
Future<bool?> showMatchStructureGuide(BuildContext context) {
  GameAudio.instance.playSfx(SfxId.uiConfirm);
  return Navigator.of(context).push<bool>(
    PageRouteBuilder<bool>(
      opaque: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 360),
      pageBuilder: (context, animation, secondary) =>
          const _MatchStructureGuide(),
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

class _GuidePage {
  const _GuidePage({
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

const _pages = <_GuidePage>[
  _GuidePage(
    icon: Icons.timeline_rounded,
    color: Color(0xFF2E86DE),
    title: '1試合の流れ',
    lines: [
      '準備 → 追跡フェーズ → （脱落しても続行）→ 終了。',
      '鬼は人を捕まえ、逃走者は時間まで生き残る。',
      'これが本体。スキルやギミックはその上に載る道具です。',
    ],
  ),
  _GuidePage(
    icon: Icons.hub_outlined,
    color: Color(0xFF8E5BD8),
    title: '3役の関係',
    lines: [
      '👹 鬼：追う側。人を0人にすれば勝ち。',
      '🏃 逃走者：逃げる側。時間切れか告発成功で勝ち。',
      '🌙 人狼：常に「少ない方の陣営」の味方（人数で変わる）。',
    ],
  ),
  _GuidePage(
    icon: Icons.nightlight_round,
    color: Color(0xFF6C5CE7),
    title: '人狼の駆け引き',
    lines: [
      '前半：人が多い → 鬼側の味方。鬼化しても人は襲えない。撹乱・誘導が主役。',
      '後半：人が多い → 人側の味方。鬼化すると捕獲できる → 距離を取る。',
      '見た目と陣営は別。ボタン「人化」「鬼化」で姿を切り替えます。',
    ],
  ),
  _GuidePage(
    icon: Icons.layers_outlined,
    color: Color(0xFFF39C12),
    title: '逃走者の3つの選択',
    lines: [
      '情報屋 … 鬼の方角・距離を探る（今の座標そのものではない）。',
      '通信障害地帯 … 今の安全度を上げる（暴露がノイズになりやすい）。',
      '安全地帯 … 未来の安全を買う（一定時間、追われにくくなる）。',
    ],
  ),
  _GuidePage(
    icon: Icons.groups_outlined,
    color: Color(0xFF1FA98A),
    title: 'みんなが狙うもの',
    lines: [
      '鬼 … 痕跡・暴露・スキルで追い、要所へ移動して作戦を立てる。',
      '逃走者 … 上の3ギミック＋告発で生き延びる。',
      '人狼 … 前半は鬼と協力、後半は人と協力（人数で味方が変わる）。',
      '脱落後 … 残響体・鬼影として第二ゲーム。3人以上なら告発も。',
    ],
  ),
];

class _MatchStructureGuide extends StatefulWidget {
  const _MatchStructureGuide();

  @override
  State<_MatchStructureGuide> createState() => _MatchStructureGuideState();
}

class _MatchStructureGuideState extends State<_MatchStructureGuide> {
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
      GameAudio.instance.playSfx(SfxId.uiConfirm);
      Navigator.of(context).pop(true);
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
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
                onPressed: () {
                  GameAudio.instance.playSfx(SfxId.uiBack);
                  Navigator.of(context).pop(false);
                },
                child: const Text('スキップ'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '試合の構造',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _GuideCard(page: _pages[i]),
              ),
            ),
            _Dots(count: _pages.length, index: _index, color: page.color),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: JuicyTap(
                onTap: _next,
                sfx: _isLast ? SfxId.uiConfirm : SfxId.uiTap,
                child: IgnorePointer(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: page.color,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: _next,
                    icon: Icon(
                      _isLast
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                    label: Text(_isLast ? '了解' : '次へ'),
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

class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.page});

  final _GuidePage page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(page.icon, size: 72, color: page.color),
          const SizedBox(height: 24),
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
                  height: 1.45,
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
