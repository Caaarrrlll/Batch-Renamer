import 'dart:convert';
import 'dart:io';
import 'package:bulk_renamer/models/rule.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RulePersistence {
  static const _key = 'rules_file_path';

  static Future<String> defaultPath() async {
    final docs = await getApplicationDocumentsDirectory();
    return '${docs.path}${Platform.pathSeparator}Bulk-Renamer${Platform.pathSeparator}settings.json';
  }

  static Future<String> currentPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? await defaultPath();
  }

  static Future<void> setPath(String newPath) async {
    final prefs = await SharedPreferences.getInstance();
    final oldPath = prefs.getString(_key);
    await prefs.setString(_key, newPath);

    if (oldPath != null && oldPath != newPath) {
      final oldFile = File(oldPath);
      if (await oldFile.exists()) {
        final newFile = File(newPath);
        final dir = newFile.parent;
        if (!await dir.exists()) await dir.create(recursive: true);
        await oldFile.rename(newFile.path);
      }
    }
  }

  static Future<File> get _file async {
    return File(await currentPath());
  }

  static Future<void> save(List<Rule> rules) async {
    final file = await _file;
    final dir = file.parent;
    if (!await dir.exists()) await dir.create(recursive: true);
    final data = rules.map((r) => r.toJson()).toList();
    await file.writeAsString(jsonEncode(data));
  }

  static Future<List<Rule>> load() async {
    try {
      final file = await _file;
      if (!await file.exists()) return [];
      final data = jsonDecode(await file.readAsString()) as List;
      return data
          .map((e) => Rule.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
