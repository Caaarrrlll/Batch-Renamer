import 'dart:io';

import 'package:bulk_renamer/services/file_list.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
