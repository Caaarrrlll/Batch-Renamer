import 'dart:io';

import 'package:bulk_renamer/ui/file_handler.dart';
import 'package:bulk_renamer/ui/renaming_rules.dart';
import 'package:bulk_renamer/ui/rule_config.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double _splitRatio = 0.45;
  final List<RuleConfig> _rules = [];
  final List<DropItem> _files = [];

  Future<void> _renameFiles() async {
    int renamed = 0;
    int failed = 0;

    for (final file in _files) {
      final oldPath = file.path;
      final oldName = file.name;
      var newName = oldName;
      for (final rule in _rules) {
        newName = rule.apply(newName);
      }
      if (newName == oldName) continue;

      final dir = File(oldPath).parent.path;
      final newPath = '$dir${Platform.pathSeparator}$newName';

      try {
        await File(oldPath).rename(newPath);
        renamed++;
      } catch (e) {
        failed++;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failed > 0
                ? "Renamed $renamed file(s), $failed failed"
                : "Renamed $renamed file(s)",
          ),
        ),
      );
      _files.clear();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final totalHeight = constraints.maxHeight;
          const verticalPadding = 24.0;
          const dividerTotalHeight = 22.0;
          const buttonHeight = 48.0;
          const buttonGap = 4.0;
          final availableHeight = totalHeight -
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
                    onPressed:
                        _files.isNotEmpty && _rules.isNotEmpty ? _renameFiles : null,
                    icon: const Icon(Icons.edit, size: 20),
                    label: const Text("Rename File(s)"),
                  ),
                ),
                const SizedBox(height: buttonGap),
                SizedBox(
                  height: topHeight,
                  child: RenamingRules(
                    rules: _rules,
                    onChanged: () => setState(() {}),
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
                          color:
                              Theme.of(context).colorScheme.outlineVariant,
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
