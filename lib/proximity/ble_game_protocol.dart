import 'dart:convert';

/// 同一ルームの端末だけを BLE で識別するためのマーカー。
abstract final class BleGameProtocol {
  /// カスタムサービス UUID（スキャンフィルタ用）。
  static const serviceUuid = '6f6e6900-0001-4000-8000-00805f9b34fb';

  /// manufacturerData の会社 ID（テスト用レンジ）。
  static const manufacturerId = 0x4E47; // "NG"

  static const String _magic = 'ONI';

  /// ルーム＋試合セッション＋鬼役アクティブフラグ（12 バイト）。
  ///
  /// 逃走者の BLE スキャンは [advertiseAsOni] が true の端末だけを
  /// 近接「接触」候補にする（同ルームの他逃走者を誤検知しない）。
  static List<int> encodePayload({
    required String roomId,
    required int sessionKey,
    required bool advertiseAsOni,
  }) {
    final roomHash = _fnv1a32(roomId);
    return [
      ...utf8.encode(_magic),
      (roomHash >> 24) & 0xff,
      (roomHash >> 16) & 0xff,
      (roomHash >> 8) & 0xff,
      roomHash & 0xff,
      (sessionKey >> 24) & 0xff,
      (sessionKey >> 16) & 0xff,
      (sessionKey >> 8) & 0xff,
      sessionKey & 0xff,
      advertiseAsOni ? 1 : 0,
    ];
  }

  static bool matchesPayload(
    List<int>? data, {
    required String roomId,
    required int sessionKey,
    bool requireOniBeacon = true,
  }) {
    if (data == null || data.length < 7) return false;
    if (String.fromCharCodes(data.take(3)) != _magic) return false;
    final roomHash = _fnv1a32(roomId);
    final sk = sessionKey;
    final r0 = data[3];
    final r1 = data[4];
    final r2 = data[5];
    final r3 = data[6];
    final gotRoom =
        r0 == ((roomHash >> 24) & 0xff) &&
        r1 == ((roomHash >> 16) & 0xff) &&
        r2 == ((roomHash >> 8) & 0xff) &&
        r3 == (roomHash & 0xff);
    if (!gotRoom || data.length < 11) return false;
    final s0 = data[7];
    final s1 = data[8];
    final s2 = data[9];
    final s3 = data[10];
    if (!(s0 == ((sk >> 24) & 0xff) &&
        s1 == ((sk >> 16) & 0xff) &&
        s2 == ((sk >> 8) & 0xff) &&
        s3 == (sk & 0xff))) {
      return false;
    }
    if (!requireOniBeacon) return true;
    return data.length >= 12 && data[11] == 1;
  }

  static int _fnv1a32(String s) {
    var h = 0x811c9dc5;
    for (final c in s.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h;
  }
}

/// 試合中スキャン／アドバタイズの対象ルーム。
class BleGameScanFilter {
  const BleGameScanFilter({
    required this.roomId,
    required this.sessionKey,
    this.advertiseAsOni = false,
  });

  final String roomId;
  final int sessionKey;

  /// 鬼（または一時鬼化中）の端末だけ 1。逃走者は 0 のままアドバタイズ可。
  final bool advertiseAsOni;

  List<int> get manufacturerPayload => BleGameProtocol.encodePayload(
        roomId: roomId,
        sessionKey: sessionKey,
        advertiseAsOni: advertiseAsOni,
      );
}
