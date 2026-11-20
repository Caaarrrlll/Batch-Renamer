import 'dart:io';

import 'package:bulk_renamer/models/rule.dart';
import 'package:bulk_renamer/services/file_renaming.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

final _numberOrText = RegExp(r'\d+|\D+');
final _startsWithDigit = RegExp(r'^\d');
final _leadingZeros = RegExp(r'^0+(?=\d)');

/// Compares file names the way people read them: case-insensitively, with
/// runs of digits compared by value, so "file2" sorts before "file10".
int compareNatural(String a, String b) {
  final aParts = _numberOrText.allMatches(a.toLowerCase()).toList();
  final bParts = _numberOrText.allMatches(b.toLowerCase()).toList();

  for (var i = 0; i < aParts.length && i < bParts.length; i++) {
    final x = aParts[i][0]!;
    final y = bParts[i][0]!;
    final xIsNumber = _startsWithDigit.hasMatch(x);
    final yIsNumber = _startsWithDigit.hasMatch(y);

    final int result;
    if (xIsNumber && yIsNumber) {
      // Compare by value without parsing, so long digit runs can't overflow.
      final xValue = x.replaceFirst(_leadingZeros, '');
      final yValue = y.replaceFirst(_leadingZeros, '');
      result = xValue.length != yValue.length
          ? xValue.length.compareTo(yValue.length)
          : xValue.compareTo(yValue);
    } else {
      result = x.compareTo(y);
    }
    if (result != 0) return result;
  }

  final lengthResult = aParts.length.compareTo(bParts.length);
  // Fall back to plain comparison so names like "a01" and "a1" stay stable.
  return lengthResult != 0 ? lengthResult : a.compareTo(b);
}

/// Adds the [added] files that aren't already in [files], then sorts
/// [files] naturally by name. Returns how many were skipped as duplicates.
int addNewFiles(List<DropItem> files, Iterable<DropItem> added) {
  final caseInsensitive = Platform.isWindows || Platform.isMacOS;
  String key(String path) => caseInsensitive ? path.toLowerCase() : path;

  final known = files.map((f) => key(f.path)).toSet();
  var skipped = 0;
  for (final item in added) {
    if (known.add(key(item.path))) {
      files.add(item);
    } else {
      skipped++;
    }
  }
  files.sort((a, b) => compareNatural(a.name, b.name));
  return skipped;
}

class FileHandler extends StatefulWidget {
  final List<Rule> rules;
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

  void _addFiles(Iterable<DropItem> items) {
    final skipped = addNewFiles(widget.files, items);
    widget.onChanged();
    if (skipped > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Skipped $skipped file(s) already in the list")),
      );
    }
  }

  Future<void> _pickFiles() async {
    final picked = await FilePicker.pickFiles(dialogTitle: "Add files");
    if (!mounted) return;
    _addFiles([
      for (final file in picked)
        if (file.path case final path?) DropItemFile(path),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final plan = FileRenamingService.plan(
      widget.files.map((f) => f.path).toList(),
      widget.rules,
    );
    final problemCount = plan.problems.length;
    final colors = Theme.of(context).colorScheme;

    return DropTarget(
      onDragDone: (detail) => _addFiles(detail.files),
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
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
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
                  Icon(
                    Icons.file_upload_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text("Files", style: Theme.of(context).textTheme.titleMedium),
                  if (problemCount > 0) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.error_outline, size: 18, color: colors.error),
                    const SizedBox(width: 4),
                    Text(
                      "$problemCount file(s) can't be renamed",
                      style: TextStyle(color: colors.error),
                    ),
                  ],
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _pickFiles,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Add Files"),
                  ),
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
                        "Drop files here or click Add Files",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: SingleChildScrollView(
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
                            rows: plan.entries.map((entry) {
                              final problem = entry.problem;
                              final preview = Text(
                                entry.newName,
                                style: TextStyle(
                                  color: problem != null
                                      ? colors.error
                                      : entry.changed
                                      ? colors.primary
                                      : null,
                                  fontWeight: entry.changed
                                      ? FontWeight.w600
                                      : null,
                                ),
                              );
                              return DataRow(
                                cells: [
                                  DataCell(Text(entry.oldName)),
                                  DataCell(
                                    problem == null
                                        ? preview
                                        : Tooltip(
                                            message: problem,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.error_outline,
                                                  size: 16,
                                                  color: colors.error,
                                                ),
                                                const SizedBox(width: 4),
                                                preview,
                                              ],
                                            ),
                                          ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
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
