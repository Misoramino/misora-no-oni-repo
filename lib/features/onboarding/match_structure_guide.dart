import 'package:flutter/material.dart';

import '../../presentation/world/world_legibility.dart';
import '../../presentation/world/world_presentation_context.dart';
import '../../presentation/world/world_ui_helpers.dart';
import '../../presentation/world/widgets/world_scaffold.dart';
import '../../audio/game_audio.dart';
import '../../audio/sfx_id.dart';
import '../../features/how_to_play/guide_diagram_type.dart';
import '../../features/how_to_play/guide_models.dart';
import '../../features/how_to_play/widgets/guide_diagram_slot.dart';
import '../../widgets/juicy_tap.dart';
import '../how_to_play/guide_text.dart';
import 'guide_bullet_list.dart';

/// 第2段階：試合の構造と駆け引き（初回準備画面など）。
Future<bool?> showMatchStructureGuide(BuildContext context) {
  GameAudio.instance.playSfx(SfxId.uiConfirm);
  return Navigator.of(context).push<bool>(
    PageRouteBuilder<bool>(
      opaque: true,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondary) =>
          const _MatchStructureGuide(),
      transitionsBuilder: (context, animation, secondary, child) {
        return FadeTransition(opacity: animation, child: child);
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
    this.subtitle,
    this.diagram,
  });

  final IconData icon;
  final Color color;
  final String title;
  final List<String> lines;
  final String? subtitle;
  final GuideDiagramData? diagram;
}

const _pages = <_GuidePage>[
  _GuidePage(
    icon: Icons.timeline_rounded,
    color: Color(0xFF2E86DE),
    title: '1試合の流れ',
    subtitle: '準備 → 追跡 → 終了（脱落しても続行）',
    diagram: GuideDiagramData(
      type: GuideDiagramType.matchSessionFlow,
      title: '準備 → 追跡 → 終了',
      caption: '脱落しても試合は続行（第二ゲームへ）',
    ),
    lines: [
      'ホストがエリアと時間を決めて「試合を開始」',
      '鬼は追う／逃走者は耐える — スキルとギミックはあとで詳しく',
      '捕まっても“第二の役割”（残響体・鬼影）になり、第二ゲームで味方を助けられます',
      '通話中でも近づき・捕獲の判定は続きます。スキル操作のときだけ ONI PIN を前面に。',
    ],
  ),
  _GuidePage(
    icon: Icons.hub_outlined,
    color: Color(0xFF8E5BD8),
    title: '3役の関係',
    diagram: GuideDiagramData(
      type: GuideDiagramType.roleOverview,
      title: '役職は試合開始時に決まる',
    ),
    lines: [
      '👹 鬼 … 追う側。逃走者を全員捕まえれば勝ち',
      '🏃 逃走者 … 逃げる側。生き残るか告発成功で勝ち',
      '🌙 人狼 … 人数で味方が決まる二面役（次のページ）',
    ],
  ),
  _GuidePage(
    icon: Icons.nightlight_round,
    color: Color(0xFF6C5CE7),
    title: '人狼の駆け引き',
    diagram: GuideDiagramData(
      type: GuideDiagramType.werewolfNotOni,
      title: '人狼は鬼そのものではない',
    ),
    lines: [
      '【決まり方】生存者のうち、人側・鬼側の人数が少ない方が味方',
      '【つまり？】人が捕まって減るほど、前半は鬼側・後半は人側の味方になりやすい',
      '「人化」「鬼化」で見た目を切り替えて攪乱',
    ],
  ),
  _GuidePage(
    icon: Icons.layers_outlined,
    color: Color(0xFFF39C12),
    title: '逃走者の選択肢',
    subtitle: 'マップ上の施設に近づくと使えます',
    lines: [
      '情報屋 … 鬼の方角・距離がわかる（今の座標まではわからない）',
      '通信障害地帯 … 鬼から見つかりにくくする',
      '安全地帯 … しばらく追跡されにくくなる',
      '告発 … 試合の後半に解禁。条件を満たせば本物の鬼を当てられる',
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
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final page = _pages[_index];
    final profile = context.worldProfile;

    return WorldScaffold(
      profile: profile,
      body: WorldScaffoldThemed(
        profile: profile,
        child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  GameAudio.instance.playSfx(SfxId.uiBack);
                  Navigator.of(context).pop(false);
                },
                style: TextButton.styleFrom(
                  foregroundColor: context.worldAccentReadable,
                ),
                child: const Text('スキップ'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    '試合の構造',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.worldAccentReadable,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'スキルの細部の前に、試合全体の流れと役職の動きを共有します',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.worldMutedOnScaffold,
                      height: 1.35,
                    ),
                  ),
                  if (page.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      GuideText.forDisplay(page.subtitle!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.worldMutedOnScaffold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => RepaintBoundary(
                  child: _GuideCard(page: _pages[i]),
                ),
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
                      foregroundColor: context.worldButtonLabel,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(page.icon, size: 36, color: page.color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  page.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.worldBodyOnScaffold,
                  ),
                ),
              ),
            ],
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
                : context.worldMutedOnScaffold,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
