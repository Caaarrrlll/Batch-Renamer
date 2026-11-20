import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';

final _numberOrText = RegExp(r'\d+|\D+');
final _startsWithDigit = RegExp(r'^\d');
final _leadingZeros = RegExp(r'^0+(?=\d)');

/// Compares file names the way people read them: case-insensitively, with
/// runs of digits compared by value, so "file2" sorts before "file10".
int compareNatural(String a, String b) {
  final aParts = _numberOrText.allMatches(a.toLowerCase()).toList();
  final bParts = _numberOrText.allMatches(b.toLowerCase()).toList();

  for (var i = 0; i < aParts.length && i < bParts.length; i++) {
    final x = aParts[i][0]!;
    final y = bParts[i][0]!;
    final xIsNumber = _startsWithDigit.hasMatch(x);
    final yIsNumber = _startsWithDigit.hasMatch(y);

    final int result;
    if (xIsNumber && yIsNumber) {
      // Compare by value without parsing, so long digit runs can't overflow.
      final xValue = x.replaceFirst(_leadingZeros, '');
      final yValue = y.replaceFirst(_leadingZeros, '');
      result = xValue.length != yValue.length
          ? xValue.length.compareTo(yValue.length)
          : xValue.compareTo(yValue);
    } else {
      result = x.compareTo(y);
    }
    if (result != 0) return result;
  }

  final lengthResult = aParts.length.compareTo(bParts.length);
  // Fall back to plain comparison so names like "a01" and "a1" stay stable.
  return lengthResult != 0 ? lengthResult : a.compareTo(b);
}

/// Adds the [added] files that aren't already in [files], then sorts
/// [files] naturally by path, so files stay grouped by folder. Returns how
/// many were skipped as duplicates.
int addNewFiles(List<DropItem> files, Iterable<DropItem> added) {
  final caseInsensitive = Platform.isWindows || Platform.isMacOS;
  String key(String path) => caseInsensitive ? path.toLowerCase() : path;

  final known = files.map((f) => key(f.path)).toSet();
  var skipped = 0;
  for (final item in added) {
    if (known.add(key(item.path))) {
      files.add(item);
    } else {
      skipped++;
    }
  }
  files.sort((a, b) => compareNatural(a.path, b.path));
  return skipped;
}
