import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/session/avatar_thumb_codec.dart';

void main() {
  test('encodeBytes returns bounded base64', () async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawCircle(const ui.Offset(32, 32), 28, ui.Paint()..color = const ui.Color(0xFF336699));
    final picture = recorder.endRecording();
    final image = await picture.toImage(64, 64);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    expect(data, isNotNull);

    final encoded = await AvatarThumbCodec.encodeBytesForSync(
      data!.buffer.asUint8List(),
    );
    expect(encoded, isNotNull);
    expect(encoded!.length, lessThanOrEqualTo(AvatarThumbCodec.maxEncodedChars));
    expect(AvatarThumbCodec.decode(encoded), isA<Uint8List>());
  });
}
