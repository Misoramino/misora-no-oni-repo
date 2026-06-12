import '../features/how_to_play/guide_terms.dart';
import '../theme/accusation_facility_copy.dart';
import 'accusation_weight.dart';

/// 告発施設初回到着時の案内文。
abstract final class AccusationIntroCopy {
  static String body({
    required String accuseActionLabel,
    required AccusationWeight weight,
  }) {
    return 'このあと告発画面が開きます。'
        '「$accuseActionLabel」で${GuideTerms.trueOni}だと思う相手を選べます。\n'
        '${AccusationFacilityCopy.accuseTargetLine}\n'
        '告発できるのは生存中の${GuideTerms.runner}のみです。\n'
        '生存中の${GuideTerms.trueOni}が施設付近にいると、この施設では告発できません。\n'
        'この試合のルール: ${weight.helperText}';
  }
}
