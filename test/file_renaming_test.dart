import 'dart:io';

import 'package:bulk_renamer/models/rule.dart';
import 'package:bulk_renamer/services/file_renaming.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  final sep = Platform.pathSeparator;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('bulk_renamer_test');
  });

  tearDown(() async {
    await dir.delete(recursive: true);
  });

  String create(String name, [String? content]) {
    final file = File('${dir.path}$sep$name')
      ..writeAsStringSync(content ?? name);
    return file.path;
  }

  String read(String name) => File('${dir.path}$sep$name').readAsStringSync();

  List<String> names() =>
      dir.listSync().map((e) => e.path.split(sep).last).toList()..sort();

  group('plan', () {
    test('calculates names without touching disk', () {
      final path = create('a.txt');
      final plan = FileRenamingService.plan(
        [path],
        [const InsertRule(insertText: 'x_')],
      );

      expect(plan.entries.single.newName, 'x_a.txt');
      expect(plan.hasProblems, isFalse);
      expect(names(), ['a.txt']);
    });

    test('flags files that would get the same name', () {
      final a = create('a1.txt');
      final b = create('a2.txt');
      final plan = FileRenamingService.plan(
        [a, b],
        [const DeleteRule(fromPosition: 2)],
      );

      expect(
        plan.entries.map((e) => e.problem),
        everyElement('Another file would get the same name'),
      );
    });

    test('flags a target that already exists outside the batch', () {
      final a = create('a.txt');
      create('b.txt');
      final plan = FileRenamingService.plan(
        [a],
        [const FindReplaceRule(find: 'a', replace: 'b')],
      );

      expect(
        plan.entries.single.problem,
        'A file with this name already exists',
      );
    });

    test('flags a target held by an unchanged file in the batch', () {
      final a = create('a.txt');
      final b = create('b.txt');
      final plan = FileRenamingService.plan(
        [a, b],
        [const FindReplaceRule(find: 'a', replace: 'b')],
      );

      expect(
        plan.entries.first.problem,
        'A file with this name already exists',
      );
      expect(plan.entries.last.problem, isNull);
    });

    test('flags a name reduced to only its extension', () {
      final a = create('a.txt');
      final plan = FileRenamingService.plan([a], [const DeleteRule()]);

      expect(plan.entries.single.newName, '.txt');
      expect(plan.entries.single.problem, 'Name would be only an extension');
    });

    test('handles files in a folder that no longer exists', () {
      final path = '${dir.path}${sep}gone${sep}a.txt';
      final plan = FileRenamingService.plan(
        [path],
        [const InsertRule(insertText: 'x_')],
      );

      expect(plan.entries.single.newName, 'x_a.txt');
      expect(plan.hasProblems, isFalse);
    });

    test('allows a case-only rename', () {
      final a = create('a.txt');
      final plan = FileRenamingService.plan(
        [a],
        [const ChangeCaseRule(changeCase: ChangeCase.upperCase)],
      );

      expect(plan.entries.single.newName, 'A.txt');
      expect(plan.hasProblems, isFalse);
    });

    test('numbers files consecutively even if rules were used before', () {
      final a = create('a.txt');
      final b = create('b.txt');
      final rule = SerializeRule();
      rule.apply('earlier preview');

      final plan = FileRenamingService.plan([a, b], [rule]);

      expect(plan.entries.map((e) => e.newName), ['1a.txt', '2b.txt']);
    });
  });

  group('nameProblem', () {
    String? problem(String name, {bool windows = true}) =>
        FileRenamingService.nameProblem(
          name,
          oldName: 'old.txt',
          windows: windows,
        );

    test('accepts normal names', () {
      expect(problem('new name (1).txt'), isNull);
    });

    test('rejects empty names', () {
      expect(problem(''), 'Name is empty');
      expect(problem('   '), 'Name is empty');
    });

    test('rejects path separators everywhere', () {
      expect(problem('a/b.txt', windows: false), isNotNull);
    });

    test('rejects characters Windows does not allow', () {
      for (final c in ['<', '>', ':', '"', '\\', '|', '?', '*']) {
        expect(problem('a${c}b.txt'), isNotNull, reason: c);
      }
      expect(problem('a:b.txt', windows: false), isNull);
    });

    test('rejects trailing spaces and dots on Windows', () {
      expect(problem('name.'), isNotNull);
      expect(problem('name '), isNotNull);
    });

    test('rejects reserved Windows names', () {
      expect(problem('CON.txt'), isNotNull);
      expect(problem('nul'), isNotNull);
      expect(problem('com1.log'), isNotNull);
      expect(problem('CONSOLE.txt'), isNull);
    });

    test('allows dot files that were already dot files', () {
      expect(
        FileRenamingService.nameProblem(
          '.config',
          oldName: '.Config',
          windows: true,
        ),
        isNull,
      );
    });
  });

  group('execute', () {
    test('renames files', () async {
      final a = create('a.txt');
      final plan = FileRenamingService.plan(
        [a],
        [const InsertRule(insertText: 'x_')],
      );

      final result = await FileRenamingService.execute(plan);

      expect(result.renamed, 1);
      expect(result.failures, isEmpty);
      expect(names(), ['x_a.txt']);
    });

    test('refuses a plan with problems', () async {
      final a = create('a.txt');
      create('b.txt');
      final plan = FileRenamingService.plan(
        [a],
        [const FindReplaceRule(find: 'a', replace: 'b')],
      );

      expect(() => FileRenamingService.execute(plan), throwsStateError);
      expect(read('b.txt'), 'b.txt');
    });

    test('handles chained renames without overwriting', () async {
      final a = create('a.txt');
      final b = create('b.txt');
      // a -> b, b -> c
      final plan = FileRenamingService.plan(
        [a, b],
        [
          const FindReplaceRule(find: 'b', replace: 'c'),
          const FindReplaceRule(find: 'a', replace: 'b'),
        ],
      );
      expect(plan.hasProblems, isFalse);

      final result = await FileRenamingService.execute(plan);

      expect(result.failures, isEmpty);
      expect(names(), ['b.txt', 'c.txt']);
      expect(read('b.txt'), 'a.txt');
      expect(read('c.txt'), 'b.txt');
    });

    test('swaps two names', () async {
      final a = create('a.txt');
      final b = create('b.txt');
      final plan = FileRenamingService.plan(
        [a, b],
        [
          const FindReplaceRule(find: 'a', replace: 'x'),
          const FindReplaceRule(find: 'b', replace: 'a'),
          const FindReplaceRule(find: 'x', replace: 'b'),
        ],
      );
      expect(plan.hasProblems, isFalse);

      final result = await FileRenamingService.execute(plan);

      expect(result.failures, isEmpty);
      expect(read('a.txt'), 'b.txt');
      expect(read('b.txt'), 'a.txt');
    });

    test('renames only the case of a name', () async {
      final a = create('a.txt');
      final plan = FileRenamingService.plan(
        [a],
        [const ChangeCaseRule(changeCase: ChangeCase.upperCase)],
      );

      final result = await FileRenamingService.execute(plan);

      expect(result.failures, isEmpty);
      expect(names(), ['A.txt']);
    });

    test('does not overwrite a file created after planning', () async {
      final a = create('a.txt');
      final plan = FileRenamingService.plan(
        [a],
        [const FindReplaceRule(find: 'a', replace: 'b')],
      );
      create('b.txt', 'keep me');

      final result = await FileRenamingService.execute(plan);

      expect(result.renamed, 0);
      expect(result.failures.single.path, a);
      expect(read('a.txt'), 'a.txt');
      expect(read('b.txt'), 'keep me');
    });

    test('reports a missing file as a failure', () async {
      final a = create('a.txt');
      final plan = FileRenamingService.plan(
        [a],
        [const InsertRule(insertText: 'x_')],
      );
      File(a).deleteSync();

      final result = await FileRenamingService.execute(plan);

      expect(result.renamed, 0);
      expect(result.failures.single.path, a);
    });

    test('reports where each file went', () async {
      final a = create('a.txt');
      final plan = FileRenamingService.plan(
        [a],
        [const InsertRule(insertText: 'x_')],
      );

      final result = await FileRenamingService.execute(plan);

      expect(result.moves, {a: '${dir.path}${sep}x_a.txt'});
    });
  });

  group('undo', () {
    Future<RenameResult> rename(List<String> paths, List<Rule> rules) =>
        FileRenamingService.execute(FileRenamingService.plan(paths, rules));

    test('puts files back to their old names', () async {
      final a = create('a.txt');
      final b = create('b.txt');
      final result = await rename([a, b], [SerializeRule()]);
      expect(names(), ['1a.txt', '2b.txt']);

      final undo = await FileRenamingService.execute(
        FileRenamingService.planUndo(result.moves),
      );

      expect(undo.failures, isEmpty);
      expect(names(), ['a.txt', 'b.txt']);
      expect(read('a.txt'), 'a.txt');
    });

    test('undoes a swap', () async {
      final a = create('a.txt');
      final b = create('b.txt');
      final result = await rename(
        [a, b],
        [
          const FindReplaceRule(find: 'a', replace: 'x'),
          const FindReplaceRule(find: 'b', replace: 'a'),
          const FindReplaceRule(find: 'x', replace: 'b'),
        ],
      );
      expect(read('a.txt'), 'b.txt');

      final undo = await FileRenamingService.execute(
        FileRenamingService.planUndo(result.moves),
      );

      expect(undo.failures, isEmpty);
      expect(read('a.txt'), 'a.txt');
      expect(read('b.txt'), 'b.txt');
    });

    test('restores names that a rename could not create', () async {
      final dotFile = create('.config');
      final result = await rename(
        [dotFile],
        [const InsertRule(insertText: 'my')],
      );
      expect(names(), ['my.config']);

      final plan = FileRenamingService.planUndo(result.moves);

      expect(plan.hasProblems, isFalse);
      await FileRenamingService.execute(plan);
      expect(names(), ['.config']);
    });

    test('refuses to overwrite a file that took an old name', () async {
      final a = create('a.txt');
      final result = await rename([a], [const InsertRule(insertText: 'x_')]);
      create('a.txt', 'new file');

      final plan = FileRenamingService.planUndo(result.moves);

      expect(
        plan.entries.single.problem,
        'A file with this name already exists',
      );
      expect(read('a.txt'), 'new file');
    });
  });
}
