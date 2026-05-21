import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/features/branding/oni_pin_mark_geometry.dart';

void main() {
  test('layersFor caches scaled paths by quantized width', () {
    const size = Size(88, 88);
    final a = OniPinMarkGeometry.layersFor(size);
    final b = OniPinMarkGeometry.layersFor(size);
    expect(identical(a, b), isTrue);
    expect(a.coreR, closeTo(6.292, 0.01));
    expect(a.strokeW, closeTo(5.016, 0.01));
  });

  test('beat is stable at pulse wrap', () {
    expect(OniPinMarkGeometry.beat(0), closeTo(0.5, 0.001));
    expect(OniPinMarkGeometry.beat(0.25), closeTo(1.0, 0.001));
  });
}
