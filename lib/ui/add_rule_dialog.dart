import 'package:bulk_renamer/ui/rule_forms/delete_form.dart';
import 'package:bulk_renamer/ui/rule_forms/find_replace_form.dart';
import 'package:bulk_renamer/ui/rule_forms/insert_form.dart';
import 'package:bulk_renamer/ui/rule_forms/clean_up_form.dart';
import 'package:bulk_renamer/models/rule.dart';
import 'package:flutter/material.dart';

class AddRuleDialog extends StatefulWidget {
  final Rule? existing;

  const AddRuleDialog({super.key, this.existing});

  static Future<Rule?> show(BuildContext context, {Rule? existing}) {
    return showDialog<Rule>(
      context: context,
      builder: (_) => AddRuleDialog(existing: existing),
    );
  }

  @override
  State<AddRuleDialog> createState() => _AddRuleDialogState();
}

enum _RuleType { findReplace, insert, delete, cleanUp }

class _AddRuleDialogState extends State<AddRuleDialog> {
  _RuleType? _selectedRule;
  Rule? _result;

  @override
  void initState() {
    super.initState();
    if (widget.existing case FindReplaceRule()) {
      _selectedRule = _RuleType.findReplace;
    } else if (widget.existing case InsertRule()) {
      _selectedRule = _RuleType.insert;
    } else if (widget.existing case DeleteRule()) {
      _selectedRule = _RuleType.delete;
    } else if (widget.existing case CleanUpRule()) {
      _selectedRule = _RuleType.cleanUp;
    }
  }

  void _confirm() {
    if (_result != null) {
      Navigator.of(context).pop(_result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (_selectedRule != null)
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => setState(() {
                        _selectedRule = null;
                        _result = null;
                      }),
                    ),
                  Text(
                    _selectedRule != null ? _labelForType(_selectedRule!) : "Add Rule",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_selectedRule == null) ...[
                ..._RuleType.values.map((type) => ListTile(
                      leading: Icon(_iconForType(type)),
                      title: Text(_labelForType(type)),
                      trailing: _hasConfiguration(type)
                          ? const Icon(Icons.chevron_right)
                          : null,
                      onTap: _isAvailable(type)
                          ? () => setState(() => _selectedRule = type)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    )),
              ] else ...[
                if (_selectedRule == _RuleType.findReplace)
                  FindReplaceRuleWidget(
                    initial: widget.existing is FindReplaceRule
                        ? widget.existing as FindReplaceRule
                        : null,
                    onChanged: (rule) => setState(() => _result = rule),
                  ),
                if (_selectedRule == _RuleType.insert)
                  InsertRuleWidget(
                    initial: widget.existing is InsertRule
                        ? widget.existing as InsertRule
                        : null,
                    onChanged: (rule) => setState(() => _result = rule),
                  ),
                if (_selectedRule == _RuleType.delete)
                  DeleteRuleWidget(
                    initial: widget.existing is DeleteRule
                        ? widget.existing as DeleteRule
                        : null,
                    onChanged: (rule) => setState(() => _result = rule),
                  ),
                if (_selectedRule == _RuleType.cleanUp)
                  CleanUpRuleWidget(
                    initial: widget.existing is CleanUpRule
                        ? widget.existing as CleanUpRule
                        : null,
                    onChanged: (rule) => setState(() => _result = rule),
                  ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: _result != null ? _confirm : null,
                    child: Text(isEditing ? "Save Changes" : "Add Rule"),
                  ),
                ),
              ],
              if (_selectedRule == null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Cancel"),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(_RuleType type) => switch (type) {
    _RuleType.findReplace => Icons.find_replace,
    _RuleType.insert => Icons.text_increase,
    _RuleType.delete => Icons.backspace,
    _RuleType.cleanUp => Icons.cleaning_services,
  };

  String _labelForType(_RuleType type) => switch (type) {
    _RuleType.findReplace => "Find & Replace",
    _RuleType.insert => "Insert",
    _RuleType.delete => "Delete",
    _RuleType.cleanUp => "Clean Up",
  };

  bool _hasConfiguration(_RuleType type) => true;

  bool _isAvailable(_RuleType type) =>
      type == _RuleType.findReplace ||
      type == _RuleType.insert ||
      type == _RuleType.delete ||
      type == _RuleType.cleanUp;
}
