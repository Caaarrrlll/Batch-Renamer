import 'package:bulk_renamer/models/rule.dart';
import 'package:flutter/material.dart';

class CleanUpRuleWidget extends StatefulWidget {
  final CleanUpRule? initial;
  final ValueChanged<CleanUpRule> onChanged;

  const CleanUpRuleWidget({
    super.key,
    this.initial,
    required this.onChanged,
  });

  @override
  State<CleanUpRuleWidget> createState() => _CleanUpRuleWidgetState();
}

class _CleanUpRuleWidgetState extends State<CleanUpRuleWidget> {
  late bool _stripParentheses;
  late bool _stripSquareBrackets;
  late bool _stripCurlyBrackets;
  late bool _replaceFullStop;
  late bool _replaceComma;
  late bool _replaceUnderscore;
  late bool _replacePlus;
  late bool _replaceMinus;
  late bool _replacePipe;
  late bool _trimSpaces;
  late bool _standardizeWhitespace;
  late bool _skipExtension;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _stripParentheses = init?.stripParentheses ?? false;
    _stripSquareBrackets = init?.stripSquareBrackets ?? false;
    _stripCurlyBrackets = init?.stripCurlyBrackets ?? false;
    _replaceFullStop = init?.replaceFullStop ?? false;
    _replaceComma = init?.replaceComma ?? false;
    _replaceUnderscore = init?.replaceUnderscore ?? false;
    _replacePlus = init?.replacePlus ?? false;
    _replaceMinus = init?.replaceMinus ?? false;
    _replacePipe = init?.replacePipe ?? false;
    _trimSpaces = init?.trimSpaces ?? true;
    _standardizeWhitespace = init?.standardizeWhitespace ?? false;
    _skipExtension = init?.skipExtension ?? true;
  }

  void _update(void Function() modify) {
    setState(modify);
    widget.onChanged(_buildRule());
  }

  CleanUpRule _buildRule() {
    return CleanUpRule(
      stripParentheses: _stripParentheses,
      stripSquareBrackets: _stripSquareBrackets,
      stripCurlyBrackets: _stripCurlyBrackets,
      replaceFullStop: _replaceFullStop,
      replaceComma: _replaceComma,
      replaceUnderscore: _replaceUnderscore,
      replacePlus: _replacePlus,
      replaceMinus: _replaceMinus,
      replacePipe: _replacePipe,
      trimSpaces: _trimSpaces,
      standardizeWhitespace: _standardizeWhitespace,
      skipExtension: _skipExtension,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Strip Bracket Content",
            style: Theme.of(context).textTheme.titleMedium),
        CheckboxListTile(
          value: _stripParentheses,
          onChanged: (v) => _update(() => _stripParentheses = v!),
          title: const Text("Parentheses (...)"),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          visualDensity: VisualDensity.compact,
        ),
        CheckboxListTile(
          value: _stripSquareBrackets,
          onChanged: (v) => _update(() => _stripSquareBrackets = v!),
          title: const Text("Square Brackets [...]"),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          visualDensity: VisualDensity.compact,
        ),
        CheckboxListTile(
          value: _stripCurlyBrackets,
          onChanged: (v) => _update(() => _stripCurlyBrackets = v!),
          title: const Text("Curly Brackets {...}"),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          visualDensity: VisualDensity.compact,
        ),
        Text("Character Replacement",
            style: Theme.of(context).textTheme.titleMedium),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  CheckboxListTile(
                    value: _replaceFullStop,
                    onChanged: (v) => _update(() => _replaceFullStop = v!),
                    title: const Text("Full Stop (.)"),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    visualDensity: VisualDensity.compact,
                  ),
                  CheckboxListTile(
                    value: _replaceComma,
                    onChanged: (v) => _update(() => _replaceComma = v!),
                    title: const Text("Comma (,)"),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    visualDensity: VisualDensity.compact,
                  ),
                  CheckboxListTile(
                    value: _replaceUnderscore,
                    onChanged: (v) => _update(() => _replaceUnderscore = v!),
                    title: const Text("Underscore (_)"),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  CheckboxListTile(
                    value: _replacePlus,
                    onChanged: (v) => _update(() => _replacePlus = v!),
                    title: const Text("Plus (+)"),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    visualDensity: VisualDensity.compact,
                  ),
                  CheckboxListTile(
                    value: _replaceMinus,
                    onChanged: (v) => _update(() => _replaceMinus = v!),
                    title: const Text("Minus (-)"),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    visualDensity: VisualDensity.compact,
                  ),
                  CheckboxListTile(
                    value: _replacePipe,
                    onChanged: (v) => _update(() => _replacePipe = v!),
                    title: const Text("Pipe (|)"),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ],
        ),
        Text("Additional Settings",
            style: Theme.of(context).textTheme.titleMedium),
        CheckboxListTile(
          value: _trimSpaces,
          onChanged: (v) => _update(() => _trimSpaces = v!),
          title: const Text("Trim leading and trailing spaces"),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          visualDensity: VisualDensity.compact,
        ),
        CheckboxListTile(
          value: _standardizeWhitespace,
          onChanged: (v) => _update(() => _standardizeWhitespace = v!),
          title: const Text("Standardize Whitespace"),
          subtitle: const Text("Replace all whitespace with a single space"),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          visualDensity: VisualDensity.compact,
        ),
        CheckboxListTile(
          value: _skipExtension,
          onChanged: (v) => _update(() => _skipExtension = v!),
          title: const Text("Skip file extension"),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
