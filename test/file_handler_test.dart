import 'dart:io';

import 'package:bulk_renamer/models/rule.dart';
import 'package:bulk_renamer/services/file_renaming.dart';
import 'package:bulk_renamer/ui/file_handler.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('empty file list invites a click to add files', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FileHandler(
            plan: const RenamePlan([], caseInsensitive: false),
            files: const [],
            onChanged: () {},
          ),
        ),
      ),
    );

    final hint = find.text('Drop files here or click to add');
    expect(hint, findsOneWidget);
    expect(
      find.ancestor(of: hint, matching: find.byType(InkWell)),
      findsOneWidget,
    );
  });

  testWidgets('preview builds only the visible rows of a large batch', (
    tester,
  ) async {
    final sep = Platform.pathSeparator;
    final files = [
      for (var i = 0; i < 5000; i++)
        DropItemFile('${sep}missing$sep${'file$i.txt'}'),
    ];
    final plan = FileRenamingService.plan(files.map((f) => f.path).toList(), [
      // Gives file0 and file1 the same name, to show a problem.
      const RegexRule(expression: r'^file[01]$', replace: 'same'),
      const InsertRule(insertText: 'new_'),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 400,
            child: FileHandler(plan: plan, files: files, onChanged: () {}),
          ),
        ),
      ),
    );

    expect(find.text("2 file(s) can't be renamed"), findsOneWidget);
    expect(find.text('file2.txt'), findsOneWidget);
    expect(find.text('new_file2.txt'), findsOneWidget);
    expect(find.text('file4999.txt'), findsNothing);
    expect(find.byIcon(Icons.error_outline), findsNWidgets(3));
  });
}
