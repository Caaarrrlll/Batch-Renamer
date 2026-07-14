import 'package:flutter/material.dart';

sealed class Rule {
  const Rule();

  String apply(String filename);

  IconData get icon;
  String get label;
}

enum Occurrence { all, first, last }

enum InsertPosition { prefix, suffix, position }

enum DeleteFrom { position, delimiter }

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

    final extIndex = filename.lastIndexOf('.');
    final name = skipExtension && extIndex > 0
        ? filename.substring(0, extIndex)
        : filename;
    final ext =
        skipExtension && extIndex > 0 ? filename.substring(extIndex) : '';

    if (wholeWords) {
      final pattern = RegExp(r'\b' + RegExp.escape(find) + r'\b',
          caseSensitive: caseSensitive);
      return _applyOccurrence(name, pattern) + ext;
    }

    final pattern =
        RegExp(RegExp.escape(find), caseSensitive: caseSensitive);
    return _applyOccurrence(name, pattern) + ext;
  }

  String _applyOccurrence(String input, RegExp pattern) {
    if (occurrence == Occurrence.first) {
      return input.replaceFirst(pattern, replace);
    }
    if (occurrence == Occurrence.last) {
      final matches = pattern.allMatches(input).toList();
      if (matches.isEmpty) return input;
      final last = matches.last;
      return input.substring(0, last.start) +
          replace +
          input.substring(last.end);
    }
    return input.replaceAll(pattern, replace);
  }

  FindReplaceRule copyWith({
    String? find,
    String? replace,
    Occurrence? occurrence,
    bool? caseSensitive,
    bool? wholeWords,
    bool? skipExtension,
  }) {
    return FindReplaceRule(
      find: find ?? this.find,
      replace: replace ?? this.replace,
      occurrence: occurrence ?? this.occurrence,
      caseSensitive: caseSensitive ?? this.caseSensitive,
      wholeWords: wholeWords ?? this.wholeWords,
      skipExtension: skipExtension ?? this.skipExtension,
    );
  }
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

    final extIndex = filename.lastIndexOf('.');
    final name = skipExtension && extIndex > 0
        ? filename.substring(0, extIndex)
        : filename;
    final ext =
        skipExtension && extIndex > 0 ? filename.substring(extIndex) : '';

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

  InsertRule copyWith({
    String? insertText,
    InsertPosition? position,
    int? positionIndex,
    bool? rightToLeft,
    bool? skipExtension,
  }) {
    return InsertRule(
      insertText: insertText ?? this.insertText,
      position: position ?? this.position,
      positionIndex: positionIndex ?? this.positionIndex,
      rightToLeft: rightToLeft ?? this.rightToLeft,
      skipExtension: skipExtension ?? this.skipExtension,
    );
  }
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
    final extIndex = filename.lastIndexOf('.');
    final name = skipExtension && extIndex > 0
        ? filename.substring(0, extIndex)
        : filename;
    final ext =
        skipExtension && extIndex > 0 ? filename.substring(extIndex) : '';

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
        return keepDelimiters
            ? index
            : index + untilDelimiter.length;
      case DeleteUntil.tillEnd:
        return work.length;
    }
  }

  DeleteRule copyWith({
    DeleteFrom? from,
    int? fromPosition,
    String? fromDelimiter,
    DeleteUntil? until,
    int? untilCount,
    String? untilDelimiter,
    bool? skipExtension,
    bool? rightToLeft,
    bool? keepDelimiters,
  }) {
    return DeleteRule(
      from: from ?? this.from,
      fromPosition: fromPosition ?? this.fromPosition,
      fromDelimiter: fromDelimiter ?? this.fromDelimiter,
      until: until ?? this.until,
      untilCount: untilCount ?? this.untilCount,
      untilDelimiter: untilDelimiter ?? this.untilDelimiter,
      skipExtension: skipExtension ?? this.skipExtension,
      rightToLeft: rightToLeft ?? this.rightToLeft,
      keepDelimiters: keepDelimiters ?? this.keepDelimiters,
    );
  }
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
    final extIndex = filename.lastIndexOf('.');
    final name = skipExtension && extIndex > 0
        ? filename.substring(0, extIndex)
        : filename;
    final ext =
        skipExtension && extIndex > 0 ? filename.substring(extIndex) : '';

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

  CleanUpRule copyWith({
    bool? stripParentheses,
    bool? stripSquareBrackets,
    bool? stripCurlyBrackets,
    bool? replaceFullStop,
    bool? replaceComma,
    bool? replaceUnderscore,
    bool? replacePlus,
    bool? replaceMinus,
    bool? replacePipe,
    bool? trimSpaces,
    bool? standardizeWhitespace,
    bool? skipExtension,
  }) {
    return CleanUpRule(
      stripParentheses: stripParentheses ?? this.stripParentheses,
      stripSquareBrackets: stripSquareBrackets ?? this.stripSquareBrackets,
      stripCurlyBrackets: stripCurlyBrackets ?? this.stripCurlyBrackets,
      replaceFullStop: replaceFullStop ?? this.replaceFullStop,
      replaceComma: replaceComma ?? this.replaceComma,
      replaceUnderscore: replaceUnderscore ?? this.replaceUnderscore,
      replacePlus: replacePlus ?? this.replacePlus,
      replaceMinus: replaceMinus ?? this.replaceMinus,
      replacePipe: replacePipe ?? this.replacePipe,
      trimSpaces: trimSpaces ?? this.trimSpaces,
      standardizeWhitespace:
          standardizeWhitespace ?? this.standardizeWhitespace,
      skipExtension: skipExtension ?? this.skipExtension,
    );
  }
}
