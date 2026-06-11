import 'accusation_weight.dart';

/// 告発施設初回到着時の案内文。
abstract final class AccusationIntroCopy {
  static String body({
    required String accuseActionLabel,
    required AccusationWeight weight,
  }) {
    return 'このあと告発画面が開きます。'
        '「$accuseActionLabel」で相手を選べます。\n'
        'この試合のルール: ${weight.helperText}';
  }
}
