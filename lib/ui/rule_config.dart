import 'package:bulk_renamer/ui/replacement_rules/find_replace_rule.dart';
import 'package:flutter/material.dart';

enum RuleType {
  findReplace,
  addPrefix,
  addSuffix,
  removeText,
  changeCase,
  regex,
  sequentialNumber,
  date,
}

extension RuleTypeLabel on RuleType {
  String get label => switch (this) {
        RuleType.findReplace => "Find & Replace",
        RuleType.addPrefix => "Add Prefix",
        RuleType.addSuffix => "Add Suffix",
        RuleType.removeText => "Remove Text",
        RuleType.changeCase => "Change Case",
        RuleType.regex => "Regular Expression",
        RuleType.sequentialNumber => "Sequential Numbering",
        RuleType.date => "Insert Date",
      };

  IconData get icon => switch (this) {
        RuleType.findReplace => Icons.find_replace,
        RuleType.addPrefix => Icons.arrow_back,
        RuleType.addSuffix => Icons.arrow_forward,
        RuleType.removeText => Icons.backspace,
        RuleType.changeCase => Icons.text_fields,
        RuleType.regex => Icons.code,
        RuleType.sequentialNumber => Icons.pin,
        RuleType.date => Icons.calendar_today,
      };
}

class RuleConfig {
  final RuleType type;
  final String find;
  final String replace;
  final Occurrence occurrence;
  final bool caseSensitive;
  final bool wholeWords;
  final bool skipExtension;

  const RuleConfig({
    required this.type,
    this.find = '',
    this.replace = '',
    this.occurrence = Occurrence.all,
    this.caseSensitive = false,
    this.wholeWords = false,
    this.skipExtension = true,
  });

  String apply(String filename) {
    if (type != RuleType.findReplace) return filename;
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

  RuleConfig copyWith({
    String? find,
    String? replace,
    Occurrence? occurrence,
    bool? caseSensitive,
    bool? wholeWords,
    bool? skipExtension,
  }) {
    return RuleConfig(
      type: type,
      find: find ?? this.find,
      replace: replace ?? this.replace,
      occurrence: occurrence ?? this.occurrence,
      caseSensitive: caseSensitive ?? this.caseSensitive,
      wholeWords: wholeWords ?? this.wholeWords,
      skipExtension: skipExtension ?? this.skipExtension,
    );
  }
}
