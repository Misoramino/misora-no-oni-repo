import 'package:flutter/material.dart';

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
    final scheme = Theme.of(context).colorScheme;
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
              color: steps[i].color ?? scheme.primary,
            ),
            if (i < steps.length - 1)
              Icon(Icons.arrow_forward_rounded,
                  size: 18, color: scheme.outline),
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
    final scheme = Theme.of(context).colorScheme;
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
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text('VS', style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(
            child: _DiagramPanel(
              color: scheme.error,
              icon: Icons.nightlight_round,
              title: '鬼陣営',
              lines: const ['鬼', '人狼（鬼側）', '逃走者を捕らえる'],
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
    final scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 1.6,
      child: CustomPaint(
        painter: _MapConceptPainter(scheme.primary, scheme.tertiary),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _legendRow(Icons.crop_free, 'プレイエリア', scheme.primary),
              _legendRow(Icons.nightlight_round, '鬼の手がかり', scheme.error),
              _legendRow(Icons.shield_outlined, '安全地帯', Colors.green.shade600),
              _legendRow(Icons.storefront_outlined, '情報屋', scheme.tertiary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendRow(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11)),
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
  });

  final IconData icon;
  final String label;
  final Color color;

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
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
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
  });

  final Color color;
  final IconData icon;
  final String title;
  final List<String> lines;

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
              style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          for (final line in lines)
            Text(line,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _MapConceptPainter extends CustomPainter {
  _MapConceptPainter(this.primary, this.tertiary);

  final Color primary;
  final Color tertiary;

  @override
  void paint(Canvas canvas, Size size) {
    final area = RRect.fromRectAndRadius(
      Rect.fromLTWH(8, 8, size.width - 16, size.height - 16),
      const Radius.circular(16),
    );
    canvas.drawRRect(
      area,
      Paint()
        ..color = primary.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      area,
      Paint()
        ..color = primary.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.35),
      10,
      Paint()..color = Colors.red.shade400,
    );
    canvas.drawCircle(
      Offset(size.width * 0.35, size.height * 0.62),
      8,
      Paint()..color = Colors.green.shade500,
    );
    canvas.drawCircle(
      Offset(size.width * 0.55, size.height * 0.72),
      7,
      Paint()..color = tertiary,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
