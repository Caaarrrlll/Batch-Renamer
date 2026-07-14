import 'package:bulk_renamer/models/rule_config.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

class FileHandler extends StatefulWidget {
  final List<RuleConfig> rules;
  final List<DropItem> files;
  final VoidCallback onChanged;

  const FileHandler({
    super.key,
    required this.rules,
    required this.files,
    required this.onChanged,
  });

  @override
  State<FileHandler> createState() => _FileHandlerState();
}

class _FileHandlerState extends State<FileHandler> {
  bool _dragging = false;

  String _previewName(String filename) {
    var name = filename;
    for (final rule in widget.rules) {
      name = rule.apply(name);
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (detail) {
        widget.files.addAll(detail.files);
        widget.onChanged();
      },
      onDragEntered: (detail) {
        setState(() {
          _dragging = true;
        });
      },
      onDragExited: (detail) {
        setState(() {
          _dragging = false;
        });
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: _dragging
              ? Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.08)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _dragging
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
              child: Row(
                children: [
                  Icon(Icons.file_upload_outlined,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    "Files",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  if (widget.files.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        widget.files.clear();
                        widget.onChanged();
                      },
                      icon: const Icon(Icons.delete_outline),
                      tooltip: "Clear files",
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: widget.files.isEmpty
                  ? Center(
                      child: Text(
                        "Drop files here",
                        style:
                            Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.9,
                        child: DataTable(
                          headingRowHeight: 36,
                          dataRowMinHeight: 32,
                          dataRowMaxHeight: 32,
                          columns: const [
                            DataColumn(label: Text("Current Name")),
                            DataColumn(label: Text("Preview")),
                          ],
                          rows: widget.files.map((file) {
                            final name = file.name;
                            final preview = _previewName(name);
                            final changed = name != preview;
                            return DataRow(cells: [
                              DataCell(Text(name)),
                              DataCell(
                                Text(
                                  preview,
                                  style: TextStyle(
                                    color: changed
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                        : null,
                                    fontWeight:
                                        changed ? FontWeight.w600 : null,
                                  ),
                                ),
                              ),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
