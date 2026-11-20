import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:bulk_renamer/models/rule.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RulesLoadResult {
  final List<Rule> rules;

  /// Number of saved rules that could not be read and were left out.
  final int skipped;

  /// True when the file could not be read or parsed at all.
  final bool unreadable;

  /// Where the original file was copied before anything could overwrite it,
  /// or null if nothing needed backing up or the backup failed.
  final String? backupPath;

  const RulesLoadResult(
    this.rules, {
    this.skipped = 0,
    this.unreadable = false,
    this.backupPath,
  });

  bool get hasProblems => unreadable || skipped > 0;
}

class RulePersistence {
  static const _key = 'rules_file_path';

  static const _fileName = 'settings.json';

  static Future<String> defaultPath() async {
    final docs = await getApplicationDocumentsDirectory();
    return '${docs.path}${Platform.pathSeparator}Bulk-Renamer${Platform.pathSeparator}$_fileName';
  }

  static Future<String> currentPath() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key) ?? await defaultPath();
    return _toFilePath(raw);
  }

  /// Changes where rules are saved.
  ///
  /// If a rules file already exists at [newPath] it is used as-is and this
  /// returns true, so the caller can load the rules from it. Otherwise the
  /// current file is moved there and this returns false. The setting only
  /// changes once the file is in place, and throws [FileSystemException] if
  /// it can't be.
  static Future<bool> setPath(String newPath) async {
    final normalized = _toFilePath(newPath);
    if (normalized.isEmpty) return false;

    final oldPath = await currentPath();
    if (_samePath(oldPath, normalized)) return false;

    final target = File(normalized);
    final usedExisting = await target.exists();
    if (!usedExisting) {
      final old = File(oldPath);
      await target.parent.create(recursive: true);
      if (await old.exists()) {
        // Copy then delete, because rename fails across drives.
        await old.copy(target.path);
        try {
          await old.delete();
        } on FileSystemException catch (e, s) {
          // The rules are safe in the new location; a leftover old file
          // is harmless.
          log(
            'Could not delete old rules file',
            name: 'RulePersistence.setPath',
            error: e,
            stackTrace: s,
          );
        }
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, normalized);
    return usedExisting;
  }

  static bool _samePath(String a, String b) =>
      Platform.isWindows ? a.toLowerCase() == b.toLowerCase() : a == b;

  static Future<File> get _file async {
    return File(await currentPath());
  }

  static String _toFilePath(String raw) {
    final path = raw.trim();
    if (path.isEmpty) return path;
    try {
      if (FileSystemEntity.isDirectorySync(path)) {
        final sep = Platform.pathSeparator;
        return path.endsWith(sep) ? '$path$_fileName' : '$path$sep$_fileName';
      }
    } catch (_) {
      // If the path cannot be inspected, leave it as-is.
    }
    return path;
  }

  /// Saves [rules]. Returns false if they could not be written.
  static Future<bool> save(List<Rule> rules) async {
    try {
      var file = await _file;
      if (FileSystemEntity.isDirectorySync(file.path)) {
        file = File(await defaultPath());
      }
      final dir = file.parent;
      if (!await dir.exists()) await dir.create(recursive: true);
      final data = rules.map((r) => r.toJson()).toList();
      await file.writeAsString(jsonEncode(data));
      return true;
    } on FileSystemException catch (e, s) {
      log(
        'Failed to save rules',
        name: 'RulePersistence.save',
        error: e,
        stackTrace: s,
      );
      return false;
    }
  }

  /// Loads the saved rules. Rules that can't be read are left out, and the
  /// original file is backed up first so the next save can't destroy them.
  static Future<RulesLoadResult> load() async {
    final file = await _file;
    if (!await file.exists()) return const RulesLoadResult([]);

    final List<Object?> data;
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) {
        throw const FormatException('Expected a list of rules');
      }
      data = decoded;
    } on Exception catch (e, s) {
      log(
        'Failed to read rules file',
        name: 'RulePersistence.load',
        error: e,
        stackTrace: s,
      );
      return RulesLoadResult(
        const [],
        unreadable: true,
        backupPath: await _backup(file),
      );
    }

    final rules = <Rule>[];
    var skipped = 0;
    for (final item in data) {
      try {
        rules.add(Rule.fromJson(item as Map<String, dynamic>));
      } on FormatException catch (e) {
        skipped++;
        log(
          'Skipped saved rule: $item',
          name: 'RulePersistence.load',
          error: e,
        );
      } on ArgumentError catch (e) {
        // An enum value saved by another version, e.g. Occurrence.byName.
        skipped++;
        log(
          'Skipped saved rule: $item',
          name: 'RulePersistence.load',
          error: e,
        );
      } on TypeError catch (e) {
        // A field with the wrong type.
        skipped++;
        log(
          'Skipped saved rule: $item',
          name: 'RulePersistence.load',
          error: e,
        );
      }
    }

    return RulesLoadResult(
      rules,
      skipped: skipped,
      backupPath: skipped > 0 ? await _backup(file) : null,
    );
  }

  static Future<String?> _backup(File file) async {
    final path = '${file.path}.${DateTime.now().millisecondsSinceEpoch}.bak';
    try {
      await file.copy(path);
      return path;
    } on FileSystemException catch (e, s) {
      log(
        'Failed to back up rules file',
        name: 'RulePersistence.load',
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }
}
