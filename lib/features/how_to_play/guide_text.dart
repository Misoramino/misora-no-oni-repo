/// 遊び方・チュートリアルなど、プレイヤー向け説明文の表示調整。
abstract final class GuideText {
  static const _nbsp = '\u00A0';

  /// 矢印の手順や番号付きステップが行の途中で折り返されないようにする。
  static String forDisplay(String text) {
    if (text.isEmpty) return text;

    var s = text;

    s = s.replaceAllMapped(
      RegExp(r'([①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳])(?!\u00A0)'),
      (m) => '${m[1]}$_nbsp',
    );

    for (var i = 0; i < 8; i++) {
      final next = s
          .replaceAllMapped(
            RegExp(r'(\S)\s*→\s*(\S)'),
            (m) => '${m[1]}$_nbsp→$_nbsp${m[2]}',
          )
          .replaceAllMapped(
            RegExp(r'(\S)→(\S)'),
            (m) => '${m[1]}$_nbsp→$_nbsp${m[2]}',
          );
      if (next == s) break;
      s = next;
    }

    s = s.replaceAll(' / ', ' $_nbsp/$_nbsp ');

    return s;
  }
}
