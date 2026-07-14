import 'package:flutter/material.dart';

enum Occurrence { all, first, last }

class FindReplaceRule extends StatefulWidget {
  final String initialFind;
  final String initialReplace;
  final Occurrence initialOccurrence;
  final bool initialCaseSensitive;
  final bool initialWholeWords;
  final bool initialSkipExtension;

  const FindReplaceRule({
    super.key,
    this.initialFind = '',
    this.initialReplace = '',
    this.initialOccurrence = Occurrence.all,
    this.initialCaseSensitive = false,
    this.initialWholeWords = false,
    this.initialSkipExtension = true,
  });

  @override
  State<FindReplaceRule> createState() => FindReplaceRuleState();
}

class FindReplaceRuleState extends State<FindReplaceRule> {
  late final TextEditingController _findController;
  late final TextEditingController _replaceController;
  late Occurrence _occurrence;
  late bool _caseSensitive;
  late bool _wholeWords;
  late bool _skipExtension;

  @override
  void initState() {
    super.initState();
    _findController = TextEditingController(text: widget.initialFind);
    _replaceController = TextEditingController(text: widget.initialReplace);
    _occurrence = widget.initialOccurrence;
    _caseSensitive = widget.initialCaseSensitive;
    _wholeWords = widget.initialWholeWords;
    _skipExtension = widget.initialSkipExtension;
  }

  @override
  void dispose() {
    _findController.dispose();
    _replaceController.dispose();
    super.dispose();
  }

  String get find => _findController.text;
  String get replace => _replaceController.text;
  Occurrence get occurrence => _occurrence;
  bool get caseSensitive => _caseSensitive;
  bool get wholeWords => _wholeWords;
  bool get skipExtension => _skipExtension;

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
          onChanged: (v) => setState(() => _occurrence = v!),
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
          onChanged: (v) => setState(() => _caseSensitive = v!),
          title: const Text("Case sensitive"),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          value: _wholeWords,
          onChanged: (v) => setState(() => _wholeWords = v!),
          title: const Text("Match whole words only"),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          value: _skipExtension,
          onChanged: (v) => setState(() => _skipExtension = v!),
          title: const Text("Skip file extension"),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }
}
