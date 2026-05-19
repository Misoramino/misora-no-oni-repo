import 'package:flutter/material.dart';

/// テストモード用の診断オーバーレイ。
class DiagnosticsCard extends StatelessWidget {
  const DiagnosticsCard({
    required this.fps,
    required this.gpsTier,
    required this.gpsAccuracyLast,
    required this.gpsAccuracyAvg,
    required this.batteryScore,
    required this.timeScale,
    required this.onCycleTimeScale,
    required this.onFlushSync,
    required this.debugLogs,
    required this.queueCount,
    required this.proximityText,
    required this.roomSessionText,
    required this.syncInFlight,
    super.key,
  });

  final double fps;
  final String gpsTier;
  final double? gpsAccuracyLast;
  final double gpsAccuracyAvg;
  final double batteryScore;
  final int timeScale;
  final VoidCallback onCycleTimeScale;
  final VoidCallback onFlushSync;
  final List<String> debugLogs;
  final int queueCount;
  final String proximityText;
  final String roomSessionText;
  final bool syncInFlight;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Material(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.speed, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  const Text(
                    'Test Mode',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: onCycleTimeScale,
                    child: Text('${timeScale}x'),
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: syncInFlight ? null : onFlushSync,
                    child: Text(syncInFlight ? 'Sync...' : 'Sync'),
                  ),
                ],
              ),
              Text(
                'FPS: ${fps.toStringAsFixed(1)}',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                'GPS tier: $gpsTier',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                'GPS精度: last=${gpsAccuracyLast?.toStringAsFixed(1) ?? '-'}m / avg=${gpsAccuracyAvg.toStringAsFixed(1)}m',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                'Battery score(est): ${batteryScore.toStringAsFixed(1)}',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                'Offline queue: $queueCount',
                style: const TextStyle(color: Colors.white),
              ),
              Text(proximityText, style: const TextStyle(color: Colors.white)),
              Text(
                'Room: $roomSessionText',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 6),
              const Text(
                'Logs',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              ...debugLogs
                  .take(4)
                  .map(
                    (e) => Text(
                      e,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
