import 'package:flutter/material.dart';

import '../../audio/game_audio.dart';
import '../../audio/sfx_id.dart';
import '../../features/how_to_play/guide_diagram_type.dart';
import '../../features/how_to_play/guide_models.dart';
import '../../features/how_to_play/widgets/guide_diagram_slot.dart';
import '../../widgets/juicy_tap.dart';
import 'guide_bullet_list.dart';

/// 初回起動・「遊び方」から開く、スワイプ式のかんたん紹介。
Future<WelcomeResult?> showWelcomeFlow(
  BuildContext context, {
  bool offerTutorial = false,
}) {
  GameAudio.instance.playSfx(SfxId.uiConfirm);
  return Navigator.of(context).push<WelcomeResult>(
    PageRouteBuilder<WelcomeResult>(
      opaque: true,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondary) =>
          _WelcomeFlow(offerTutorial: offerTutorial),
      transitionsBuilder: (context, animation, secondary, child) {
        return FadeTransition(opacity: animation, child: child);
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
    this.diagram,
  });

  final IconData icon;
  final Color color;
  final String title;
  final List<String> lines;
  final GuideDiagramData? diagram;
}

const _pages = <_WelcomePage>[
  _WelcomePage(
    icon: Icons.my_location_rounded,
    color: Color(0xFF2E86DE),
    title: '街がフィールドの鬼ごっこ',
    diagram: GuideDiagramData(
      type: GuideDiagramType.mapConcept,
      title: 'みんな同じエリアの中で遊ぶ',
      caption: 'GPSで歩く。相手の正確な位置は基本見えません。',
    ),
    lines: [
      'ホストが決めたエリア（公園・商店街など）が舞台',
      '手がかり・距離感・スキルで追いかけっこ',
    ],
  ),
  _WelcomePage(
    icon: Icons.emoji_events_outlined,
    color: Color(0xFF8E5BD8),
    title: 'かんたんな勝ち負け',
    diagram: GuideDiagramData(
      type: GuideDiagramType.factionWin,
      title: '時間切れか、全員捕まえるか',
    ),
    lines: [
      '🏃 逃走者：制限時間まで生き残れば勝ち',
      '👹 鬼：逃走者を全員捕まえれば勝ち',
      'くわしい流れは準備画面の「試合の構造」で案内します',
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
      duration: const Duration(milliseconds: 280),
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
                itemBuilder: (context, i) => RepaintBoundary(
                  child: _WelcomeCard(page: _pages[i]),
                ),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    page.color.withValues(alpha: 0.32),
                    page.color.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Icon(page.icon, size: 56, color: page.color),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          if (page.diagram != null) ...[
            GuideDiagramSlot(data: page.diagram!),
            const SizedBox(height: 12),
          ],
          GuideBulletList(lines: page.lines, accent: page.color),
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

enum WelcomeResult {
  play,
  tutorial,
  skipped,
}
