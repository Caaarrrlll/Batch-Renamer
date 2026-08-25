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

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    final rules = await RulePersistence.load();
    if (mounted) setState(() => _rules.addAll(rules));
  }

  void _onRulesChanged() {
    setState(() {});
    RulePersistence.save(_rules);
  }

  void _clearSavedRules() {
    _rules.clear();
    RulePersistence.save(_rules);
    setState(() {});
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
                      pathController.text = dir;
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
              if (newPath.isNotEmpty) {
                await RulePersistence.setPath(newPath);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
    pathController.dispose();
  }

  Future<void> _renameFiles() async {
    if (_files.isEmpty || _rules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Add files and rules before renaming")),
      );
      return;
    }

    final paths = _files.map((f) => f.path).toList();
    final result = await FileRenamingService.renameFiles(paths, _rules);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.failed > 0
                ? "Renamed ${result.renamed} file(s), ${result.failed} failed"
                : "Renamed ${result.renamed} file(s)",
          ),
        ),
      );
      _files.clear();
      setState(() {});
    }
  }

  Future<void> _checkForUpdates() async {
    final update = await UpdateChecker.check();
    if (!mounted) return;

    if (update == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("You're up to date")));
      return;
    }

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
              'updates' => _checkForUpdates(),
              'clear' => _clearSavedRules(),
              'settings' => _showSettings(),
              _ => null,
            },
            itemBuilder: (_) => [
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final totalHeight = constraints.maxHeight;
          const verticalPadding = 24.0;
          const dividerTotalHeight = 22.0;
          const buttonHeight = 48.0;
          const buttonGap = 4.0;
          final availableHeight =
              totalHeight -
              verticalPadding -
              dividerTotalHeight -
              buttonHeight -
              buttonGap;
          final topHeight = availableHeight * _splitRatio;
          final bottomHeight = availableHeight * (1 - _splitRatio);

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: buttonHeight,
                  child: FilledButton.icon(
                    onPressed: _files.isNotEmpty && _rules.isNotEmpty
                        ? _renameFiles
                        : null,
                    icon: const Icon(Icons.edit, size: 20),
                    label: const Text("Rename File(s)"),
                  ),
                ),
                const SizedBox(height: buttonGap),
                SizedBox(
                  height: topHeight,
                  child: RenamingRules(
                    rules: _rules,
                    onChanged: _onRulesChanged,
                  ),
                ),
                GestureDetector(
                  onVerticalDragUpdate: (details) {
                    setState(() {
                      _splitRatio += details.delta.dy / availableHeight;
                      _splitRatio = _splitRatio.clamp(0.15, 0.85);
                    });
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeUpDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 2,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.outline,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: bottomHeight,
                  child: FileHandler(
                    rules: _rules,
                    files: _files,
                    onChanged: () => setState(() {}),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
