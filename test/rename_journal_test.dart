import 'dart:convert';
import 'dart:io';

import 'package:bulk_renamer/models/rule.dart';
import 'package:bulk_renamer/services/file_renaming.dart';
import 'package:bulk_renamer/services/rename_journal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  late RenameJournal journal;
  final sep = Platform.pathSeparator;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('bulk_renamer_journal');
    journal = RenameJournal(File('${dir.path}${sep}journal.json'));
  });

  tearDown(() async {
    await dir.delete(recursive: true);
  });

  String path(String name) => '${dir.path}$sep$name';

  String create(String name, [String? content]) =>
      (File(path(name))..writeAsStringSync(content ?? name)).path;

  List<String> names() =>
      dir.listSync().map((e) => e.path.split(sep).last).toList()..sort();

  group('recover', () {
    test('does nothing without a journal', () async {
      final result = await journal.recover();
      expect(result.isEmpty, isTrue);
    });

    test('moves stranded files back to their original names', () async {
      final temp = create('a.txt.bulk-renamer-1-0.tmp', 'original a');
      await journal.record({temp: path('a.txt')});

      final result = await journal.recover();

      expect(result.restored, [path('a.txt')]);
      expect(result.stuck, isEmpty);
      expect(File(path('a.txt')).readAsStringSync(), 'original a');
      expect(names(), ['a.txt']);
    });

    test('never overwrites a file that took the original name', () async {
      final temp = create('a.txt.bulk-renamer-1-0.tmp', 'original a');
      create('a.txt', 'newer file');
      await journal.record({temp: path('a.txt')});

      final result = await journal.recover();

      expect(result.restored, isEmpty);
      expect(result.stuck.single.tempPath, temp);
      expect(File(path('a.txt')).readAsStringSync(), 'newer file');
      expect(File(temp).readAsStringSync(), 'original a');
    });

    test('skips files that already reached their new name', () async {
      await journal.record({path('gone.tmp'): path('a.txt')});

      final result = await journal.recover();

      expect(result.isEmpty, isTrue);
    });

    test('clears the journal afterwards', () async {
      final temp = create('a.txt.bulk-renamer-1-0.tmp');
      await journal.record({temp: path('a.txt')});

      await journal.recover();

      expect(journal.file.existsSync(), isFalse);
    });

    test('treats a half-written journal as nothing to recover', () async {
      journal.file.writeAsStringSync('{"broken');

      final result = await journal.recover();

      expect(result.isEmpty, isTrue);
      expect(journal.file.existsSync(), isFalse);
    });
  });

  group('rename with a journal', () {
    test('clears the journal after a rename that used temp names', () async {
      final a = create('a.txt');
      final b = create('b.txt');
      // Swap the names, which needs temporary names.
      final plan = FileRenamingService.plan(
        [a, b],
        [
          const FindReplaceRule(find: 'a', replace: 'x'),
          const FindReplaceRule(find: 'b', replace: 'a'),
          const FindReplaceRule(find: 'x', replace: 'b'),
        ],
      );

      final result = await FileRenamingService.execute(plan, journal: journal);

      expect(result.failures, isEmpty);
      expect(File(path('a.txt')).readAsStringSync(), 'b.txt');
      expect(journal.file.existsSync(), isFalse);
    });

    test('does not write a journal when no temp names are needed', () async {
      final a = create('a.txt');
      final plan = FileRenamingService.plan(
        [a],
        [const InsertRule(insertText: 'x_')],
      );

      await FileRenamingService.execute(plan, journal: journal);

      expect(journal.file.existsSync(), isFalse);
      expect(names(), ['x_a.txt']);
    });

    test('does not start if the journal cannot be written', () async {
      final a = create('a.txt');
      final b = create('b.txt');
      final blocker = create('blocker');
      final unwritable = RenameJournal(File('$blocker${sep}journal.json'));
      final plan = FileRenamingService.plan(
        [a, b],
        [
          const FindReplaceRule(find: 'a', replace: 'x'),
          const FindReplaceRule(find: 'b', replace: 'a'),
          const FindReplaceRule(find: 'x', replace: 'b'),
        ],
      );

      final result = await FileRenamingService.execute(
        plan,
        journal: unwritable,
      );

      expect(result.renamed, 0);
      expect(result.failures, hasLength(2));
      expect(File(path('a.txt')).readAsStringSync(), 'a.txt');
      expect(File(path('b.txt')).readAsStringSync(), 'b.txt');
    });

    test('the journal records temp name to original path', () async {
      final temp = path('a.txt.bulk-renamer-1-0.tmp');
      await journal.record({temp: path('a.txt')});

      expect(jsonDecode(journal.file.readAsStringSync()), {
        temp: path('a.txt'),
      });
    });
  });
}
