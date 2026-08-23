import 'dart:io';

import 'package:bulk_renamer/models/rule.dart';

class RenameResult {
  final int renamed;
  final int failed;

  const RenameResult(this.renamed, this.failed);
}

class FileRenamingService {
  static Future<RenameResult> renameFiles(
    List<String> paths,
    List<Rule> rules,
  ) async {
    int renamed = 0;
    int failed = 0;

    for (final rule in rules) {
      rule.reset();
    }

    for (final oldPath in paths) {
      final oldName = oldPath.split(Platform.pathSeparator).last;
      var newName = oldName;
      for (final rule in rules) {
        newName = rule.apply(newName);
      }
      if (newName == oldName) continue;

      final dir = File(oldPath).parent.path;
      final newPath = '$dir${Platform.pathSeparator}$newName';

      try {
        await File(oldPath).rename(newPath);
        renamed++;
      } catch (e) {
        failed++;
      }
    }

    return RenameResult(renamed, failed);
  }
}
