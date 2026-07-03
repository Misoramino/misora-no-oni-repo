// ignore_for_file: avoid_print

// 可読性アンチパターンの静的監査。
import 'dart:io';

const _scanRoots = [
  'lib/features/how_to_play',
  'lib/features/onboarding',
  'lib/features/tutorial',
  'lib/screens/title_screen.dart',
  'lib/screens/progress_screen.dart',
  'lib/features/game_map/prep',
];

const _allowOnSurface = {
  'lib/theme/app_theme_factory.dart',
  'lib/presentation/world/world_ui_helpers.dart',
  'lib/theme/map_hud_contrast.dart',
};

const _forbiddenInGuideDiagrams = [
  'colorScheme.outline',
  'colorScheme.tertiary',
  'colorScheme.outlineVariant',
  'scheme.outline',
  'scheme.tertiary',
  'scheme.outlineVariant',
];

void main() {
  final violations = <String>[];

  for (final root in _scanRoots) {
    final entity = FileSystemEntity.typeSync(root);
    if (entity == FileSystemEntityType.directory) {
      _walkDirectory(Directory(root), violations);
    } else if (entity == FileSystemEntityType.file) {
      _scanFile(File(root), violations);
    }
  }

  _scanFile(
    File('lib/features/how_to_play/widgets/guide_diagram_views.dart'),
    violations,
    extraForbidden: _forbiddenInGuideDiagrams,
    skipWorldBodyHeuristic: true,
  );

  if (violations.isEmpty) {
    print('audit_legibility: OK (no violations)');
    exit(0);
  }

  print('audit_legibility: ${violations.length} violation(s)\n');
  for (final v in violations) {
    print(v);
  }
  print('\nSee docs/LEGIBILITY_RULES.md');
  exit(1);
}

void _walkDirectory(Directory dir, List<String> violations) {
  if (!dir.existsSync()) return;
  for (final entity in dir.listSync(recursive: true, followLinks: false)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      _scanFile(entity, violations);
    }
  }
}

void _scanFile(
  File file,
  List<String> violations, {
  List<String> extraForbidden = const [],
  bool skipWorldBodyHeuristic = false,
}) {
  if (!file.existsSync()) return;
  final path = file.path.replaceAll('\\', '/');
  if (_allowOnSurface.contains(path)) return;

  final lines = file.readAsLinesSync();
  final fileUsesPanelThemed = lines.any((l) => l.contains('WorldPanelThemed'));
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trim();
    if (trimmed.startsWith('//')) continue;
    if (trimmed.contains('legibility:ok')) continue;

    final lineNo = i + 1;

    if (line.contains('colorScheme.onSurface') ||
        line.contains('colorScheme.onSurfaceVariant')) {
      violations.add('$path:$lineNo  uses colorScheme.onSurface* — prefer '
          'worldBodyOnScaffold / worldTextOn(bg) / prepHudLegibility');
    }

    for (final token in extraForbidden) {
      if (line.contains(token)) {
        violations.add(
          '$path:$lineNo  uses $token — prefer diagramLegibility() or worldMuted',
        );
      }
    }

    if (path.contains('how_to_play') &&
        !skipWorldBodyHeuristic &&
        !path.endsWith('guide_diagram_views.dart') &&
        !fileUsesPanelThemed &&
        line.contains('worldBody') &&
        !line.contains('worldBodyOnScaffold') &&
        !path.contains('world_legibility.dart')) {
      if (line.contains('WorldScaffoldThemed') ||
          line.contains('WorldPanelThemed')) {
        continue;
      }
      if (trimmed.startsWith('color: context.worldBody')) {
        final start = i > 40 ? i - 40 : 0;
        final window = lines.sublist(start, i).join('\n');
          if (!window.contains('WorldPanelThemed') &&
            !window.contains('worldPanelBg') &&
            !window.contains('Card(') &&
            !window.contains('ActionChip') &&
            !window.contains('_DiagramMiniCard')) {
          violations.add(
            '$path:$lineNo  worldBody on possible scaffold — wrap WorldPanelThemed '
            'or use worldBodyOnScaffold',
          );
        }
      }
    }
  }
}
