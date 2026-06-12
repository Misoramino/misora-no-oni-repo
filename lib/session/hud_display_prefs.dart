import 'package:shared_preferences/shared_preferences.dart';

import '../features/game_map/hud/hud_compact_line.dart';
import '../session/game_map_prefs.dart';

/// 試合中 HUD 表示の端末保存。
class HudDisplaySettings {
  const HudDisplaySettings({
    this.compactLineSlot = HudCompactLineSlot.all,
    this.showIntelLine = true,
    this.showStatusLine = true,
    this.showConditionLine = true,
    this.markerIconScale = 1.0,
    this.mapLowSpecMode = false,
  });

  final HudCompactLineSlot compactLineSlot;
  final bool showIntelLine;
  final bool showStatusLine;
  final bool showConditionLine;

  /// 地図ピンの基準サイズ倍率（ズーム時の出し分けはそのまま）。
  final double markerIconScale;

  /// 監視カメラのパルス演出などを抑え、GPS 更新の再描画を減らす。
  final bool mapLowSpecMode;

  static const double markerIconScaleMin = 0.65;
  static const double markerIconScaleMax = 1.5;

  static double clampMarkerIconScale(double v) =>
      v.clamp(markerIconScaleMin, markerIconScaleMax);
}

/// 試合中 HUD 一行表示・表示トグルの端末保存。
abstract final class HudDisplayPrefs {
  static Future<HudDisplaySettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return HudDisplaySettings(
      compactLineSlot: HudCompactLineSlotLabel.fromStorage(
        prefs.getString(GameMapPrefs.hudCompactLineSlot),
      ),
      showIntelLine: prefs.getBool(GameMapPrefs.hudShowIntelLine) ?? true,
      showStatusLine: prefs.getBool(GameMapPrefs.hudShowStatusLine) ?? true,
      showConditionLine:
          prefs.getBool(GameMapPrefs.hudShowConditionLine) ?? true,
      markerIconScale: HudDisplaySettings.clampMarkerIconScale(
        prefs.getDouble(GameMapPrefs.mapMarkerIconScale) ?? 1.0,
      ),
      mapLowSpecMode: prefs.getBool(GameMapPrefs.mapLowSpecMode) ?? false,
    );
  }

  static Future<void> save(HudDisplaySettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      GameMapPrefs.hudCompactLineSlot,
      settings.compactLineSlot.name,
    );
    await prefs.setBool(GameMapPrefs.hudShowIntelLine, settings.showIntelLine);
    await prefs.setBool(
      GameMapPrefs.hudShowStatusLine,
      settings.showStatusLine,
    );
    await prefs.setBool(
      GameMapPrefs.hudShowConditionLine,
      settings.showConditionLine,
    );
    await prefs.setDouble(
      GameMapPrefs.mapMarkerIconScale,
      HudDisplaySettings.clampMarkerIconScale(settings.markerIconScale),
    );
    await prefs.setBool(GameMapPrefs.mapLowSpecMode, settings.mapLowSpecMode);
  }

  static Future<HudCompactLineSlot> loadCompactLineSlot() async {
    return (await load()).compactLineSlot;
  }

  static Future<void> saveCompactLineSlot(HudCompactLineSlot slot) async {
    final current = await load();
    await save(
      HudDisplaySettings(
        compactLineSlot: slot,
        showIntelLine: current.showIntelLine,
        showStatusLine: current.showStatusLine,
        showConditionLine: current.showConditionLine,
      ),
    );
  }
}
