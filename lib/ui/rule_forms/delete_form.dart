import 'package:bulk_renamer/models/rule.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DeleteRuleWidget extends StatefulWidget {
  final DeleteRule? initial;
  final ValueChanged<DeleteRule> onChanged;

  const DeleteRuleWidget({
    super.key,
    this.initial,
    required this.onChanged,
  });

  @override
  State<DeleteRuleWidget> createState() => _DeleteRuleWidgetState();
}

class _DeleteRuleWidgetState extends State<DeleteRuleWidget> {
  late final TextEditingController _fromPositionController;
  late final TextEditingController _fromDelimiterController;
  late final TextEditingController _untilCountController;
  late final TextEditingController _untilDelimiterController;
  late DeleteFrom _from;
  late DeleteUntil _until;
  late bool _skipExtension;
  late bool _rightToLeft;
  late bool _keepDelimiters;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _fromPositionController = TextEditingController(
        text: (init?.fromPosition ?? 1).toString());
    _fromDelimiterController =
        TextEditingController(text: init?.fromDelimiter ?? '');
    _untilCountController = TextEditingController(
        text: (init?.untilCount ?? 1).toString());
    _untilDelimiterController =
        TextEditingController(text: init?.untilDelimiter ?? '');
    _from = init?.from ?? DeleteFrom.position;
    _until = init?.until ?? DeleteUntil.tillEnd;
    _skipExtension = init?.skipExtension ?? true;
    _rightToLeft = init?.rightToLeft ?? false;
    _keepDelimiters = init?.keepDelimiters ?? false;

    _fromPositionController.addListener(_emitChange);
    _fromDelimiterController.addListener(_emitChange);
    _untilCountController.addListener(_emitChange);
    _untilDelimiterController.addListener(_emitChange);
  }

  @override
  void dispose() {
    _fromPositionController.removeListener(_emitChange);
    _fromDelimiterController.removeListener(_emitChange);
    _untilCountController.removeListener(_emitChange);
    _untilDelimiterController.removeListener(_emitChange);
    _fromPositionController.dispose();
    _fromDelimiterController.dispose();
    _untilCountController.dispose();
    _untilDelimiterController.dispose();
    super.dispose();
  }

  void _emitChange() {
    widget.onChanged(_buildRule());
  }

  DeleteRule _buildRule() {
    return DeleteRule(
      from: _from,
      fromPosition: int.tryParse(_fromPositionController.text) ?? 1,
      fromDelimiter: _fromDelimiterController.text,
      until: _until,
      untilCount: int.tryParse(_untilCountController.text) ?? 1,
      untilDelimiter: _untilDelimiterController.text,
      skipExtension: _skipExtension,
      rightToLeft: _rightToLeft,
      keepDelimiters: _keepDelimiters,
    );
  }

  void _update(void Function() modify) {
    setState(modify);
    widget.onChanged(_buildRule());
  }

  bool get _hasDelimiterActive =>
      _from == DeleteFrom.delimiter || _until == DeleteUntil.delimiter;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("From", style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        RadioGroup<DeleteFrom>(
          groupValue: _from,
          onChanged: (v) => _update(() => _from = v!),
          child: Column(
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 120,
                    child: Row(
                      children: [
                        Radio<DeleteFrom>(value: DeleteFrom.position),
                        Text("Position"),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 200,
                    child: TextField(
                      controller: _fromPositionController,
                      keyboardType: TextInputType.number,
                      enabled: _from == DeleteFrom.position,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: "Index",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        final num = int.tryParse(value);
                        if (num != null && num < 1) {
                          _fromPositionController.text = '1';
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(
                    width: 120,
                    child: Row(
                      children: [
                        Radio<DeleteFrom>(value: DeleteFrom.delimiter),
                        Text("Delimiter"),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 200,
                    child: TextField(
                      controller: _fromDelimiterController,
                      enabled: _from == DeleteFrom.delimiter,
                      decoration: const InputDecoration(
                        labelText: "Delimiter",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text("Until", style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        RadioGroup<DeleteUntil>(
          groupValue: _until,
          onChanged: (v) => _update(() => _until = v!),
          child: Column(
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 120,
                    child: Row(
                      children: [
                        Radio<DeleteUntil>(value: DeleteUntil.count),
                        Text("Count"),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 200,
                    child: TextField(
                      controller: _untilCountController,
                      keyboardType: TextInputType.number,
                      enabled: _until == DeleteUntil.count,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: "Count",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        final num = int.tryParse(value);
                        if (num != null && num < 1) {
                          _untilCountController.text = '1';
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(
                    width: 120,
                    child: Row(
                      children: [
                        Radio<DeleteUntil>(value: DeleteUntil.delimiter),
                        Text("Delimiter"),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 200,
                    child: TextField(
                      controller: _untilDelimiterController,
                      enabled: _until == DeleteUntil.delimiter,
                      decoration: const InputDecoration(
                        labelText: "Delimiter",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Radio<DeleteUntil>(value: DeleteUntil.tillEnd),
                  const Text("Till end"),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text("Additional Settings",
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        CheckboxListTile(
          value: _skipExtension,
          onChanged: (v) => _update(() => _skipExtension = v!),
          title: const Text("Skip file extension"),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          visualDensity: VisualDensity.compact,
        ),
        CheckboxListTile(
          value: _rightToLeft,
          onChanged: (v) => _update(() => _rightToLeft = v!),
          title: const Text("Right to left"),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          visualDensity: VisualDensity.compact,
        ),
        CheckboxListTile(
          value: _keepDelimiters,
          onChanged: _hasDelimiterActive
              ? (v) => _update(() => _keepDelimiters = v!)
              : null,
          title: const Text("Do not remove delimiters"),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
