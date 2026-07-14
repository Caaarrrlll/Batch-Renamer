import 'package:bulk_renamer/models/rule.dart';
import 'package:flutter/material.dart';

class FindReplaceRuleWidget extends StatefulWidget {
  final FindReplaceRule? initial;
  final ValueChanged<FindReplaceRule> onChanged;

  const FindReplaceRuleWidget({
    super.key,
    this.initial,
    required this.onChanged,
  });

  @override
  State<FindReplaceRuleWidget> createState() => _FindReplaceRuleWidgetState();
}

class _FindReplaceRuleWidgetState extends State<FindReplaceRuleWidget> {
  late final TextEditingController _findController;
  late final TextEditingController _replaceController;
  late Occurrence _occurrence;
  late bool _caseSensitive;
  late bool _wholeWords;
  late bool _skipExtension;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _findController = TextEditingController(text: init?.find ?? '');
    _replaceController = TextEditingController(text: init?.replace ?? '');
    _occurrence = init?.occurrence ?? Occurrence.all;
    _caseSensitive = init?.caseSensitive ?? false;
    _wholeWords = init?.wholeWords ?? false;
    _skipExtension = init?.skipExtension ?? true;

    _findController.addListener(_emitChange);
    _replaceController.addListener(_emitChange);
  }

  @override
  void dispose() {
    _findController.removeListener(_emitChange);
    _replaceController.removeListener(_emitChange);
    _findController.dispose();
    _replaceController.dispose();
    super.dispose();
  }

  void _emitChange() {
    widget.onChanged(_buildRule());
  }

  FindReplaceRule _buildRule() {
    return FindReplaceRule(
      find: _findController.text,
      replace: _replaceController.text,
      occurrence: _occurrence,
      caseSensitive: _caseSensitive,
      wholeWords: _wholeWords,
      skipExtension: _skipExtension,
    );
  }

  void _update(void Function() modify) {
    setState(modify);
    widget.onChanged(_buildRule());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _findController,
          decoration: const InputDecoration(
            labelText: "Find",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _replaceController,
          decoration: const InputDecoration(
            labelText: "Replace",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Text("Occurrences", style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        RadioGroup<Occurrence>(
          groupValue: _occurrence,
          onChanged: (v) => _update(() => _occurrence = v!),
          child: Wrap(
            spacing: 16,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Radio<Occurrence>(value: Occurrence.all),
                  const Text("All"),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Radio<Occurrence>(value: Occurrence.first),
                  const Text("First"),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Radio<Occurrence>(value: Occurrence.last),
                  const Text("Last"),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: _caseSensitive,
          onChanged: (v) => _update(() => _caseSensitive = v!),
          title: const Text("Case sensitive"),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          value: _wholeWords,
          onChanged: (v) => _update(() => _wholeWords = v!),
          title: const Text("Match whole words only"),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          value: _skipExtension,
          onChanged: (v) => _update(() => _skipExtension = v!),
          title: const Text("Skip file extension"),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }
}
