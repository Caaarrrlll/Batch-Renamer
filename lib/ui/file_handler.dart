import 'dart:developer';

import 'package:bulk_renamer/services/file_list.dart';
import 'package:bulk_renamer/services/file_listing.dart';
import 'package:bulk_renamer/services/file_renaming.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class FileHandler extends StatefulWidget {
  /// The preview to show; the parent recalculates it when [files] change.
  final RenamePlan plan;
  final List<DropItem> files;
  final VoidCallback onChanged;

  const FileHandler({
    super.key,
    required this.plan,
    required this.files,
    required this.onChanged,
  });

  @override
  State<FileHandler> createState() => _FileHandlerState();
}

class _FileHandlerState extends State<FileHandler> {
  bool _dragging = false;

  /// Adds dropped or picked [paths]; folders are replaced by all the files
  /// inside them.
  Future<void> _addPaths(Iterable<String> paths) async {
    final listing = await FileListingService.expand(paths);
    if (!mounted) return;
    final skipped = addNewFiles(widget.files, [
      for (final path in listing.files) DropItemFile(path),
    ]);
    widget.onChanged();

    final messages = [
      if (skipped > 0) "Skipped $skipped file(s) already in the list.",
      if (listing.unreadableFolders.isNotEmpty)
        "Couldn't read ${listing.unreadableFolders.length} folder(s), "
            "so their files weren't added.",
    ];
    if (messages.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(messages.join(' '))));
    }
  }

  Future<void> _pickFiles() async {
    final List<PlatformFile> picked;
    try {
      picked = await FilePicker.pickFiles(dialogTitle: "Add files");
    } on Exception catch (e, s) {
      log('File picker failed', name: 'FileHandler', error: e, stackTrace: s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't open the file picker: $e")),
        );
      }
      return;
    }
    if (!mounted) return;
    await _addPaths([for (final file in picked) ?file.path]);
  }

  Widget _row(Widget current, Widget preview, {TextStyle? style}) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: current),
          const SizedBox(width: 16),
          Expanded(child: preview),
        ],
      ),
    );
    return style == null
        ? row
        : SizedBox(
            height: 36,
            child: DefaultTextStyle.merge(style: style, child: row),
          );
  }

  Widget _entryRow(RenamePlanEntry entry, ColorScheme colors) {
    final problem = entry.problem;
    Widget name(String text, {String? tooltip, TextStyle? style}) => Tooltip(
      message: tooltip ?? text,
      waitDuration: const Duration(milliseconds: 600),
      child: Text(
        text,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    final preview = name(
      entry.newName,
      style: TextStyle(
        color: problem != null
            ? colors.error
            : entry.changed
            ? colors.primary
            : null,
        fontWeight: entry.changed ? FontWeight.w600 : null,
      ),
    );

    return _row(
      Align(
        alignment: Alignment.centerLeft,
        // The full path tells apart files with the same name from
        // different folders.
        child: name(entry.oldName, tooltip: entry.oldPath),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: problem == null
            ? preview
            : Row(
                children: [
                  Tooltip(
                    message: problem,
                    child: Icon(
                      Icons.error_outline,
                      size: 16,
                      color: colors.error,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(child: preview),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final problemCount = plan.problems.length;
    final colors = Theme.of(context).colorScheme;

    return DropTarget(
      onDragDone: (detail) => _addPaths(detail.files.map((f) => f.path)),
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
                  // Transparent Material so the click ripple shows on top of
                  // the container's background colour.
                  ? Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        onTap: _pickFiles,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            "Drop files here or click to add",
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        _row(
                          const Text("Current Name"),
                          const Text("Preview"),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const Divider(height: 1),
                        Expanded(
                          // Only the visible rows are built, so large
                          // batches stay responsive.
                          child: ListView.builder(
                            itemCount: plan.entries.length,
                            itemExtent: 32,
                            itemBuilder: (context, index) =>
                                _entryRow(plan.entries[index], colors),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
