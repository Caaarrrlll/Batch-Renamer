import 'package:bulk_renamer/ui/replacement_rules/delete_rule.dart';
import 'package:bulk_renamer/ui/replacement_rules/find_replace_rule.dart';
import 'package:bulk_renamer/ui/replacement_rules/insert_rule.dart';
import 'package:bulk_renamer/models/rule_config.dart';
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
  final _deleteKey = GlobalKey<DeleteRuleState>();

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
      case RuleType.delete:
        final state = _deleteKey.currentState;
        config = RuleConfig(
          type: RuleType.delete,
          deleteFrom: state?.from ?? DeleteFrom.position,
          deleteFromPosition: state?.fromPosition ?? 1,
          deleteFromDelimiter: state?.fromDelimiter ?? '',
          deleteUntil: state?.until ?? DeleteUntil.tillEnd,
          deleteUntilCount: state?.untilCount ?? 1,
          deleteUntilDelimiter: state?.untilDelimiter ?? '',
          deleteSkipExtension: state?.skipExtension ?? true,
          deleteRightToLeft: state?.rightToLeft ?? false,
          deleteKeepDelimiters: state?.keepDelimiters ?? false,
        );
      default:
        config = RuleConfig(type: _selectedRule!);
    }
    Navigator.of(context).pop(config);
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
                      title: Text(type.label,
                          style: type.isAvailable
                              ? null
                              : TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant)),
                      trailing: type.hasConfiguration
                          ? const Icon(Icons.chevron_right)
                          : null,
                      onTap: type.isAvailable
                          ? () => setState(() => _selectedRule = type)
                          : null,
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
                if (_selectedRule == RuleType.delete)
                  DeleteRule(
                    key: _deleteKey,
                    initialFrom:
                        widget.existing?.deleteFrom ?? DeleteFrom.position,
                    initialFromPosition:
                        widget.existing?.deleteFromPosition ?? 1,
                    initialFromDelimiter:
                        widget.existing?.deleteFromDelimiter ?? '',
                    initialUntil:
                        widget.existing?.deleteUntil ?? DeleteUntil.tillEnd,
                    initialUntilCount:
                        widget.existing?.deleteUntilCount ?? 1,
                    initialUntilDelimiter:
                        widget.existing?.deleteUntilDelimiter ?? '',
                    initialSkipExtension:
                        widget.existing?.deleteSkipExtension ?? true,
                    initialRightToLeft:
                        widget.existing?.deleteRightToLeft ?? false,
                    initialKeepDelimiters:
                        widget.existing?.deleteKeepDelimiters ?? false,
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
