import 'dart:io';

import 'package:bulk_renamer/services/file_list.dart';
import 'package:bulk_renamer/services/file_renaming.dart';
import 'package:bulk_renamer/services/rule_persistence.dart';
import 'package:bulk_renamer/services/update_checker.dart';
import 'package:bulk_renamer/ui/file_handler.dart';
import 'package:bulk_renamer/ui/renaming_rules.dart';
import 'package:bulk_renamer/models/rule.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double _splitRatio = 0.45;
  final List<Rule> _rules = [];
  final List<DropItem> _files = [];
  bool _renaming = false;

  /// What the last rename did (old path to new path), so it can be undone.
  /// Kept in memory only.
  Map<String, String>? _lastRename;

  /// The preview of what renaming would do. Recalculated only when files or
  /// rules change, not on every rebuild (e.g. while dragging the splitter).
  RenamePlan _plan = const RenamePlan([], caseInsensitive: false);

  /// Applies [change] to the files or rules and refreshes the preview.
  void _update([VoidCallback? change]) {
    setState(() {
      change?.call();
      _plan = FileRenamingService.plan(
        _files.map((f) => f.path).toList(),
        _rules,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    final result = await RulePersistence.load();
    if (!mounted) return;
    _update(
      () => _rules
        ..clear()
        ..addAll(result.rules),
    );

    if (!result.hasProblems) return;
    final what = result.unreadable
        ? "Your saved rules couldn't be read."
        : "${result.skipped} saved rule(s) couldn't be read and were left out.";
    final backup = result.backupPath != null
        ? "The original file was backed up to:\n${result.backupPath}"
        : "The original file could not be backed up, so it may be "
              "overwritten the next time rules are saved.";
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Problem loading saved rules"),
        content: SelectableText("$what\n\n$backup"),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _saveRules() async {
    final saved = await RulePersistence.save(_rules);
    if (!saved && mounted) {
      _showMessage(
        "Couldn't save rules. Check the rules file location in Settings.",
      );
    }
  }

  void _onRulesChanged() {
    _update();
    _saveRules();
  }

  Future<void> _clearSavedRules() async {
    if (_rules.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear saved rules?"),
        content: Text(
          "Remove all ${_rules.length} rule(s)? This can't be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Clear"),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _update(_rules.clear);
    await _saveRules();
  }

  Future<void> _showSettings() async {
    final currentPath = await RulePersistence.currentPath();

    if (!mounted) return;
    final pathController = TextEditingController(text: currentPath);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Settings"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Rules file location",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: pathController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      labelText: "Path",
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    final dir = await FilePicker.getDirectoryPath();
                    if (dir != null) {
                      pathController.text =
                          '$dir${Platform.pathSeparator}settings.json';
                    }
                  },
                  icon: const Icon(Icons.folder_open, size: 18),
                  label: const Text("Browse"),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () async {
              final newPath = pathController.text.trim();
              if (newPath.isEmpty) return;
              final bool usedExisting;
              try {
                usedExisting = await RulePersistence.setPath(newPath);
              } on FileSystemException catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Couldn't move rules there: ${e.osError?.message ?? e.message}",
                      ),
                    ),
                  );
                }
                return;
              }
              if (context.mounted) Navigator.of(context).pop();
              if (usedExisting) {
                _showMessage("Loaded the rules file found at the new location");
                await _loadRules();
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
    pathController.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _renameFiles() async {
    if (_renaming) return;
    if (_files.isEmpty || _rules.isEmpty) {
      _showMessage("Add files and rules before renaming");
      return;
    }

    final plan = FileRenamingService.plan(
      _files.map((f) => f.path).toList(),
      _rules,
    );
    if (plan.hasProblems) {
      _showMessage(
        "${plan.problems.length} file(s) can't be renamed. "
        "Hover the marked names in the preview for details.",
      );
      return;
    }
    final count = plan.changes.length;
    if (count == 0) {
      _showMessage("The rules don't change any file names");
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Rename files?"),
        content: Text(
          "Rename $count file(s) as shown in the preview? "
          "You can undo this until you rename again or close the app.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Rename"),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _renaming = true);
    final RenameResult result;
    try {
      result = await FileRenamingService.execute(plan);
    } finally {
      if (mounted) setState(() => _renaming = false);
    }
    if (!mounted) return;

    // Keep only the files that failed, so they can be fixed and retried.
    final failedPaths = result.failures.map((f) => f.path).toSet();
    _update(() {
      _files.removeWhere((f) => !failedPaths.contains(f.path));
      _lastRename = result.moves.isEmpty ? null : result.moves;
    });

    if (result.failures.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Renamed ${result.renamed} file(s)"),
          action: SnackBarAction(label: "Undo", onPressed: _undoRename),
        ),
      );
      return;
    }
    await _showFailures(
      "Renamed ${result.renamed} file(s), ${result.failed} failed",
      result.failures,
    );
  }

  /// Puts the files from the last rename back to their old names.
  Future<void> _undoRename() async {
    final moves = _lastRename;
    if (moves == null || _renaming) return;

    final plan = FileRenamingService.planUndo(moves);
    if (plan.hasProblems) {
      await _showFailures(
        "Can't undo the last rename",
        [
          for (final e in plan.problems)
            RenameFailure(
              e.oldPath,
              "Can't go back to \"${e.newName}\": "
              "${e.problem}",
            ),
        ],
        footer: "Nothing was changed. Resolve these and try again.",
      );
      return;
    }

    setState(() => _renaming = true);
    final RenameResult result;
    try {
      result = await FileRenamingService.execute(plan);
    } finally {
      if (mounted) setState(() => _renaming = false);
    }
    if (!mounted) return;

    // Restored files go back in the list so the rules can be adjusted and
    // run again. Files that couldn't be restored stay undoable.
    _update(() {
      addNewFiles(_files, [
        for (final path in result.moves.values) DropItemFile(path),
      ]);
      final remaining = {
        for (final MapEntry(key: oldPath, value: newPath) in moves.entries)
          if (!result.moves.containsKey(newPath)) oldPath: newPath,
      };
      _lastRename = remaining.isEmpty ? null : remaining;
    });

    if (result.failures.isEmpty) {
      _showMessage("Restored ${result.renamed} file(s) to their old names");
      return;
    }
    await _showFailures(
      "Restored ${result.renamed} file(s), ${result.failed} failed",
      result.failures,
    );
  }

  Future<void> _showFailures(
    String title,
    List<RenameFailure> failures, {
    String? footer,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 500,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final failure in failures)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.error_outline),
                  title: Text(failure.path),
                  subtitle: Text(failure.message),
                ),
              if (footer != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(footer),
                ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _checkForUpdates() async {
    final UpdateInfo? found;
    try {
      found = await UpdateChecker.check();
    } on UpdateCheckException catch (e) {
      if (mounted) _showMessage("Couldn't check for updates. $e");
      return;
    }
    if (!mounted) return;

    if (found == null) {
      _showMessage("You're up to date");
      return;
    }
    final update = found;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Update v${update.latestVersion} Available"),
        content: SingleChildScrollView(
          child: Text(
            update.releaseNotes.isEmpty
                ? "A new version is available."
                : update.releaseNotes,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Later"),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await launchUrl(
                Uri.parse(update.downloadUrl),
                mode: LaunchMode.externalApplication,
              );
            },
            child: const Text("Download"),
          ),
        ],
      ),
    );
  }

  static const _splitterHeight = 22.0;

  Widget _splitter(double available) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (available <= 0) return;
        setState(() {
          _splitRatio = (_splitRatio + details.delta.dy / available).clamp(
            0.15,
            0.85,
          );
        });
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeUpDown,
        child: SizedBox(
          height: _splitterHeight,
          child: Center(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: colors.outlineVariant,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Center(
                child: Container(
                  width: 40,
                  height: 2,
                  decoration: BoxDecoration(
                    color: colors.outline,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) => switch (v) {
              'undo' => _undoRename(),
              'updates' => _checkForUpdates(),
              'clear' => _clearSavedRules(),
              'settings' => _showSettings(),
              _ => null,
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'undo',
                enabled: _lastRename != null && !_renaming,
                child: Row(
                  children: [
                    const Icon(Icons.undo, size: 20),
                    const SizedBox(width: 12),
                    const Text("Undo Last Rename"),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'updates',
                child: Row(
                  children: [
                    const Icon(Icons.update, size: 20),
                    const SizedBox(width: 12),
                    const Text("Check for Updates"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    const Icon(Icons.delete_sweep, size: 20),
                    const SizedBox(width: 12),
                    const Text("Clear Saved Rules"),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    const Icon(Icons.settings, size: 20),
                    const SizedBox(width: 12),
                    const Text("Settings"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _files.isNotEmpty && _rules.isNotEmpty && !_renaming
                    ? _renameFiles
                    : null,
                icon: const Icon(Icons.edit, size: 20),
                label: const Text("Rename File(s)"),
              ),
            ),
            const SizedBox(height: 4),
            // The rules and files panels share whatever height is left,
            // split by the draggable divider.
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final available = (constraints.maxHeight - _splitterHeight)
                      .clamp(0.0, double.infinity);
                  return Column(
                    children: [
                      SizedBox(
                        height: available * _splitRatio,
                        child: RenamingRules(
                          rules: _rules,
                          onChanged: _onRulesChanged,
                        ),
                      ),
                      _splitter(available),
                      Expanded(
                        child: FileHandler(
                          plan: _plan,
                          files: _files,
                          onChanged: _update,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
