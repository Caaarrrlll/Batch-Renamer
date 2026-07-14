import 'package:bulk_renamer/ui/replacement_rules/find_replace_rule.dart';
import 'package:bulk_renamer/ui/replacement_rules/insert_rule.dart';
import 'package:flutter/material.dart';

enum RuleType {
  findReplace,
  insert,
  removeText,
  changeCase,
  regex,
  sequentialNumber,
  date,
}

extension RuleTypeLabel on RuleType {
  String get label => switch (this) {
        RuleType.findReplace => "Find & Replace",
        RuleType.insert => "Insert",
        RuleType.removeText => "Remove Text",
        RuleType.changeCase => "Change Case",
        RuleType.regex => "Regular Expression",
        RuleType.sequentialNumber => "Sequential Numbering",
        RuleType.date => "Insert Date",
      };

  IconData get icon => switch (this) {
        RuleType.findReplace => Icons.find_replace,
        RuleType.insert => Icons.text_increase,
        RuleType.removeText => Icons.backspace,
        RuleType.changeCase => Icons.text_fields,
        RuleType.regex => Icons.code,
        RuleType.sequentialNumber => Icons.pin,
        RuleType.date => Icons.calendar_today,
      };

  bool get hasConfiguration =>
      this == RuleType.findReplace || this == RuleType.insert;
}

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
  });

  String apply(String filename) {
    switch (type) {
      case RuleType.findReplace:
        return _applyFindReplace(filename);
      case RuleType.insert:
        return _applyInsert(filename);
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
    );
  }
}
