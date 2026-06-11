import 'play_area.dart';

/// 地図プレビューモードで重ね描きするエリア。
class PlayAreaPreviewEntry {
  const PlayAreaPreviewEntry({
    required this.id,
    required this.area,
    required this.label,
    required this.focused,
    required this.isActive,
  });

  final String id;
  final PlayArea area;
  final String label;
  final bool focused;
  final bool isActive;
}
