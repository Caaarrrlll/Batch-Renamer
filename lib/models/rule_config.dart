import 'package:flutter/material.dart';

enum RuleType {
  findReplace,
  insert,
  delete,
  changeCase,
  regex,
  sequentialNumber,
  cleanUp,
}

extension RuleTypeLabel on RuleType {
  String get label => switch (this) {
    RuleType.findReplace => "Find & Replace",
    RuleType.insert => "Insert",
    RuleType.delete => "Delete",
    RuleType.changeCase => "Change Case",
    RuleType.regex => "Regular Expression",
    RuleType.sequentialNumber => "Sequential Numbering",
    RuleType.cleanUp => "Clean Up",
  };

  IconData get icon => switch (this) {
    RuleType.findReplace => Icons.find_replace,
    RuleType.insert => Icons.text_increase,
    RuleType.delete => Icons.backspace,
    RuleType.changeCase => Icons.text_fields,
    RuleType.regex => Icons.code,
    RuleType.sequentialNumber => Icons.pin,
    RuleType.cleanUp => Icons.cleaning_services,
  };

  bool get hasConfiguration =>
      this == RuleType.findReplace ||
      this == RuleType.insert ||
      this == RuleType.delete;

  bool get isAvailable =>
      this == RuleType.findReplace ||
      this == RuleType.insert ||
      this == RuleType.delete ||
      this == RuleType.cleanUp;
}

enum Occurrence { all, first, last }

enum InsertPosition { prefix, suffix, position }

enum DeleteFrom { position, delimiter }

enum DeleteUntil { count, delimiter, tillEnd }

class RuleConfig {
  final RuleType type;
  final String find;
  final String replace;
  final Occurrence occurrence;
  final bool caseSensitive;
  final bool wholeWords;
  final bool skipExtension;
  final String insertText;
  final InsertPosition insertPosition;
  final int insertPositionIndex;
  final bool insertRightToLeft;
  final bool insertSkipExtension;
  final DeleteFrom deleteFrom;
  final int deleteFromPosition;
  final String deleteFromDelimiter;
  final DeleteUntil deleteUntil;
  final int deleteUntilCount;
  final String deleteUntilDelimiter;
  final bool deleteSkipExtension;
  final bool deleteRightToLeft;
  final bool deleteKeepDelimiters;

  const RuleConfig({
    required this.type,
    this.find = '',
    this.replace = '',
    this.occurrence = Occurrence.all,
    this.caseSensitive = false,
    this.wholeWords = false,
    this.skipExtension = true,
    this.insertText = '',
    this.insertPosition = InsertPosition.prefix,
    this.insertPositionIndex = 1,
    this.insertRightToLeft = false,
    this.insertSkipExtension = true,
    this.deleteFrom = DeleteFrom.position,
    this.deleteFromPosition = 1,
    this.deleteFromDelimiter = '',
    this.deleteUntil = DeleteUntil.tillEnd,
    this.deleteUntilCount = 1,
    this.deleteUntilDelimiter = '',
    this.deleteSkipExtension = true,
    this.deleteRightToLeft = false,
    this.deleteKeepDelimiters = false,
  });

  String apply(String filename) {
    switch (type) {
      case RuleType.findReplace:
        return _applyFindReplace(filename);
      case RuleType.insert:
        return _applyInsert(filename);
      case RuleType.delete:
        return _applyDelete(filename);
      default:
        return filename;
    }
  }

  String _applyFindReplace(String filename) {
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

  String _applyInsert(String filename) {
    if (insertText.isEmpty) return filename;

    final extIndex = filename.lastIndexOf('.');
    final name = insertSkipExtension && extIndex > 0
        ? filename.substring(0, extIndex)
        : filename;
    final ext = insertSkipExtension && extIndex > 0
        ? filename.substring(extIndex)
        : '';

    switch (insertPosition) {
      case InsertPosition.prefix:
        return insertText + name + ext;
      case InsertPosition.suffix:
        return name + insertText + ext;
      case InsertPosition.position:
        var index = insertPositionIndex - 1;
        if (insertRightToLeft) {
          index = name.length - index;
        }
        index = index.clamp(0, name.length);
        return name.substring(0, index) +
            insertText +
            name.substring(index) +
            ext;
    }
  }

  String _applyDelete(String filename) {
    final extIndex = filename.lastIndexOf('.');
    final name = deleteSkipExtension && extIndex > 0
        ? filename.substring(0, extIndex)
        : filename;
    final ext = deleteSkipExtension && extIndex > 0
        ? filename.substring(extIndex)
        : '';

    var work = name;
    if (deleteRightToLeft) {
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

    if (deleteRightToLeft) {
      result = result.split('').reversed.join();
    }

    return result + ext;
  }

  int _resolveFromIndex(String work) {
    switch (deleteFrom) {
      case DeleteFrom.position:
        return (deleteFromPosition - 1).clamp(0, work.length);
      case DeleteFrom.delimiter:
        if (deleteFromDelimiter.isEmpty) return 0;
        final index = work.indexOf(deleteFromDelimiter);
        return index < 0 ? 0 : index;
    }
  }

  int _resolveUntilIndex(String work, int fromIndex) {
    switch (deleteUntil) {
      case DeleteUntil.count:
        return (fromIndex + deleteUntilCount).clamp(0, work.length);
      case DeleteUntil.delimiter:
        if (deleteUntilDelimiter.isEmpty) return work.length;
        final startSearch = fromIndex + 1;
        if (startSearch >= work.length) return work.length;
        final index = work.indexOf(deleteUntilDelimiter, startSearch);
        if (index < 0) return work.length;
        return deleteKeepDelimiters
            ? index
            : index + deleteUntilDelimiter.length;
      case DeleteUntil.tillEnd:
        return work.length;
    }
  }

  RuleConfig copyWith({
    String? find,
    String? replace,
    Occurrence? occurrence,
    bool? caseSensitive,
    bool? wholeWords,
    bool? skipExtension,
    String? insertText,
    InsertPosition? insertPosition,
    int? insertPositionIndex,
    bool? insertRightToLeft,
    bool? insertSkipExtension,
    DeleteFrom? deleteFrom,
    int? deleteFromPosition,
    String? deleteFromDelimiter,
    DeleteUntil? deleteUntil,
    int? deleteUntilCount,
    String? deleteUntilDelimiter,
    bool? deleteSkipExtension,
    bool? deleteRightToLeft,
    bool? deleteKeepDelimiters,
  }) {
    return RuleConfig(
      type: type,
      find: find ?? this.find,
      replace: replace ?? this.replace,
      occurrence: occurrence ?? this.occurrence,
      caseSensitive: caseSensitive ?? this.caseSensitive,
      wholeWords: wholeWords ?? this.wholeWords,
      skipExtension: skipExtension ?? this.skipExtension,
      insertText: insertText ?? this.insertText,
      insertPosition: insertPosition ?? this.insertPosition,
      insertPositionIndex: insertPositionIndex ?? this.insertPositionIndex,
      insertRightToLeft: insertRightToLeft ?? this.insertRightToLeft,
      insertSkipExtension: insertSkipExtension ?? this.insertSkipExtension,
      deleteFrom: deleteFrom ?? this.deleteFrom,
      deleteFromPosition: deleteFromPosition ?? this.deleteFromPosition,
      deleteFromDelimiter: deleteFromDelimiter ?? this.deleteFromDelimiter,
      deleteUntil: deleteUntil ?? this.deleteUntil,
      deleteUntilCount: deleteUntilCount ?? this.deleteUntilCount,
      deleteUntilDelimiter: deleteUntilDelimiter ?? this.deleteUntilDelimiter,
      deleteSkipExtension: deleteSkipExtension ?? this.deleteSkipExtension,
      deleteRightToLeft: deleteRightToLeft ?? this.deleteRightToLeft,
      deleteKeepDelimiters: deleteKeepDelimiters ?? this.deleteKeepDelimiters,
    );
  }
}
