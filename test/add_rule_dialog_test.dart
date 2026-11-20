import 'package:bulk_renamer/models/rule.dart';
import 'package:bulk_renamer/ui/add_rule_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Opens the dialog and returns a function that gives the rule it closed
  /// with.
  Future<Rule? Function()> open(WidgetTester tester, {Rule? existing}) async {
    // Tall enough for the longest form, so its buttons can be tapped.
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Rule? result;
    await tester.pumpWidget(
      MaterialApp(
        // The test font draws every character as a full square, much wider
        // than real text; scale it down so the forms' rows fit as they do
        // in the app.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(0.6)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await AddRuleDialog.show(
                context,
                existing: existing,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return () => result;
  }

  FilledButton button(WidgetTester tester, String label) => tester.widget(
    find.ancestor(of: find.text(label), matching: find.byType(FilledButton)),
  );

  testWidgets('adds a rule with its default settings without changes', (
    tester,
  ) async {
    final result = await open(tester);
    await tester.tap(find.text('Clean Up'));
    await tester.pumpAndSettle();

    expect(button(tester, 'Add Rule').onPressed, isNotNull);
    await tester.tap(find.widgetWithText(FilledButton, 'Add Rule'));
    await tester.pumpAndSettle();

    expect(result()?.toJson(), const CleanUpRule().toJson());
  });

  testWidgets('saves an edited rule without changes', (tester) async {
    const existing = InsertRule(insertText: 'x_');
    final result = await open(tester, existing: existing);

    expect(button(tester, 'Save Changes').onPressed, isNotNull);
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(result()?.toJson(), existing.toJson());
  });

  testWidgets('switching type while editing starts from defaults', (
    tester,
  ) async {
    final result = await open(
      tester,
      existing: const InsertRule(insertText: 'x_'),
    );
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change Case'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(result()?.toJson(), const ChangeCaseRule().toJson());
  });

  testWidgets('cannot save a regex that is not valid', (tester) async {
    await open(tester, existing: const RegexRule(expression: '('));

    expect(button(tester, 'Save Changes').onPressed, isNull);
  });
}
