import 'package:flutter/material.dart';

sealed class Rule {
  const Rule();

  String apply(String filename);

  void reset() {}

  IconData get icon;
  String get label;
  Map<String, dynamic> toJson();

  ({String name, String ext}) _splitNameAndExt(
    String filename, {
    bool skipExtension = true,
  }) {
    final extIndex = filename.lastIndexOf('.');
    final name = skipExtension && extIndex > 0
        ? filename.substring(0, extIndex)
        : filename;
    final ext = skipExtension && extIndex > 0
        ? filename.substring(extIndex)
        : '';
    return (name: name, ext: ext);
  }

  static Rule fromJson(Map<String, dynamic> json) {
    return switch (json[r'$type'] as String) {
      'findReplace' => FindReplaceRule.fromJson(json),
      'insert' => InsertRule.fromJson(json),
      'delete' => DeleteRule.fromJson(json),
      'cleanUp' => CleanUpRule.fromJson(json),
      'changeCase' => ChangeCaseRule.fromJson(json),
      'regex' => RegexRule.fromJson(json),
      'serialize' => SerializeRule.fromJson(json),
      _ => throw FormatException('Unknown rule type: ${json[r'$type']}'),
    };
  }
}

enum Occurrence { all, first, last }

enum InsertPosition { prefix, suffix, position }

enum DeleteFrom { position, delimiter }

enum ChangeCase {
  capitalizeWords,
  lowerCase,
  upperCase,
  invertCase,
  firstLetter,
}

enum DeleteUntil { count, delimiter, tillEnd }

class FindReplaceRule extends Rule {
  final String find;
  final String replace;
  final Occurrence occurrence;
  final bool caseSensitive;
  final bool wholeWords;
  final bool skipExtension;

  const FindReplaceRule({
    this.find = '',
    this.replace = '',
    this.occurrence = Occurrence.all,
    this.caseSensitive = false,
    this.wholeWords = false,
    this.skipExtension = true,
  });

  @override
  IconData get icon => Icons.find_replace;

  @override
  String get label => "Find & Replace";

  @override
  String apply(String filename) {
    if (find.isEmpty) return filename;

    final (:name, :ext) = _splitNameAndExt(
      filename,
      skipExtension: skipExtension,
    );

    if (wholeWords) {
      final pattern = RegExp(
        r'\b' + RegExp.escape(find) + r'\b',
        caseSensitive: caseSensitive,
      );
      return _applyOccurrence(name, pattern) + ext;
    }

    final pattern = RegExp(RegExp.escape(find), caseSensitive: caseSensitive);
    return _applyOccurrence(name, pattern) + ext;
  }

  String _applyOccurrence(String input, RegExp pattern) {
    switch (occurrence) {
      case Occurrence.first:
        return input.replaceFirst(pattern, replace);
      case Occurrence.last:
        final matches = pattern.allMatches(input).toList();
        if (matches.isEmpty) return input;
        final last = matches.last;
        return input.substring(0, last.start) +
            replace +
            input.substring(last.end);
      case Occurrence.all:
        return input.replaceAll(pattern, replace);
    }
  }

  @override
  Map<String, dynamic> toJson() => {
    r'$type': 'findReplace',
    'find': find,
    'replace': replace,
    'occurrence': occurrence.name,
    'caseSensitive': caseSensitive,
    'wholeWords': wholeWords,
    'skipExtension': skipExtension,
  };

  factory FindReplaceRule.fromJson(Map<String, dynamic> json) =>
      FindReplaceRule(
        find: json['find'] as String? ?? '',
        replace: json['replace'] as String? ?? '',
        occurrence: Occurrence.values.byName(
          json['occurrence'] as String? ?? 'all',
        ),
        caseSensitive: json['caseSensitive'] as bool? ?? false,
        wholeWords: json['wholeWords'] as bool? ?? false,
        skipExtension: json['skipExtension'] as bool? ?? true,
      );
}

class InsertRule extends Rule {
  final String insertText;
  final InsertPosition position;
  final int positionIndex;
  final bool rightToLeft;
  final bool skipExtension;

  const InsertRule({
    this.insertText = '',
    this.position = InsertPosition.prefix,
    this.positionIndex = 1,
    this.rightToLeft = false,
    this.skipExtension = true,
  });

  @override
  IconData get icon => Icons.text_increase;

  @override
  String get label => "Insert";

  @override
  String apply(String filename) {
    if (insertText.isEmpty) return filename;

    final (:name, :ext) = _splitNameAndExt(
      filename,
      skipExtension: skipExtension,
    );

    switch (position) {
      case InsertPosition.prefix:
        return insertText + name + ext;
      case InsertPosition.suffix:
        return name + insertText + ext;
      case InsertPosition.position:
        var index = positionIndex - 1;
        if (rightToLeft) {
          index = name.length - index;
        }
        index = index.clamp(0, name.length);
        return name.substring(0, index) +
            insertText +
            name.substring(index) +
            ext;
    }
  }

  @override
  Map<String, dynamic> toJson() => {
    r'$type': 'insert',
    'insertText': insertText,
    'position': position.name,
    'positionIndex': positionIndex,
    'rightToLeft': rightToLeft,
    'skipExtension': skipExtension,
  };

  factory InsertRule.fromJson(Map<String, dynamic> json) => InsertRule(
    insertText: json['insertText'] as String? ?? '',
    position: InsertPosition.values.byName(
      json['position'] as String? ?? 'prefix',
    ),
    positionIndex: json['positionIndex'] as int? ?? 1,
    rightToLeft: json['rightToLeft'] as bool? ?? false,
    skipExtension: json['skipExtension'] as bool? ?? true,
  );
}

class DeleteRule extends Rule {
  final DeleteFrom from;
  final int fromPosition;
  final String fromDelimiter;
  final DeleteUntil until;
  final int untilCount;
  final String untilDelimiter;
  final bool skipExtension;
  final bool rightToLeft;
  final bool keepDelimiters;

  const DeleteRule({
    this.from = DeleteFrom.position,
    this.fromPosition = 1,
    this.fromDelimiter = '',
    this.until = DeleteUntil.tillEnd,
    this.untilCount = 1,
    this.untilDelimiter = '',
    this.skipExtension = true,
    this.rightToLeft = false,
    this.keepDelimiters = false,
  });

  @override
  IconData get icon => Icons.backspace;

  @override
  String get label => "Delete";

  @override
  String apply(String filename) {
    final (:name, :ext) = _splitNameAndExt(
      filename,
      skipExtension: skipExtension,
    );

    var work = name;
    if (rightToLeft) {
      work = work.split('').reversed.join();
    }

    int fromIndex = _resolveFromIndex(work);
    int untilIndex = _resolveUntilIndex(work, fromIndex);

    if (fromIndex > untilIndex) {
      final temp = fromIndex;
      fromIndex = untilIndex;
      untilIndex = temp;
    }

    fromIndex = fromIndex.clamp(0, work.length);
    untilIndex = untilIndex.clamp(0, work.length);

    var result = work.substring(0, fromIndex) + work.substring(untilIndex);

    if (rightToLeft) {
      result = result.split('').reversed.join();
    }

    return result + ext;
  }

  int _resolveFromIndex(String work) {
    switch (from) {
      case DeleteFrom.position:
        return (fromPosition - 1).clamp(0, work.length);
      case DeleteFrom.delimiter:
        if (fromDelimiter.isEmpty) return 0;
        final index = work.indexOf(fromDelimiter);
        return index < 0 ? 0 : index;
    }
  }

  int _resolveUntilIndex(String work, int fromIndex) {
    switch (until) {
      case DeleteUntil.count:
        return (fromIndex + untilCount).clamp(0, work.length);
      case DeleteUntil.delimiter:
        if (untilDelimiter.isEmpty) return work.length;
        final startSearch = fromIndex + 1;
        if (startSearch >= work.length) return work.length;
        final index = work.indexOf(untilDelimiter, startSearch);
        if (index < 0) return work.length;
        return keepDelimiters ? index : index + untilDelimiter.length;
      case DeleteUntil.tillEnd:
        return work.length;
    }
  }

  @override
  Map<String, dynamic> toJson() => {
    r'$type': 'delete',
    'from': from.name,
    'fromPosition': fromPosition,
    'fromDelimiter': fromDelimiter,
    'until': until.name,
    'untilCount': untilCount,
    'untilDelimiter': untilDelimiter,
    'skipExtension': skipExtension,
    'rightToLeft': rightToLeft,
    'keepDelimiters': keepDelimiters,
  };

  factory DeleteRule.fromJson(Map<String, dynamic> json) => DeleteRule(
    from: DeleteFrom.values.byName(json['from'] as String? ?? 'position'),
    fromPosition: json['fromPosition'] as int? ?? 1,
    fromDelimiter: json['fromDelimiter'] as String? ?? '',
    until: DeleteUntil.values.byName(json['until'] as String? ?? 'tillEnd'),
    untilCount: json['untilCount'] as int? ?? 1,
    untilDelimiter: json['untilDelimiter'] as String? ?? '',
    skipExtension: json['skipExtension'] as bool? ?? true,
    rightToLeft: json['rightToLeft'] as bool? ?? false,
    keepDelimiters: json['keepDelimiters'] as bool? ?? false,
  );
}

class CleanUpRule extends Rule {
  final bool stripParentheses;
  final bool stripSquareBrackets;
  final bool stripCurlyBrackets;
  final bool replaceFullStop;
  final bool replaceComma;
  final bool replaceUnderscore;
  final bool replacePlus;
  final bool replaceMinus;
  final bool replacePipe;
  final bool trimSpaces;
  final bool standardizeWhitespace;
  final bool skipExtension;

  const CleanUpRule({
    this.stripParentheses = false,
    this.stripSquareBrackets = false,
    this.stripCurlyBrackets = false,
    this.replaceFullStop = false,
    this.replaceComma = false,
    this.replaceUnderscore = false,
    this.replacePlus = false,
    this.replaceMinus = false,
    this.replacePipe = false,
    this.trimSpaces = true,
    this.standardizeWhitespace = false,
    this.skipExtension = true,
  });

  @override
  IconData get icon => Icons.cleaning_services;

  @override
  String get label => "Clean Up";

  @override
  String apply(String filename) {
    final (:name, :ext) = _splitNameAndExt(
      filename,
      skipExtension: skipExtension,
    );

    var result = name;

    if (stripParentheses) {
      result = result.replaceAll(RegExp(r'\([^)]*\)'), '');
    }
    if (stripSquareBrackets) {
      result = result.replaceAll(RegExp(r'\[[^\]]*\]'), '');
    }
    if (stripCurlyBrackets) {
      result = result.replaceAll(RegExp(r'\{[^}]*\}'), '');
    }

    if (replaceFullStop) result = result.replaceAll('.', ' ');
    if (replaceComma) result = result.replaceAll(',', ' ');
    if (replaceUnderscore) result = result.replaceAll('_', ' ');
    if (replacePlus) result = result.replaceAll('+', ' ');
    if (replaceMinus) result = result.replaceAll('-', ' ');
    if (replacePipe) result = result.replaceAll('|', ' ');

    if (standardizeWhitespace) {
      result = result.replaceAll(RegExp(r'\s+'), ' ');
    }
    if (trimSpaces) {
      result = result.trim();
    }

    return result + ext;
  }

  @override
  Map<String, dynamic> toJson() => {
    r'$type': 'cleanUp',
    'stripParentheses': stripParentheses,
    'stripSquareBrackets': stripSquareBrackets,
    'stripCurlyBrackets': stripCurlyBrackets,
    'replaceFullStop': replaceFullStop,
    'replaceComma': replaceComma,
    'replaceUnderscore': replaceUnderscore,
    'replacePlus': replacePlus,
    'replaceMinus': replaceMinus,
    'replacePipe': replacePipe,
    'trimSpaces': trimSpaces,
    'standardizeWhitespace': standardizeWhitespace,
    'skipExtension': skipExtension,
  };

  factory CleanUpRule.fromJson(Map<String, dynamic> json) => CleanUpRule(
    stripParentheses: json['stripParentheses'] as bool? ?? false,
    stripSquareBrackets: json['stripSquareBrackets'] as bool? ?? false,
    stripCurlyBrackets: json['stripCurlyBrackets'] as bool? ?? false,
    replaceFullStop: json['replaceFullStop'] as bool? ?? false,
    replaceComma: json['replaceComma'] as bool? ?? false,
    replaceUnderscore: json['replaceUnderscore'] as bool? ?? false,
    replacePlus: json['replacePlus'] as bool? ?? false,
    replaceMinus: json['replaceMinus'] as bool? ?? false,
    replacePipe: json['replacePipe'] as bool? ?? false,
    trimSpaces: json['trimSpaces'] as bool? ?? true,
    standardizeWhitespace: json['standardizeWhitespace'] as bool? ?? false,
    skipExtension: json['skipExtension'] as bool? ?? true,
  );
}

class ChangeCaseRule extends Rule {
  final ChangeCase changeCase;

  const ChangeCaseRule({this.changeCase = ChangeCase.capitalizeWords});

  @override
  IconData get icon => Icons.text_format;

  @override
  String get label => "Change Case";

  @override
  String apply(String filename) {
    final (:name, :ext) = _splitNameAndExt(filename);

    switch (changeCase) {
      case ChangeCase.capitalizeWords:
        return name
                .split(' ')
                .map((w) {
                  if (w.isEmpty) return w;
                  return w[0].toUpperCase() + w.substring(1).toLowerCase();
                })
                .join(' ') +
            ext;
      case ChangeCase.lowerCase:
        return name.toLowerCase() + ext;
      case ChangeCase.upperCase:
        return name.toUpperCase() + ext;
      case ChangeCase.invertCase:
        return name
                .split('')
                .map((c) {
                  final lower = c.toLowerCase();
                  final upper = c.toUpperCase();
                  if (c == lower) return upper;
                  if (c == upper) return lower;
                  return c;
                })
                .join('') +
            ext;
      case ChangeCase.firstLetter:
        if (name.isEmpty) return filename;
        return name[0].toUpperCase() + name.substring(1) + ext;
    }
  }

  @override
  Map<String, dynamic> toJson() => {
    r'$type': 'changeCase',
    'changeCase': changeCase.name,
  };

  factory ChangeCaseRule.fromJson(Map<String, dynamic> json) => ChangeCaseRule(
    changeCase: ChangeCase.values.byName(
      json['changeCase'] as String? ?? 'capitalizeWords',
    ),
  );
}

class RegexRule extends Rule {
  final String expression;
  final String replace;
  final bool replaceAll;
  final bool caseSensitive;
  final bool skipExtension;

  const RegexRule({
    this.expression = '',
    this.replace = '',
    this.replaceAll = false,
    this.caseSensitive = true,
    this.skipExtension = true,
  });

  bool get isExpressionValid {
    if (expression.isEmpty) return true;
    try {
      RegExp(expression, caseSensitive: caseSensitive);
      return true;
    } on FormatException {
      return false;
    }
  }

  @override
  IconData get icon => Icons.manage_search;

  @override
  String get label => "Regex";

  @override
  String apply(String filename) {
    if (expression.isEmpty) return filename;

    final (:name, :ext) = _splitNameAndExt(
      filename,
      skipExtension: skipExtension,
    );

    final pattern = RegExp(expression, caseSensitive: caseSensitive);

    if (replaceAll) {
      return name.replaceAll(pattern, replace) + ext;
    }
    return name.replaceFirst(pattern, replace) + ext;
  }

  @override
  Map<String, dynamic> toJson() => {
    r'$type': 'regex',
    'expression': expression,
    'replace': replace,
    'replaceAll': replaceAll,
    'caseSensitive': caseSensitive,
    'skipExtension': skipExtension,
  };

  factory RegexRule.fromJson(Map<String, dynamic> json) => RegexRule(
    expression: json['expression'] as String? ?? '',
    replace: json['replace'] as String? ?? '',
    replaceAll: json['replaceAll'] as bool? ?? false,
    caseSensitive: json['caseSensitive'] as bool? ?? true,
    skipExtension: json['skipExtension'] as bool? ?? true,
  );
}

class SerializeRule extends Rule {
  final int indexStart;
  final int step;
  final int padWithZeros;
  final bool skipExtension;
  final InsertPosition insertWhere;
  final int positionIndex;
  int? _current;

  SerializeRule({
    this.indexStart = 1,
    this.step = 1,
    this.padWithZeros = 0,
    this.skipExtension = true,
    this.insertWhere = InsertPosition.prefix,
    this.positionIndex = 1,
  });

  @override
  void reset() {
    _current = null;
  }

  String _nextValue() {
    _current = (_current ?? indexStart - step) + step;
    return _current!.toString().padLeft(padWithZeros, '0');
  }

  @override
  IconData get icon => Icons.format_list_numbered;

  @override
  String get label => "Serialize";

  @override
  String apply(String filename) {
    final (:name, :ext) = _splitNameAndExt(
      filename,
      skipExtension: skipExtension,
    );
    final serial = _nextValue();

    switch (insertWhere) {
      case InsertPosition.prefix:
        return serial + name + ext;
      case InsertPosition.suffix:
        return name + serial + ext;
      case InsertPosition.position:
        final index = (positionIndex - 1).clamp(0, name.length);
        return name.substring(0, index) + serial + name.substring(index) + ext;
    }
  }

  @override
  Map<String, dynamic> toJson() => {
    r'$type': 'serialize',
    'indexStart': indexStart,
    'step': step,
    'padWithZeros': padWithZeros,
    'skipExtension': skipExtension,
    'insertWhere': insertWhere.name,
    'positionIndex': positionIndex,
  };

  factory SerializeRule.fromJson(Map<String, dynamic> json) => SerializeRule(
    indexStart: json['indexStart'] as int? ?? 1,
    step: json['step'] as int? ?? 1,
    padWithZeros: json['padWithZeros'] as int? ?? 0,
    skipExtension: json['skipExtension'] as bool? ?? true,
    insertWhere: InsertPosition.values.byName(
      json['insertWhere'] as String? ?? 'prefix',
    ),
    positionIndex: json['positionIndex'] as int? ?? 1,
  );
}
