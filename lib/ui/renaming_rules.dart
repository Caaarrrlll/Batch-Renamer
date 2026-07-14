import 'package:bulk_renamer/ui/add_rule_dialog.dart';
import 'package:bulk_renamer/ui/rule_config.dart';
import 'package:flutter/material.dart';

class RenamingRules extends StatelessWidget {
  final List<RuleConfig> rules;
  final VoidCallback onChanged;

  const RenamingRules({
    super.key,
    required this.rules,
    required this.onChanged,
  });

  Future<void> _addRule(BuildContext context) async {
    final config = await AddRuleDialog.show(context);
    if (config != null) {
      rules.add(config);
      onChanged();
    }
  }

  Future<void> _editRule(BuildContext context, int index) async {
    final config =
        await AddRuleDialog.show(context, existing: rules[index]);
    if (config != null) {
      rules[index] = config;
      onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rule, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text.rich(
                TextSpan(
                  text: "Renaming Rules ",
                  style: Theme.of(context).textTheme.titleMedium,
                  children: [
                    TextSpan(
                      text: "(Click to configure)",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _addRule(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Add Rule"),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: rules.isEmpty
                ? Center(
                    child: Text(
                      "No rules added yet",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  )
                : ListView.builder(
                    itemCount: rules.length,
                    itemBuilder: (context, index) {
                      final rule = rules[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 4),
                        child: ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: Icon(rule.type.icon),
                          title: Text(rule.type.label),
                          onTap: () => _editRule(context, index),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (index > 0)
                                IconButton(
                                  icon: const Icon(Icons.arrow_upward,
                                      size: 20),
                                  onPressed: () {
                                    final temp = rules[index];
                                    rules[index] = rules[index - 1];
                                    rules[index - 1] = temp;
                                    onChanged();
                                  },
                                  tooltip: "Move up",
                                ),
                              if (index < rules.length - 1)
                                IconButton(
                                  icon: const Icon(Icons.arrow_downward,
                                      size: 20),
                                  onPressed: () {
                                    final temp = rules[index];
                                    rules[index] = rules[index + 1];
                                    rules[index + 1] = temp;
                                    onChanged();
                                  },
                                  tooltip: "Move down",
                                ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () {
                                  rules.removeAt(index);
                                  onChanged();
                                },
                                tooltip: "Remove rule",
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
