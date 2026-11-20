import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class RecoveryResult {
  /// Files moved back from a temporary name to their original name.
  final List<String> restored;

  /// Files still at a temporary name, with the reason they couldn't be
  /// moved back.
  final List<({String tempPath, String originalPath, String reason})> stuck;

  const RecoveryResult(this.restored, this.stuck);

  bool get isEmpty => restored.isEmpty && stuck.isEmpty;
}

/// Records which files are at a temporary name while a rename runs, so that
/// if the app stops part-way (a crash or power cut), the next start can move
/// them back.
///
/// The temporary files are the user's real files, never copies, so they are
/// only ever renamed back, never deleted.
class RenameJournal {
  final File file;

  RenameJournal(this.file);

  static Future<RenameJournal> open() async {
    final dir = await getApplicationSupportDirectory();
    return RenameJournal(
      File('${dir.path}${Platform.pathSeparator}rename-journal.json'),
    );
  }

  /// Saves [tempToOriginal] (temporary path to original path) to disk before
  /// any file is moved.
  Future<void> record(Map<String, String> tempToOriginal) async {
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(tempToOriginal), flush: true);
  }

  /// Forgets the journal once a rename has finished, however it ended.
  Future<void> clear() async {
    if (await file.exists()) await file.delete();
  }

  /// Moves any file still at a temporary name from an interrupted rename
  /// back to its original name, unless something else has taken that name.
  /// The journal is cleared afterwards. Throws [FileSystemException] if the
  /// journal can't be read.
  Future<RecoveryResult> recover() async {
    if (!await file.exists()) return const RecoveryResult([], []);

    final Map<String, dynamic> entries;
    try {
      entries = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } on FormatException {
      // A journal cut off mid-write means the rename never started moving
      // files, so there is nothing to recover.
      await clear();
      return const RecoveryResult([], []);
    }

    final restored = <String>[];
    final stuck = <({String tempPath, String originalPath, String reason})>[];
    for (final MapEntry(key: temp, value: original) in entries.entries) {
      final originalPath = original as String;
      if (await FileSystemEntity.type(temp, followLinks: false) ==
          FileSystemEntityType.notFound) {
        continue; // Already moved on to its new name before the stop.
      }
      if (await FileSystemEntity.type(originalPath, followLinks: false) !=
          FileSystemEntityType.notFound) {
        stuck.add((
          tempPath: temp,
          originalPath: originalPath,
          reason: 'Another file now has its original name',
        ));
        continue;
      }
      try {
        if (await FileSystemEntity.isDirectory(temp)) {
          await Directory(temp).rename(originalPath);
        } else {
          await File(temp).rename(originalPath);
        }
        restored.add(originalPath);
      } on FileSystemException catch (e) {
        stuck.add((
          tempPath: temp,
          originalPath: originalPath,
          reason: e.osError?.message.trim() ?? e.message,
        ));
      }
    }

    await clear();
    return RecoveryResult(restored, stuck);
  }
}
