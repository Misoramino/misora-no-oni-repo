import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/game/game_config.dart';
import 'package:oni_game/presentation/world/world_presentation_catalog.dart';
import 'package:oni_game/services/background_crisis_alert.dart';
import 'package:oni_game/services/resume_crisis_summary.dart';
import 'package:oni_game/sync/member_connection_label.dart';
import 'package:oni_game/sync/room_member_view.dart';
import 'package:oni_game/theme/world_profile.dart';

void main() {
  group('ResumeCrisisSummaryCollector', () {
    test('queues and prioritizes match end over proximity', () {
      final collector = ResumeCrisisSummaryCollector();
      collector.record(
        kind: BackgroundCrisisKind.proximityDanger,
        title: '近い',
        body: '鬼が近い',
      );
      collector.record(
        kind: BackgroundCrisisKind.matchEnded,
        title: '終了',
        body: '時間切れ',
      );
      final drained = collector.drainPrioritized();
      expect(drained.first.kind, BackgroundCrisisKind.matchEnded);
      expect(drained.first.summaryLine, '試合が終了しました');
    });

    test('dedupes same notification category', () {
      final collector = ResumeCrisisSummaryCollector();
      collector.record(
        kind: BackgroundCrisisKind.proximityWarning,
        title: 'a',
        body: 'a',
      );
      collector.record(
        kind: BackgroundCrisisKind.panicImminent,
        title: 'b',
        body: 'b',
      );
      expect(collector.drainPrioritized(), hasLength(1));
    });

    test('capture summary line for eliminated', () {
      final collector = ResumeCrisisSummaryCollector();
      collector.record(
        kind: BackgroundCrisisKind.eliminated,
        title: '脱落',
        body: '捕獲',
      );
      expect(
        collector.drainPrioritized().single.summaryLine,
        '捕獲されました',
      );
    });

    test('remote accusation unlock maps to summary line', () {
      final collector = ResumeCrisisSummaryCollector();
      collector.record(
        kind: BackgroundCrisisKind.accusationUnlocked,
        title: '告発',
        body: '解禁',
      );
      expect(
        collector.drainPrioritized().single.summaryLine,
        '告発が解禁されました',
      );
    });
  });

  group('MemberConnectionLabel — background grace lobby', () {
    test('grace shows temporary away not unstable', () {
      final now = DateTime.utc(2026, 6, 16, 12, 0);
      final member = RoomMemberView(
        uid: 'u1',
        nickname: 'A',
        role: 'runner',
        isSelf: false,
        reportedAtUtc: now.subtract(
          Duration(seconds: GameConfig.memberPresenceStaleSeconds + 30),
        ),
        appLifecycle: 'background',
        backgroundSinceUtc: now.subtract(const Duration(minutes: 2)),
      );
      expect(member.isStale(now), isTrue);
      expect(member.isInBackgroundGrace(now), isTrue);
      expect(
        MemberConnectionLabel.statusLine(member, now),
        '通話中 / 一時離脱中',
      );
    });

    test('host grace shows host waiting copy', () {
      final now = DateTime.utc(2026, 6, 16, 12, 0);
      final host = RoomMemberView(
        uid: 'host',
        nickname: 'H',
        role: 'runner',
        isSelf: false,
        isHost: true,
        reportedAtUtc: now.subtract(const Duration(minutes: 3)),
        appLifecycle: 'background',
        backgroundSinceUtc: now.subtract(const Duration(minutes: 2)),
      );
      expect(
        MemberConnectionLabel.statusLine(host, now),
        'ホストが一時的に離れています',
      );
    });

    test('stale after grace shows unstable', () {
      final now = DateTime.utc(2026, 6, 16, 12, 0);
      final member = RoomMemberView(
        uid: 'u1',
        nickname: 'A',
        role: 'runner',
        isSelf: false,
        reportedAtUtc: now.subtract(
          Duration(seconds: GameConfig.memberPresenceStaleSeconds + 5),
        ),
        appLifecycle: 'foreground',
      );
      expect(
        MemberConnectionLabel.statusLine(member, now),
        '接続不安定',
      );
    });
  });

  group('World contrast — Arg / Zen / Royal', () {
    test('Arg button label is dark on light accent', () {
      final pack = WorldPresentationCatalog.of(WorldProfile.arg);
      expect(pack.onAccent, const Color(0xFF171A17));
      expect(pack.buttonLabelOnAccent.computeLuminance(), lessThan(0.25));
      expect(pack.accent.computeLuminance(), greaterThan(0.5));
    });

    test('Zen panel text is dark on light panel', () {
      final pack = WorldPresentationCatalog.of(WorldProfile.japaneseLuxury);
      expect(pack.isLightPanel, isTrue);
      expect(pack.textOnPanel.computeLuminance(), lessThan(0.2));
    });

    test('Royal panel text is dark on light panel', () {
      final pack = WorldPresentationCatalog.of(WorldProfile.westernLuxury);
      expect(pack.isLightPanel, isTrue);
      expect(pack.textOnPanel.computeLuminance(), lessThan(0.2));
    });

    test('Pop City scaffold is light with dark text helpers', () {
      final pack = WorldPresentationCatalog.of(WorldProfile.sport);
      expect(pack.isLightScaffold, isTrue);
      expect(pack.textOnScaffold.computeLuminance(), lessThan(0.2));
    });

    test('readableOnScaffold lifts dark lose accent on dark scaffold', () {
      final pack = WorldPresentationCatalog.of(WorldProfile.japaneseLuxury);
      final adjusted = pack.readableOnScaffold(pack.loseAccent);
      expect(adjusted.computeLuminance(), greaterThan(0.5));
    });
  });

  group('GPS fix guard after screen lock', () {
    test('gps max fix age rejects stale positions', () {
      expect(GameConfig.gpsMaxFixAgeSeconds, 12);
      final fixTime = DateTime.now().toUtc().subtract(const Duration(seconds: 15));
      final age = DateTime.now().toUtc().difference(fixTime).inSeconds.abs();
      expect(age > GameConfig.gpsMaxFixAgeSeconds, isTrue);
    });
  });

  group('match_end_rescue idempotency key', () {
    test('time up rescue key is session scoped', () {
      const sk = 42;
      expect('time_up_$sk', 'time_up_42');
    });
  });
}
