import 'dart:io';

import 'package:bulk_renamer/models/rule.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:bulk_renamer/ui/file_handler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FindReplaceRule', () {
    test('replaces all occurrences case-insensitively by default', () {
      const rule = FindReplaceRule(find: 'a', replace: 'o');
      expect(rule.apply('AbcA.txt'), 'obco.txt');
    });

    test('replaces only the first or last occurrence', () {
      const first = FindReplaceRule(
        find: 'x',
        replace: '_',
        occurrence: Occurrence.first,
      );
      const last = FindReplaceRule(
        find: 'x',
        replace: '_',
        occurrence: Occurrence.last,
      );
      expect(first.apply('xax.txt'), '_ax.txt');
      expect(last.apply('xax.txt'), 'xa_.txt');
    });

    test('respects case sensitivity', () {
      const rule = FindReplaceRule(
        find: 'a',
        replace: 'o',
        caseSensitive: true,
      );
      expect(rule.apply('Aa.txt'), 'Ao.txt');
    });

    test('matches whole words only', () {
      const rule = FindReplaceRule(
        find: 'cat',
        replace: 'dog',
        wholeWords: true,
      );
      expect(rule.apply('cat catalog.txt'), 'dog catalog.txt');
    });

    test('treats the search text literally', () {
      const rule = FindReplaceRule(
        find: '.',
        replace: '_',
        skipExtension: false,
      );
      expect(rule.apply('a.b.txt'), 'a_b_txt');
    });

    test('skips the extension unless told otherwise', () {
      const rule = FindReplaceRule(find: 'txt', replace: 'md');
      expect(rule.apply('txt.txt'), 'md.txt');
    });

    test('does nothing with an empty search', () {
      expect(const FindReplaceRule().apply('a.txt'), 'a.txt');
    });
  });

  group('InsertRule', () {
    test('inserts a prefix or suffix', () {
      expect(const InsertRule(insertText: 'x_').apply('a.txt'), 'x_a.txt');
      expect(
        const InsertRule(
          insertText: '_x',
          position: InsertPosition.suffix,
        ).apply('a.txt'),
        'a_x.txt',
      );
    });

    test('inserts at a position, from either end', () {
      const left = InsertRule(
        insertText: '-',
        position: InsertPosition.position,
        positionIndex: 2,
      );
      const right = InsertRule(
        insertText: '-',
        position: InsertPosition.position,
        positionIndex: 2,
        rightToLeft: true,
      );
      expect(left.apply('abc.txt'), 'a-bc.txt');
      expect(right.apply('abc.txt'), 'ab-c.txt');
    });

    test('clamps positions past the end of the name', () {
      const rule = InsertRule(
        insertText: '!',
        position: InsertPosition.position,
        positionIndex: 99,
      );
      expect(rule.apply('ab.txt'), 'ab!.txt');
    });

    test('does nothing with empty text', () {
      expect(const InsertRule().apply('a.txt'), 'a.txt');
    });

    test('treats a leading dot as part of the name', () {
      expect(const InsertRule(insertText: 'x').apply('.env'), 'x.env');
    });
  });

  group('DeleteRule', () {
    test('deletes everything from the default position', () {
      expect(const DeleteRule().apply('abc.txt'), '.txt');
    });

    test('deletes a number of characters from a position', () {
      const rule = DeleteRule(
        fromPosition: 2,
        until: DeleteUntil.count,
        untilCount: 2,
      );
      expect(rule.apply('abcde.txt'), 'ade.txt');
    });

    test('deletes until a delimiter, keeping it if asked', () {
      const remove = DeleteRule(
        until: DeleteUntil.delimiter,
        untilDelimiter: '-',
      );
      const keep = DeleteRule(
        until: DeleteUntil.delimiter,
        untilDelimiter: '-',
        keepDelimiters: true,
      );
      expect(remove.apply('ab-cd.txt'), 'cd.txt');
      expect(keep.apply('ab-cd.txt'), '-cd.txt');
    });

    test('deletes from a delimiter when present', () {
      const rule = DeleteRule(from: DeleteFrom.delimiter, fromDelimiter: '[');
      expect(rule.apply('song [live].mp3'), 'song .mp3');
    });

    test('leaves names without the from delimiter unchanged', () {
      const rule = DeleteRule(from: DeleteFrom.delimiter, fromDelimiter: '[');
      expect(rule.apply('song.mp3'), 'song.mp3');
    });

    test('leaves names unchanged when no from delimiter is set', () {
      const rule = DeleteRule(from: DeleteFrom.delimiter);
      expect(rule.apply('song.mp3'), 'song.mp3');
    });

    test('works right to left from a delimiter', () {
      const rule = DeleteRule(
        from: DeleteFrom.delimiter,
        fromDelimiter: '-',
        rightToLeft: true,
      );
      expect(rule.apply('a-b-c.txt'), 'c.txt');
      expect(rule.apply('abc.txt'), 'abc.txt');
    });

    test('matches multi-character delimiters right to left', () {
      const rule = DeleteRule(
        from: DeleteFrom.delimiter,
        fromDelimiter: ' - ',
        until: DeleteUntil.delimiter,
        untilDelimiter: '[',
        rightToLeft: true,
        keepDelimiters: true,
      );
      expect(rule.apply('Artist [Live] - Song.mp3'), 'Artist [Song.mp3');
    });

    test('matches non-symmetric delimiters right to left', () {
      const rule = DeleteRule(
        from: DeleteFrom.delimiter,
        fromDelimiter: '_vs',
        rightToLeft: true,
      );
      expect(rule.apply('one_vs_two_vs_three.txt'), '_three.txt');
    });

    test('keeps emoji intact right to left', () {
      const rule = DeleteRule(
        until: DeleteUntil.count,
        untilCount: 1,
        rightToLeft: true,
      );
      expect(rule.apply('😀ab.txt'), '😀a.txt');
    });
  });

  group('CleanUpRule', () {
    test('trims spaces by default and does nothing else', () {
      expect(const CleanUpRule().apply('  a_b  .txt'), 'a_b.txt');
    });

    test('replaces separators with spaces', () {
      const rule = CleanUpRule(
        replaceFullStop: true,
        replaceComma: true,
        replaceUnderscore: true,
        replacePlus: true,
        replaceMinus: true,
        replacePipe: true,
      );
      expect(rule.apply('a.b,c_d+e-f|g.txt'), 'a b c d e f g.txt');
    });

    test('strips brackets by occurrence', () {
      const last = CleanUpRule(stripParentheses: true);
      const all = CleanUpRule(
        stripSquareBrackets: true,
        stripCurlyBrackets: true,
        bracketStripOccurrence: Occurrence.all,
      );
      expect(last.apply('a (1) (2).txt'), 'a (1).txt');
      expect(all.apply('a [x] {y} [z].txt'), 'a.txt');
    });

    test('standardizes whitespace', () {
      const rule = CleanUpRule(standardizeWhitespace: true);
      expect(rule.apply('a   b\tc.txt'), 'a b c.txt');
    });
  });

  group('ChangeCaseRule', () {
    String apply(ChangeCase c, String name) =>
        ChangeCaseRule(changeCase: c).apply(name);

    test('changes case and leaves the extension alone', () {
      expect(
        apply(ChangeCase.capitalizeWords, 'hELLO wORLD.TXT'),
        'Hello World.TXT',
      );
      expect(apply(ChangeCase.lowerCase, 'ABC.TXT'), 'abc.TXT');
      expect(apply(ChangeCase.upperCase, 'abc.txt'), 'ABC.txt');
      expect(apply(ChangeCase.invertCase, 'aBc1.txt'), 'AbC1.txt');
      expect(apply(ChangeCase.firstLetter, 'abc def.txt'), 'Abc def.txt');
    });

    test('handles empty names', () {
      expect(apply(ChangeCase.firstLetter, ''), '');
      expect(apply(ChangeCase.upperCase, ''), '');
    });
  });

  group('RegexRule', () {
    test('replaces the first match by default', () {
      const rule = RegexRule(expression: r'\d', replace: '#');
      expect(rule.apply('a1b2.txt'), 'a#b2.txt');
    });

    test('replaces all matches when asked', () {
      const rule = RegexRule(expression: r'\d', replace: '#', replaceAll: true);
      expect(rule.apply('a1b2.txt'), 'a#b#.txt');
    });

    test('inserts numbered groups', () {
      const rule = RegexRule(
        expression: r'^(\w+) - (\w+)$',
        replace: r'$2 - $1',
      );
      expect(rule.apply('Artist - Song.mp3'), 'Song - Artist.mp3');
    });

    test('inserts named groups and the whole match', () {
      const rule = RegexRule(
        expression: r'track(?<n>\d+)',
        replace: r'${n} ($0)',
      );
      expect(rule.apply('track01.mp3'), '01 (track01).mp3');
    });

    test(r'turns $$ into a literal $', () {
      const rule = RegexRule(expression: 'USD', replace: r'$$');
      expect(rule.apply('10 USD.txt'), r'10 $.txt');
    });

    test('keeps references to missing groups as typed', () {
      const rule = RegexRule(expression: r'(a)', replace: r'$2${x}');
      expect(rule.apply('a.txt'), r'$2${x}.txt');
    });

    test('inserts empty text for groups that did not match', () {
      const rule = RegexRule(expression: r'a(x)?', replace: r'[$1]');
      expect(rule.apply('a.txt'), '[].txt');
    });

    test('respects case sensitivity', () {
      const sensitive = RegexRule(expression: 'a', replace: '_');
      const insensitive = RegexRule(
        expression: 'a',
        replace: '_',
        caseSensitive: false,
      );
      expect(sensitive.apply('A.txt'), 'A.txt');
      expect(insensitive.apply('A.txt'), '_.txt');
    });

    test('does nothing with an empty expression', () {
      expect(const RegexRule().apply('a.txt'), 'a.txt');
    });

    test('reports invalid expressions', () {
      expect(const RegexRule(expression: '(').isExpressionValid, isFalse);
      expect(const RegexRule(expression: '(a)').isExpressionValid, isTrue);
    });
  });

  group('SerializeRule', () {
    test('numbers files as a prefix by default', () {
      final rule = SerializeRule();
      expect(rule.apply('a.txt'), '1a.txt');
      expect(rule.apply('b.txt'), '2b.txt');
    });

    test('uses start, step, padding and repeat', () {
      final rule = SerializeRule(
        indexStart: 5,
        step: 5,
        padWithZeros: 3,
        repeat: 2,
        insertWhere: InsertPosition.suffix,
      );
      expect(['a', 'b', 'c', 'd'].map((n) => rule.apply('$n.txt')), [
        'a005.txt',
        'b005.txt',
        'c010.txt',
        'd010.txt',
      ]);
    });

    test('inserts at a position', () {
      final rule = SerializeRule(
        insertWhere: InsertPosition.position,
        positionIndex: 2,
      );
      expect(rule.apply('ab.txt'), 'a1b.txt');
    });

    test('starts again after reset', () {
      final rule = SerializeRule();
      rule.apply('a.txt');
      rule.apply('b.txt');
      rule.reset();
      expect(rule.apply('c.txt'), '1c.txt');
    });
  });

  group('serialization', () {
    final rules = <Rule>[
      const FindReplaceRule(
        find: 'a',
        replace: 'b',
        occurrence: Occurrence.last,
        caseSensitive: true,
        wholeWords: true,
        skipExtension: false,
      ),
      const InsertRule(
        insertText: 'x',
        position: InsertPosition.position,
        positionIndex: 3,
        rightToLeft: true,
      ),
      const DeleteRule(
        from: DeleteFrom.delimiter,
        fromDelimiter: '[',
        until: DeleteUntil.delimiter,
        untilDelimiter: ']',
        keepDelimiters: true,
      ),
      const CleanUpRule(stripParentheses: true, replaceUnderscore: true),
      const ChangeCaseRule(changeCase: ChangeCase.upperCase),
      const RegexRule(expression: r'(\d+)', replace: r'#$1', replaceAll: true),
      SerializeRule(indexStart: 3, step: 2, padWithZeros: 2, repeat: 2),
    ];

    test('every rule survives a JSON round trip', () {
      for (final rule in rules) {
        final copy = Rule.fromJson(rule.toJson());
        expect(copy.runtimeType, rule.runtimeType);
        expect(copy.toJson(), rule.toJson());
      }
    });

    test('rules saved with missing fields load with defaults', () {
      final rule = Rule.fromJson({r'$type': 'insert'});
      expect(rule.toJson(), const InsertRule().toJson());
    });

    test('unknown rule types are rejected', () {
      expect(() => Rule.fromJson({r'$type': 'nope'}), throwsFormatException);
    });
  });

  group('addNewFiles', () {
    final sep = Platform.pathSeparator;
    DropItem item(String name) => DropItemFile('${sep}dir$sep$name');

    test('adds new files and sorts them naturally', () {
      final files = [item('file10.txt')];
      final skipped = addNewFiles(files, [item('file2.txt'), item('a.txt')]);

      expect(skipped, 0);
      expect(files.map((f) => f.name), ['a.txt', 'file2.txt', 'file10.txt']);
    });

    test('skips files already in the list', () {
      final files = [item('a.txt')];
      final skipped = addNewFiles(files, [
        item('a.txt'),
        item('b.txt'),
        item('b.txt'),
      ]);

      expect(skipped, 2);
      expect(files.map((f) => f.name), ['a.txt', 'b.txt']);
    });

    test('treats paths differing only in case as the same on Windows', () {
      final files = [item('a.txt')];
      final skipped = addNewFiles(files, [item('A.TXT')]);

      expect(skipped, Platform.isWindows || Platform.isMacOS ? 1 : 0);
    });
  });

  group('compareNatural', () {
    test('sorts numbers by value', () {
      final names = ['file10.txt', 'file2.txt', 'File1.txt', 'file02b.txt'];
      names.sort(compareNatural);
      expect(names, ['File1.txt', 'file2.txt', 'file02b.txt', 'file10.txt']);
    });

    test('handles long digit runs and mixed names', () {
      final names = [
        'a99999999999999999999',
        'a100000000000000000000',
        'b',
        'a',
      ];
      names.sort(compareNatural);
      expect(names, [
        'a',
        'a99999999999999999999',
        'a100000000000000000000',
        'b',
      ]);
    });

    test('is consistent for equal values with different zeros', () {
      expect(compareNatural('a01', 'a1'), isNot(0));
      expect(compareNatural('a01', 'a1'), -compareNatural('a1', 'a01'));
    });
  });
}
