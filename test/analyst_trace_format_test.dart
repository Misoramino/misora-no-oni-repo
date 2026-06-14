import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/game/analyst_trace_format.dart';
import 'package:oni_game/game/anonymous_reveal_trace.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('AnalystTraceFormat.errorLabel', () {
    test('near zero error is high confidence', () {
      expect(AnalystTraceFormat.errorLabel(0), contains('信頼: 高'));
    });

    test('moderate error is medium confidence', () {
      expect(AnalystTraceFormat.errorLabel(40), contains('約40m'));
      expect(AnalystTraceFormat.errorLabel(40), contains('信頼: 中'));
    });

    test('large error is low confidence', () {
      expect(AnalystTraceFormat.errorLabel(90), contains('信頼: 低'));
    });
  });

  test('summaryLine includes error not source-based confidence', () {
    final trace = AnonymousRevealTrace(
      timestamp: DateTime.utc(2026, 1, 1, 12),
      position: const LatLng(35, 139),
      reasonSummary: '監視カメラ',
      narrative: 'test',
      source: AnonymousTraceSource.periodic,
      errorMeters: 18,
    );
    final line = AnalystTraceFormat.summaryLine(trace, DateTime.utc(2026, 1, 1, 12, 1));
    expect(line, contains('定期観測'));
    expect(line, contains('約18m'));
    expect(line, contains('信頼: 高'));
  });
}
