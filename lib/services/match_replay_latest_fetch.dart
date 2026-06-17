import 'dart:async';

import '../game/match_record.dart';
import 'match_archive_merger.dart';

/// リザルト画面からリプレイを開くときの最新アーカイブ取得結果。
enum MatchReplayFetchSource {
  /// Firestore から取得してマージできた。
  remoteMerged,

  /// 端末保存済みにフォールバック。
  localFallback,

  /// 再生可能な記録がない。
  none,
}

class MatchReplayResolveResult {
  const MatchReplayResolveResult({
    required this.source,
    this.record,
  });

  final MatchReplayFetchSource source;
  final SavedMatchRecord? record;

  bool get hasRecord => record != null;
}

/// リザルト直後のリプレイ用。ギャラリーからは [resolveForGallery] を使う。
abstract final class MatchReplayLatestFetch {
  static const Duration defaultTimeout = Duration(seconds: 5);

  /// 最新 merged archive の取得を試み、失敗時は [local] にフォールバック。
  static Future<MatchReplayResolveResult> resolveForResultReplay({
    required SavedMatchRecord? local,
    Future<SavedMatchRecord?> Function()? fetchRemote,
    Duration timeout = defaultTimeout,
    bool attemptRemote = true,
  }) async {
    if (local == null) {
      return const MatchReplayResolveResult(source: MatchReplayFetchSource.none);
    }
    if (!attemptRemote || fetchRemote == null) {
      return MatchReplayResolveResult(
        source: MatchReplayFetchSource.localFallback,
        record: local,
      );
    }
    try {
      final remote = await fetchRemote().timeout(timeout);
      if (remote != null) {
        final merged = MatchArchiveMerger.merge(local: local, remote: remote);
        return MatchReplayResolveResult(
          source: MatchReplayFetchSource.remoteMerged,
          record: merged,
        );
      }
      return MatchReplayResolveResult(
        source: MatchReplayFetchSource.localFallback,
        record: local,
      );
    } on TimeoutException {
      return MatchReplayResolveResult(
        source: MatchReplayFetchSource.localFallback,
        record: local,
      );
    } catch (_) {
      return MatchReplayResolveResult(
        source: MatchReplayFetchSource.localFallback,
        record: local,
      );
    }
  }

  /// 取得試行後のトースト文言。試行しなかった場合は null。
  static String? toastAfterResolve(
    MatchReplayResolveResult result, {
    required bool attemptedRemote,
  }) {
    if (result.source == MatchReplayFetchSource.remoteMerged) {
      return '最新の試合記録を読み込みました';
    }
    if (result.source == MatchReplayFetchSource.localFallback && attemptedRemote) {
      return '保存済みの記録を表示します';
    }
    return null;
  }

  /// ギャラリーから手動で最新取得するとき。
  static Future<MatchReplayResolveResult> resolveForGallery({
    required SavedMatchRecord local,
    required Future<SavedMatchRecord?> Function() fetchRemote,
    Duration timeout = defaultTimeout,
  }) =>
      resolveForResultReplay(
        local: local,
        fetchRemote: fetchRemote,
        timeout: timeout,
        attemptRemote: true,
      );

  static String? toastAfterGalleryResolve(MatchReplayResolveResult result) {
    if (result.source == MatchReplayFetchSource.remoteMerged) {
      return '最新の試合記録を読み込みました';
    }
    if (result.source == MatchReplayFetchSource.localFallback) {
      return '保存済みの記録を表示します';
    }
    return null;
  }
}
