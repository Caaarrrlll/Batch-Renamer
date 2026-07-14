import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum InsertPosition { prefix, suffix, position }

class InsertRule extends StatefulWidget {
  final String initialInsert;
  final InsertPosition initialPosition;
  final int initialPositionIndex;
  final bool initialRightToLeft;
  final bool initialSkipExtension;

  const InsertRule({
    super.key,
    this.initialInsert = '',
    this.initialPosition = InsertPosition.prefix,
    this.initialPositionIndex = 1,
    this.initialRightToLeft = false,
    this.initialSkipExtension = true,
  });

  @override
  State<InsertRule> createState() => InsertRuleState();
}

class InsertRuleState extends State<InsertRule> {
  late final TextEditingController _insertController;
  late final TextEditingController _positionController;
  late InsertPosition _position;
  late bool _rightToLeft;
  late bool _skipExtension;

  @override
  void initState() {
    super.initState();
    _insertController = TextEditingController(text: widget.initialInsert);
    _positionController =
        TextEditingController(text: widget.initialPositionIndex.toString());
    _position = widget.initialPosition;
    _rightToLeft = widget.initialRightToLeft;
    _skipExtension = widget.initialSkipExtension;
  }

  @override
  void dispose() {
    _insertController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  String get insert => _insertController.text;
  InsertPosition get position => _position;
  int get positionIndex => int.tryParse(_positionController.text) ?? 1;
  bool get rightToLeft => _rightToLeft;
  bool get skipExtension => _skipExtension;

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
          onChanged: (v) => setState(() => _position = v!),
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
                  const Radio<InsertPosition>(value: InsertPosition.position),
                  const Text("Position"),
                ],
              ),
            ],
          ),
        ),
        if (_position == InsertPosition.position) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _positionController,
                    keyboardType: TextInputType.number,
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
                  onChanged: (v) => setState(() => _rightToLeft = v!),
                ),
                const Text("Right to left"),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
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
