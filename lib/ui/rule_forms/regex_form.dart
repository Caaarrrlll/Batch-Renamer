import 'package:bulk_renamer/models/rule.dart';
import 'package:flutter/material.dart';

class RegexRuleWidget extends StatefulWidget {
  final RegexRule? initial;
  final ValueChanged<RegexRule> onChanged;

  const RegexRuleWidget({super.key, this.initial, required this.onChanged});

  @override
  State<RegexRuleWidget> createState() => _RegexRuleWidgetState();
}

class _RegexRuleWidgetState extends State<RegexRuleWidget> {
  late final TextEditingController _expressionController;
  late final TextEditingController _replaceController;
  late bool _replaceAll;
  late bool _caseSensitive;
  late bool _skipExtension;

  String? _error;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _expressionController = TextEditingController(text: init?.expression ?? '');
    _replaceController = TextEditingController(text: init?.replace ?? '');
    _replaceAll = init?.replaceAll ?? false;
    _caseSensitive = init?.caseSensitive ?? true;
    _skipExtension = init?.skipExtension ?? true;

    _expressionController.addListener(_emitChange);
    _replaceController.addListener(_emitChange);

    if (init != null) _validate();
  }

  @override
  void dispose() {
    _expressionController.removeListener(_emitChange);
    _replaceController.removeListener(_emitChange);
    _expressionController.dispose();
    _replaceController.dispose();
    super.dispose();
  }

  void _validate() {
    final text = _expressionController.text;
    if (text.isEmpty) {
      _error = null;
      return;
    }
    try {
      RegExp(text, caseSensitive: _caseSensitive);
      _error = null;
    } on FormatException catch (e) {
      _error = e.message;
    }
  }

  void _emitChange() {
    _validate();
    setState(() {});
    widget.onChanged(_buildRule());
  }

  RegexRule _buildRule() {
    return RegexRule(
      expression: _expressionController.text,
      replace: _replaceController.text,
      replaceAll: _replaceAll,
      caseSensitive: _caseSensitive,
      skipExtension: _skipExtension,
    );
  }

  void _update(void Function() modify) {
    setState(modify);
    _validate();
    widget.onChanged(_buildRule());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        TextField(
          controller: _expressionController,
          decoration: InputDecoration(
            labelText: "Expression",
            border: const OutlineInputBorder(),
            isDense: true,
            errorText: _error,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _replaceController,
          decoration: const InputDecoration(
            labelText: "Replace",
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        Text("Settings", style: Theme.of(context).textTheme.titleMedium),
        CheckboxListTile(
          value: _replaceAll,
          onChanged: (v) => _update(() => _replaceAll = v!),
          title: const Text("Replace all"),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          visualDensity: VisualDensity.compact,
        ),
        CheckboxListTile(
          value: _caseSensitive,
          onChanged: (v) => _update(() => _caseSensitive = v!),
          title: const Text("Case sensitive"),
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
