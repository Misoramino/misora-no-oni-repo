import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../game/match_record.dart';

/// 試合記録JSONをアプリ専用フォルダに保存。
class MatchArchiveStore {
  Future<Directory> _directory() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/oni_match_archive');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _fileForId(String id) async {
    final dir = await _directory();
    final safe = id.replaceAll(RegExp(r'[^\w\-.]+'), '_');
    return File('${dir.path}/$safe.json');
  }

  Future<void> save(SavedMatchRecord record) async {
    final file = await _fileForId(record.id);
    await file.writeAsString(record.encode(), flush: true);
  }

  Future<List<SavedMatchRecord>> listRecent({int limit = 40}) async {
    final dir = await _directory();
    final entries = await dir.list().toList();
    final files =
        entries.whereType<File>().where((f) => f.path.endsWith('.json')).toList();
    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

    final out = <SavedMatchRecord>[];
    for (final f in files) {
      if (out.length >= limit) break;
      try {
        final raw = await f.readAsString();
        out.add(SavedMatchRecord.decode(raw));
      } catch (_) {
        continue;
      }
    }
    return out;
  }

  Future<SavedMatchRecord?> loadById(String id) async {
    try {
      final raw = await _fileForId(id).then((f) => f.readAsString());
      return SavedMatchRecord.decode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> delete(String id) async {
    final f = await _fileForId(id);
    if (await f.exists()) await f.delete();
  }

  Future<int> totalApproxBytes() async {
    final dir = await _directory();
    var sum = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        try {
          sum += await entity.length();
        } catch (_) {}
      }
    }
    return sum;
  }

  Future<void> clearAll() async {
    final dir = await _directory();
    await for (final entity in dir.list(recursive: false)) {
      if (entity is File && entity.path.endsWith('.json')) {
        try {
          await entity.delete();
        } catch (_) {}
      }
    }
  }
}
