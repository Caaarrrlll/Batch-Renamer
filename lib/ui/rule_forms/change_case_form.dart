import 'package:bulk_renamer/models/rule.dart';
import 'package:flutter/material.dart';

class ChangeCaseRuleWidget extends StatefulWidget {
  final ChangeCaseRule? initial;
  final ValueChanged<ChangeCaseRule> onChanged;

  const ChangeCaseRuleWidget({
    super.key,
    this.initial,
    required this.onChanged,
  });

  @override
  State<ChangeCaseRuleWidget> createState() => _ChangeCaseRuleWidgetState();
}

class _ChangeCaseRuleWidgetState extends State<ChangeCaseRuleWidget> {
  late ChangeCase _changeCase;

  @override
  void initState() {
    super.initState();
    _changeCase = widget.initial?.changeCase ?? ChangeCase.capitalizeWords;
  }

  void _update(void Function() modify) {
    setState(modify);
    widget.onChanged(ChangeCaseRule(changeCase: _changeCase));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Case", style: Theme.of(context).textTheme.titleMedium),
        RadioGroup<ChangeCase>(
          groupValue: _changeCase,
          onChanged: (v) => _update(() => _changeCase = v!),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ChangeCase.values
                .map(
                  (c) => RadioListTile<ChangeCase>(
                    value: c,
                    title: Text(_labelForCase(c)),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  String _labelForCase(ChangeCase c) => switch (c) {
    ChangeCase.capitalizeWords => "Capitalize Every Word",
    ChangeCase.lowerCase => "All Lower Case",
    ChangeCase.upperCase => "All Upper Case",
    ChangeCase.invertCase => "Inverted Case",
    ChangeCase.firstLetter => "First Letter Capital",
  };
}
