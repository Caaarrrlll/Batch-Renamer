import 'package:bulk_renamer/ui/replacement_rules/find_replace_rule.dart';
import 'package:bulk_renamer/ui/replacement_rules/insert_rule.dart';
import 'package:bulk_renamer/ui/rule_config.dart';
import 'package:flutter/material.dart';

class AddRuleDialog extends StatefulWidget {
  final RuleConfig? existing;

  const AddRuleDialog({super.key, this.existing});

  static Future<RuleConfig?> show(BuildContext context,
      {RuleConfig? existing}) {
    return showDialog<RuleConfig>(
      context: context,
      builder: (_) => AddRuleDialog(existing: existing),
    );
  }

  @override
  State<AddRuleDialog> createState() => _AddRuleDialogState();
}

class _AddRuleDialogState extends State<AddRuleDialog> {
  RuleType? _selectedRule;
  final _findReplaceKey = GlobalKey<FindReplaceRuleState>();
  final _insertKey = GlobalKey<InsertRuleState>();

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _selectedRule = widget.existing!.type;
    }
  }

  void _confirm() {
    if (_selectedRule == null) return;

    RuleConfig config;
    switch (_selectedRule!) {
      case RuleType.findReplace:
        final state = _findReplaceKey.currentState;
        config = RuleConfig(
          type: RuleType.findReplace,
          find: state?.find ?? '',
          replace: state?.replace ?? '',
          occurrence: state?.occurrence ?? Occurrence.all,
          caseSensitive: state?.caseSensitive ?? false,
          wholeWords: state?.wholeWords ?? false,
          skipExtension: state?.skipExtension ?? true,
        );
      case RuleType.insert:
        final state = _insertKey.currentState;
        config = RuleConfig(
          type: RuleType.insert,
          insertText: state?.insert ?? '',
          insertPosition: state?.position ?? InsertPosition.prefix,
          insertPositionIndex: state?.positionIndex ?? 1,
          insertRightToLeft: state?.rightToLeft ?? false,
          insertSkipExtension: state?.skipExtension ?? true,
        );
      default:
        config = RuleConfig(type: _selectedRule!);
    }
    Navigator.of(context).pop(config);
  }

  bool get _hasConfig =>
      _selectedRule == RuleType.findReplace || _selectedRule == RuleType.insert;

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
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
                      onPressed: () => setState(() => _selectedRule = null),
                    ),
                  Text(
                    _selectedRule?.label ?? "Add Rule",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_selectedRule == null) ...[
                ...RuleType.values.map((type) => ListTile(
                      leading: Icon(type.icon),
                      title: Text(type.label),
                      trailing: type.hasConfiguration
                          ? const Icon(Icons.chevron_right)
                          : null,
                      onTap: () => setState(() => _selectedRule = type),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    )),
              ] else ...[
                if (_selectedRule == RuleType.findReplace)
                  FindReplaceRule(
                    key: _findReplaceKey,
                    initialFind: widget.existing?.find ?? '',
                    initialReplace: widget.existing?.replace ?? '',
                    initialOccurrence:
                        widget.existing?.occurrence ?? Occurrence.all,
                    initialCaseSensitive:
                        widget.existing?.caseSensitive ?? false,
                    initialWholeWords:
                        widget.existing?.wholeWords ?? false,
                    initialSkipExtension:
                        widget.existing?.skipExtension ?? true,
                  ),
                if (_selectedRule == RuleType.insert)
                  InsertRule(
                    key: _insertKey,
                    initialInsert: widget.existing?.insertText ?? '',
                    initialPosition:
                        widget.existing?.insertPosition ?? InsertPosition.prefix,
                    initialPositionIndex:
                        widget.existing?.insertPositionIndex ?? 1,
                    initialRightToLeft:
                        widget.existing?.insertRightToLeft ?? false,
                    initialSkipExtension:
                        widget.existing?.insertSkipExtension ?? true,
                  ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: _confirm,
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
}
