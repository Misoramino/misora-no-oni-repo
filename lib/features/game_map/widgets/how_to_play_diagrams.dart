import 'package:flutter/material.dart';

import '../../how_to_play/guide_text.dart';
import '../../../presentation/world/world_legibility.dart';
import '../../../theme/map_hud_contrast.dart';

/// 作戦マニュアル／旧遊び方シート用の簡易図解。
///
/// - [HelpFlowDiagram]: `guide_diagram_views.dart`（告発・エリア外・スキル設置）で使用中。
/// - [HelpFactionDiagram] / [HelpMapConceptDiagram]: 現行ガイドでは
///   [FactionWinDiagram] 等に置き換え済み。互換・将来再利用のため残置。
class HelpFlowDiagram extends StatelessWidget {
  const HelpFlowDiagram({
    required this.steps,
    super.key,
  });

  final List<({IconData icon, String label, Color? color})> steps;

  @override
  Widget build(BuildContext context) {
    final diag = context.diagramLegibility();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        runSpacing: 8,
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            _DiagramNode(
              icon: steps[i].icon,
              label: steps[i].label,
              color: steps[i].color ?? diag.stroke,
              labelColor: diag.label,
            ),
            if (i < steps.length - 1)
              Icon(Icons.arrow_forward_rounded,
                  size: 18, color: diag.mutedStroke),
          ],
        ],
      ),
    );
  }
}

class HelpFactionDiagram extends StatelessWidget {
  const HelpFactionDiagram({super.key});

  @override
  Widget build(BuildContext context) {
    final diag = context.diagramLegibility();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _DiagramPanel(
              color: const Color(0xFF1FA98A),
              icon: Icons.directions_run_rounded,
              title: '人陣営',
              lines: const ['逃走者', '人狼（人側）', '制限時間まで生き残る'],
              textColor: diag.label,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              'VS',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: diag.label,
                  ),
            ),
          ),
          Expanded(
            child: _DiagramPanel(
              color: const Color(0xFFE53935),
              icon: Icons.nightlight_round,
              title: '鬼陣営',
              lines: const ['鬼', '人狼（鬼側）', '逃走者を捕らえる'],
              textColor: diag.label,
            ),
          ),
        ],
      ),
    );
  }
}

class HelpMapConceptDiagram extends StatelessWidget {
  const HelpMapConceptDiagram({super.key});

  @override
  Widget build(BuildContext context) {
    final diag = context.diagramLegibility();
    return AspectRatio(
      aspectRatio: 1.6,
      child: CustomPaint(
        painter: _MapConceptPainter(diag),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _legendRow(Icons.crop_free, 'プレイエリア', diag.stroke, diag.label),
              _legendRow(Icons.nightlight_round, '鬼の手がかり',
                  const Color(0xFFE53935), diag.label),
              _legendRow(Icons.shield_outlined, '安全地帯',
                  const Color(0xFF43A047), diag.label),
              _legendRow(Icons.storefront_outlined, '情報屋', diag.mutedStroke,
                  diag.label),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendRow(IconData icon, String label, Color color, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(fontSize: 11, color: textColor)),
        ],
      ),
    );
  }
}

class _DiagramNode extends StatelessWidget {
  const _DiagramNode({
    required this.icon,
    required this.label,
    required this.color,
    required this.labelColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            GuideText.forDisplay(label),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: labelColor,
                ),
          ),
        ],
      ),
    );
  }
}

class _DiagramPanel extends StatelessWidget {
  const _DiagramPanel({
    required this.color,
    required this.icon,
    required this.title,
    required this.lines,
    required this.textColor,
  });

  final Color color;
  final IconData icon;
  final String title;
  final List<String> lines;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              )),
          const SizedBox(height: 4),
          for (final line in lines)
            Text(line,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: textColor,
                    )),
        ],
      ),
    );
  }
}

class _MapConceptPainter extends CustomPainter {
  _MapConceptPainter(this.diag);

  final WorldDiagramLegibility diag;

  @override
  void paint(Canvas canvas, Size size) {
    final area = RRect.fromRectAndRadius(
      Rect.fromLTWH(8, 8, size.width - 16, size.height - 16),
      const Radius.circular(16),
    );
    canvas.drawRRect(
      area,
      Paint()
        ..color = diag.fill
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      area,
      Paint()
        ..color = diag.stroke.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.35),
      10,
      Paint()..color = const Color(0xFFE53935),
    );
    canvas.drawCircle(
      Offset(size.width * 0.35, size.height * 0.62),
      8,
      Paint()..color = const Color(0xFF43A047),
    );
    canvas.drawCircle(
      Offset(size.width * 0.55, size.height * 0.72),
      7,
      Paint()..color = diag.mutedStroke,
    );
  }

  @override
  bool shouldRepaint(covariant _MapConceptPainter oldDelegate) =>
      oldDelegate.diag != diag;
}
