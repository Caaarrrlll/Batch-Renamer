import 'dart:convert';
import 'dart:io';

import 'package:bulk_renamer/models/rule.dart';
import 'package:bulk_renamer/services/rule_persistence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late String settingsPath;
  final sep = Platform.pathSeparator;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('bulk_renamer_settings');
    settingsPath = '${dir.path}${sep}settings.json';
    SharedPreferences.setMockInitialValues({'rules_file_path': settingsPath});
  });

  tearDown(() async {
    await dir.delete(recursive: true);
  });

  List<File> backups() => dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.bak'))
      .toList();

  group('load', () {
    test('returns no rules when there is no file', () async {
      final result = await RulePersistence.load();
      expect(result.rules, isEmpty);
      expect(result.hasProblems, isFalse);
    });

    test('loads what was saved', () async {
      final saved = await RulePersistence.save([
        const InsertRule(insertText: 'x'),
        SerializeRule(indexStart: 4),
      ]);
      final result = await RulePersistence.load();

      expect(saved, isTrue);
      expect(result.rules.map((r) => r.toJson()), [
        const InsertRule(insertText: 'x').toJson(),
        SerializeRule(indexStart: 4).toJson(),
      ]);
      expect(result.hasProblems, isFalse);
      expect(backups(), isEmpty);
    });

    test('skips unreadable rules, keeps the rest and backs up', () async {
      final original = jsonEncode([
        const InsertRule(insertText: 'x').toJson(),
        {r'$type': 'fromTheFuture'},
        {r'$type': 'changeCase', 'changeCase': 'sarcasticCase'},
        {r'$type': 'insert', 'insertText': 42},
        'not a rule',
      ]);
      File(settingsPath).writeAsStringSync(original);

      final result = await RulePersistence.load();

      expect(
        result.rules.single.toJson(),
        const InsertRule(insertText: 'x').toJson(),
      );
      expect(result.skipped, 4);
      expect(result.unreadable, isFalse);
      expect(File(result.backupPath!).readAsStringSync(), original);
    });

    test('backs up a file that is not valid JSON', () async {
      File(settingsPath).writeAsStringSync('{ broken');

      final result = await RulePersistence.load();

      expect(result.rules, isEmpty);
      expect(result.unreadable, isTrue);
      expect(File(result.backupPath!).readAsStringSync(), '{ broken');
    });

    test('backs up a file that is JSON but not a list', () async {
      File(settingsPath).writeAsStringSync('{}');

      final result = await RulePersistence.load();

      expect(result.unreadable, isTrue);
      expect(result.backupPath, isNotNull);
    });
  });

  group('setPath', () {
    test('moves the rules file to a new location', () async {
      await RulePersistence.save([const InsertRule(insertText: 'x')]);
      final newPath = '${dir.path}${sep}sub${sep}rules.json';

      final usedExisting = await RulePersistence.setPath(newPath);

      expect(usedExisting, isFalse);
      expect(await RulePersistence.currentPath(), newPath);
      expect(File(settingsPath).existsSync(), isFalse);
      final result = await RulePersistence.load();
      expect(
        result.rules.single.toJson(),
        const InsertRule(insertText: 'x').toJson(),
      );
    });

    test('accepts a folder and stores settings.json in it', () async {
      await RulePersistence.save([const InsertRule(insertText: 'x')]);
      final folder = Directory('${dir.path}${sep}folder')..createSync();

      await RulePersistence.setPath(folder.path);

      expect(
        await RulePersistence.currentPath(),
        '${folder.path}${sep}settings.json',
      );
      expect((await RulePersistence.load()).rules, hasLength(1));
    });

    test(
      'uses an existing file at the new location without touching either',
      () async {
        await RulePersistence.save([const InsertRule(insertText: 'old')]);
        final newPath = '${dir.path}${sep}other.json';
        File(newPath).writeAsStringSync(
          jsonEncode([const InsertRule(insertText: 'new').toJson()]),
        );

        final usedExisting = await RulePersistence.setPath(newPath);

        expect(usedExisting, isTrue);
        expect(File(settingsPath).existsSync(), isTrue);
        final result = await RulePersistence.load();
        expect(
          result.rules.single.toJson(),
          const InsertRule(insertText: 'new').toJson(),
        );
      },
    );

    test('works when nothing has been saved yet', () async {
      final newPath = '${dir.path}${sep}rules.json';

      final usedExisting = await RulePersistence.setPath(newPath);

      expect(usedExisting, isFalse);
      expect(await RulePersistence.currentPath(), newPath);
    });

    test('keeps the old setting when the file cannot be moved', () async {
      await RulePersistence.save([const InsertRule(insertText: 'x')]);
      // A file where a folder is needed makes creating the folder fail.
      final blocker = File('${dir.path}${sep}blocker')..writeAsStringSync('');

      await expectLater(
        RulePersistence.setPath('${blocker.path}${sep}rules.json'),
        throwsA(isA<FileSystemException>()),
      );
      expect(await RulePersistence.currentPath(), settingsPath);
      expect(File(settingsPath).existsSync(), isTrue);
    });
  });
}
