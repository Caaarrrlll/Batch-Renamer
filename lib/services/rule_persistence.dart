import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:bulk_renamer/models/rule.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static Future<void> setPath(String newPath) async {
    final normalized = _toFilePath(newPath);
    if (normalized.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final oldPath = prefs.getString(_key);
    await prefs.setString(_key, normalized);

    if (oldPath != null && oldPath != normalized) {
      final oldFile = File(oldPath);
      if (await oldFile.exists()) {
        final newFile = File(normalized);
        final dir = newFile.parent;
        if (!await dir.exists()) await dir.create(recursive: true);
        await oldFile.rename(newFile.path);
      }
    }
  }

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

  static Future<void> save(List<Rule> rules) async {
    try {
      var file = await _file;
      if (FileSystemEntity.isDirectorySync(file.path)) {
        file = File(await defaultPath());
      }
      final dir = file.parent;
      if (!await dir.exists()) await dir.create(recursive: true);
      final data = rules.map((r) => r.toJson()).toList();
      await file.writeAsString(jsonEncode(data));
    } catch (e, s) {
      log(
        'Failed to save rules',
        name: 'RulePersistence.save',
        error: e,
        stackTrace: s,
      );
    }
  }

  static Future<List<Rule>> load() async {
    try {
      final file = await _file;
      if (!await file.exists()) return [];
      final data = jsonDecode(await file.readAsString()) as List;
      return data.map((e) => Rule.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e, s) {
      log(
        'Failed to load rules',
        name: 'RulePersistence.load',
        error: e,
        stackTrace: s,
      );
      return [];
    }
  }
}
