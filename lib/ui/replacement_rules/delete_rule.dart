import 'package:bulk_renamer/models/rule_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DeleteRule extends StatefulWidget {
  final DeleteFrom initialFrom;
  final int initialFromPosition;
  final String initialFromDelimiter;
  final DeleteUntil initialUntil;
  final int initialUntilCount;
  final String initialUntilDelimiter;
  final bool initialSkipExtension;
  final bool initialRightToLeft;
  final bool initialKeepDelimiters;

  const DeleteRule({
    super.key,
    this.initialFrom = DeleteFrom.position,
    this.initialFromPosition = 1,
    this.initialFromDelimiter = '',
    this.initialUntil = DeleteUntil.tillEnd,
    this.initialUntilCount = 1,
    this.initialUntilDelimiter = '',
    this.initialSkipExtension = true,
    this.initialRightToLeft = false,
    this.initialKeepDelimiters = false,
  });

  @override
  State<DeleteRule> createState() => DeleteRuleState();
}

class DeleteRuleState extends State<DeleteRule> {
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
    _fromPositionController =
        TextEditingController(text: widget.initialFromPosition.toString());
    _fromDelimiterController =
        TextEditingController(text: widget.initialFromDelimiter);
    _untilCountController =
        TextEditingController(text: widget.initialUntilCount.toString());
    _untilDelimiterController =
        TextEditingController(text: widget.initialUntilDelimiter);
    _from = widget.initialFrom;
    _until = widget.initialUntil;
    _skipExtension = widget.initialSkipExtension;
    _rightToLeft = widget.initialRightToLeft;
    _keepDelimiters = widget.initialKeepDelimiters;
  }

  @override
  void dispose() {
    _fromPositionController.dispose();
    _fromDelimiterController.dispose();
    _untilCountController.dispose();
    _untilDelimiterController.dispose();
    super.dispose();
  }

  DeleteFrom get from => _from;
  int get fromPosition => int.tryParse(_fromPositionController.text) ?? 1;
  String get fromDelimiter => _fromDelimiterController.text;
  DeleteUntil get until => _until;
  int get untilCount => int.tryParse(_untilCountController.text) ?? 1;
  String get untilDelimiter => _untilDelimiterController.text;
  bool get skipExtension => _skipExtension;
  bool get rightToLeft => _rightToLeft;
  bool get keepDelimiters => _keepDelimiters;

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
          onChanged: (v) => setState(() => _from = v!),
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
          onChanged: (v) => setState(() => _until = v!),
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
          onChanged: (v) => setState(() => _skipExtension = v!),
          title: const Text("Skip file extension"),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          visualDensity: VisualDensity.compact,
        ),
        CheckboxListTile(
          value: _rightToLeft,
          onChanged: (v) => setState(() => _rightToLeft = v!),
          title: const Text("Right to left"),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          visualDensity: VisualDensity.compact,
        ),
        CheckboxListTile(
          value: _keepDelimiters,
          onChanged: _hasDelimiterActive
              ? (v) => setState(() => _keepDelimiters = v!)
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
