import 'package:flutter/material.dart';

import 'world_profile.dart';

/// タイトル画面などのプロファイル別アイコン。
abstract final class TitleProfileChrome {
  static IconData iconFor(WorldProfile profile) => switch (profile) {
        WorldProfile.horror => Icons.nightlight_round,
        WorldProfile.sport => Icons.wb_sunny_outlined,
        WorldProfile.sciFi => Icons.hub_outlined,
        WorldProfile.arg => Icons.visibility_off_outlined,
        WorldProfile.magical => Icons.auto_awesome,
        WorldProfile.astronomy => Icons.public,
        WorldProfile.japaneseLuxury => Icons.temple_buddhist_outlined,
        WorldProfile.westernLuxury => Icons.account_balance_outlined,
      };
}
