import 'package:bulk_renamer/models/rule.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SerializeRuleWidget extends StatefulWidget {
  final SerializeRule? initial;
  final ValueChanged<SerializeRule> onChanged;

  const SerializeRuleWidget({super.key, this.initial, required this.onChanged});

  @override
  State<SerializeRuleWidget> createState() => _SerializeRuleWidgetState();
}

class _SerializeRuleWidgetState extends State<SerializeRuleWidget> {
  late final TextEditingController _indexStartController;
  late final TextEditingController _stepController;
  late final TextEditingController _padController;
  late final TextEditingController _repeatController;
  late final TextEditingController _positionController;
  late InsertPosition _insertWhere;
  late bool _skipExtension;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _indexStartController = TextEditingController(
      text: (init?.indexStart ?? 1).toString(),
    );
    _stepController = TextEditingController(text: (init?.step ?? 1).toString());
    _padController = TextEditingController(
      text: (init?.padWithZeros ?? 0).toString(),
    );
    _repeatController = TextEditingController(
      text: (init?.repeat ?? 1).toString(),
    );
    _positionController = TextEditingController(
      text: (init?.positionIndex ?? 1).toString(),
    );
    _insertWhere = init?.insertWhere ?? InsertPosition.prefix;
    _skipExtension = init?.skipExtension ?? true;

    _indexStartController.addListener(_emitChange);
    _stepController.addListener(_emitChange);
    _padController.addListener(_emitChange);
    _repeatController.addListener(_emitChange);
    _positionController.addListener(_emitChange);
  }

  @override
  void dispose() {
    _indexStartController.removeListener(_emitChange);
    _stepController.removeListener(_emitChange);
    _padController.removeListener(_emitChange);
    _repeatController.removeListener(_emitChange);
    _positionController.removeListener(_emitChange);
    _indexStartController.dispose();
    _stepController.dispose();
    _padController.dispose();
    _repeatController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  void _emitChange() {
    widget.onChanged(_buildRule());
  }

  SerializeRule _buildRule() {
    return SerializeRule(
      indexStart: int.tryParse(_indexStartController.text) ?? 1,
      step: int.tryParse(_stepController.text) ?? 1,
      padWithZeros: int.tryParse(_padController.text) ?? 0,
      repeat: int.tryParse(_repeatController.text) ?? 1,
      skipExtension: _skipExtension,
      insertWhere: _insertWhere,
      positionIndex: int.tryParse(_positionController.text) ?? 1,
    );
  }

  void _update(void Function() modify) {
    setState(modify);
    widget.onChanged(_buildRule());
  }

  void _clampNumber(TextEditingController controller, int min) {
    final value = int.tryParse(controller.text);
    if (value != null && value < min) {
      controller.text = '$min';
    }
  }

  Widget _buildStepperField({
    required TextEditingController controller,
    required String label,
    required int min,
  }) {
    return Expanded(
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => _clampNumber(controller, min),
            ),
          ),
          const SizedBox(width: 4),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 20,
                width: 20,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  onPressed: () {
                    final current = int.tryParse(controller.text) ?? min;
                    controller.text = '${current + 1}';
                  },
                  icon: const Icon(Icons.arrow_drop_up),
                ),
              ),
              SizedBox(
                height: 20,
                width: 20,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  onPressed: () {
                    final current = int.tryParse(controller.text) ?? min;
                    if (current > min) {
                      controller.text = '${current - 1}';
                    }
                  },
                  icon: const Icon(Icons.arrow_drop_down),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Base Config", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStepperField(
              controller: _indexStartController,
              label: "Index start",
              min: 1,
            ),
            const SizedBox(width: 16),
            _buildStepperField(
              controller: _stepController,
              label: "Step",
              min: 1,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStepperField(
              controller: _padController,
              label: "Pad to length",
              min: 0,
            ),
            const SizedBox(width: 16),
            _buildStepperField(
              controller: _repeatController,
              label: "Repeat",
              min: 1,
            ),
          ],
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
        const SizedBox(height: 12),
        Text("Extra Config", style: Theme.of(context).textTheme.titleMedium),
        RadioGroup<InsertPosition>(
          groupValue: _insertWhere,
          onChanged: (v) => _update(() => _insertWhere = v!),
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
                      enabled: _insertWhere == InsertPosition.position,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: "Index",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (_) => _clampNumber(_positionController, 1),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          iconSize: 18,
                          onPressed: _insertWhere == InsertPosition.position
                              ? () {
                                  final current =
                                      int.tryParse(_positionController.text) ??
                                      1;
                                  _positionController.text = '${current + 1}';
                                }
                              : null,
                          icon: const Icon(Icons.arrow_drop_up),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          iconSize: 18,
                          onPressed: _insertWhere == InsertPosition.position
                              ? () {
                                  final current =
                                      int.tryParse(_positionController.text) ??
                                      1;
                                  if (current > 1) {
                                    _positionController.text = '${current - 1}';
                                  }
                                }
                              : null,
                          icon: const Icon(Icons.arrow_drop_down),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
