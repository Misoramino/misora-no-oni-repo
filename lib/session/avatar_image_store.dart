import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'avatar_thumb_codec.dart';

/// ピン用写真をアプリ内に永続化（ギャラリーの一時パス切れ対策）。
abstract final class AvatarImageStore {
  static const _fileName = 'player_avatar_pin.jpg';

  static Future<String?> persistFromPicker(String sourcePath) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final dest = File('${dir.path}/$_fileName');
      final raw = await File(sourcePath).readAsBytes();
      final resized = await AvatarThumbCodec.resizeForLocalStore(raw);
      if (resized != null) {
        await dest.writeAsBytes(resized, flush: true);
        return dest.path;
      }
      await File(sourcePath).copy(dest.path);
      return dest.path;
    } catch (_) {
      return sourcePath;
    }
  }

  static Future<void> deleteStored() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}/$_fileName');
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}
