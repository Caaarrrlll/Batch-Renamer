import 'package:bulk_renamer/models/rule.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InsertRuleWidget extends StatefulWidget {
  final InsertRule? initial;
  final ValueChanged<InsertRule> onChanged;

  const InsertRuleWidget({
    super.key,
    this.initial,
    required this.onChanged,
  });

  @override
  State<InsertRuleWidget> createState() => _InsertRuleWidgetState();
}

class _InsertRuleWidgetState extends State<InsertRuleWidget> {
  late final TextEditingController _insertController;
  late final TextEditingController _positionController;
  late InsertPosition _position;
  late bool _rightToLeft;
  late bool _skipExtension;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _insertController = TextEditingController(text: init?.insertText ?? '');
    _positionController = TextEditingController(
        text: (init?.positionIndex ?? 1).toString());
    _position = init?.position ?? InsertPosition.prefix;
    _rightToLeft = init?.rightToLeft ?? false;
    _skipExtension = init?.skipExtension ?? true;

    _insertController.addListener(_emitChange);
    _positionController.addListener(_emitChange);
  }

  @override
  void dispose() {
    _insertController.removeListener(_emitChange);
    _positionController.removeListener(_emitChange);
    _insertController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  void _emitChange() {
    widget.onChanged(_buildRule());
  }

  InsertRule _buildRule() {
    return InsertRule(
      insertText: _insertController.text,
      position: _position,
      positionIndex: int.tryParse(_positionController.text) ?? 1,
      rightToLeft: _rightToLeft,
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
          controller: _insertController,
          decoration: const InputDecoration(
            labelText: "Insert",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Text("Position", style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        RadioGroup<InsertPosition>(
          groupValue: _position,
          onChanged: (v) => _update(() => _position = v!),
          child: Column(
            children: [
              Row(
                children: [
                  const Radio<InsertPosition>(value: InsertPosition.prefix),
                  const Text("Prefix"),
                ],
              ),
              Row(
                children: [
                  const Radio<InsertPosition>(value: InsertPosition.suffix),
                  const Text("Suffix"),
                ],
              ),
              Row(
                children: [
                  const SizedBox(
                    width: 120,
                    child: Row(
                      children: [
                        Radio<InsertPosition>(value: InsertPosition.position),
                        Text("Position"),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 200,
                    child: TextField(
                      controller: _positionController,
                      keyboardType: TextInputType.number,
                      enabled: _position == InsertPosition.position,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: "Index",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        final num = int.tryParse(value);
                        if (num != null && num < 1) {
                          _positionController.text = '1';
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Checkbox(
                    value: _rightToLeft,
                    onChanged: _position == InsertPosition.position
                        ? (v) => _update(() => _rightToLeft = v!)
                        : null,
                  ),
                  const Text("Right to left"),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
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
