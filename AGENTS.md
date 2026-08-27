# AGENTS.md

Instructions for AI coding agents working on the **Bulk Renamer** repository.

## 1. Project Overview

**Bulk Renamer** is a cross-platform Flutter desktop application for batch-renaming files.

The primary development and target platform is **Windows**, with support for Linux and macOS.

The application allows users to:

* Add files through drag-and-drop or file selection.
* Build an ordered list of renaming rules.
* Preview the resulting filenames.
* Reorder, edit, and remove rules.
* Apply the rules to rename files on disk.
* Persist renaming rules between sessions.

Supported rule types:

* Find & Replace
* Insert
* Delete
* Clean Up
* Change Case
* Regex
* Serialize

---

## 2. Development Environment

### Preferred IDE

Use **Visual Studio Code** as the primary IDE.

When making changes:

* Prefer VS Code-compatible project structure and tooling.
* Keep `.vscode/` configuration consistent with Flutter/Dart development.
* Prefer using the Dart and Flutter VS Code extensions for debugging, analysis, formatting, and test execution.
* Do not introduce IDE-specific dependencies into the application itself.
* Keep all functionality runnable through standard Flutter/Dart CLI commands.

### Required tooling

The development environment should have:

* Flutter SDK
* Dart SDK bundled with Flutter
* Visual Studio Code
* Flutter VS Code extension
* Dart VS Code extension
* Windows desktop support enabled for Windows development

If Windows desktop support is not enabled:

```bash
flutter config --enable-windows-desktop
```

Verify the environment with:

```bash
flutter doctor
flutter devices
```

---

## 3. Tech Stack

* **Language:** Dart
* **Framework:** Flutter
* **Dart SDK:** `^3.12.0`
* **Primary platform:** Windows desktop
* **Secondary platforms:** Linux and macOS
* **State management:** Flutter `StatefulWidget` + `setState`
* **Persistence:** `shared_preferences` and JSON
* **Settings storage:** `settings.json` in the application documents directory
* **Rule persistence:** `RulePersistence`

Important packages include:

* `desktop_drop`
* `file_picker`
* `url_launcher`
* `http`
* `package_info_plus`
* `path_provider`
* `shared_preferences`
* `msix`

Do not introduce a state-management framework unless there is a clear, demonstrated need.

---

## 4. Repository Structure

```text
lib/
├── main.dart
│   └── Application entry point and MaterialApp configuration
│
├── models/
│   └── rule.dart
│       └── Rule base class, rule implementations, and enums
│
├── services/
│   ├── file_renaming.dart
│   │   └── Applies rules and performs file renames
│   ├── rule_persistence.dart
│   │   └── Saves and loads rules as JSON
│   └── update_checker.dart
│       └── Checks GitHub for newer releases
│
└── ui/
    ├── home_page.dart
    │   └── Main application screen
    ├── renaming_rules.dart
    │   └── Displays and manages active rules
    ├── add_rule_dialog.dart
    │   └── Rule type selection and rule form hosting
    ├── file_handler.dart
    │   └── File drag-and-drop, selection, and preview
    └── rule_forms/
        ├── find_replace_form.dart
        ├── insert_form.dart
        ├── delete_form.dart
        ├── clean_up_form.dart
        ├── change_case_form.dart
        ├── regex_form.dart
        └── serialize_form.dart

test/
└── widget_test.dart
    └── Basic application smoke test
```

Before modifying unfamiliar code, inspect the relevant model, service, UI component, and tests rather than assuming how the application works.

---

# 5. Architecture

## Rule Model

All renaming rules are defined in:

```text
lib/models/rule.dart
```

Rules extend the sealed `Rule` base class.

Each rule implements:

```dart
apply(String filename)
```

Rules transform a single filename.

Rules are executed **in list order**.

For example:

```text
Original filename
        ↓
Find & Replace
        ↓
Insert
        ↓
Change Case
        ↓
Serialize
        ↓
Final filename
```

Do not change rule execution order without explicitly considering its effect on existing behavior.

---

## Rule Serialization

Rules are persisted through:

```dart
toJson()
Rule.fromJson(...)
```

Every serialized rule contains a `$type` discriminator.

`Rule.fromJson` uses this discriminator to determine which rule implementation should be reconstructed.

When adding a new rule:

1. Add the rule implementation.
2. Add its `$type` discriminator.
3. Add serialization support.
4. Add deserialization support.
5. Add the corresponding UI form.
6. Add tests.
7. Verify that existing saved `settings.json` files continue to work.

Do not silently change existing serialization formats unless backward compatibility has been considered.

---

## Stateful Rules

`SerializeRule` contains internal counter state.

It must be reset before processing a batch.

Use:

```dart
reset()
```

before:

* Generating a preview.
* Performing a rename operation.
* Processing a new batch of files.

Both the preview system and rename service are responsible for resetting rules appropriately.

Be particularly careful when modifying rule execution because stateful rules can produce different results depending on execution history.

---

## UI Architecture

UI components are primarily implemented using:

```dart
StatefulWidget
setState()
```

Keep UI state local unless there is a strong reason for moving it elsewhere.

Rule forms expose an `onChanged` callback and emit the current rule as the user edits the form.

When modifying a rule form:

* Keep the form synchronized with its rule model.
* Avoid duplicating rule logic inside the UI.
* Keep transformation behavior inside the rule model.
* Keep file-system operations out of widgets.

---

## Service Layer

Services are located under:

```text
lib/services/
```

Services should contain non-UI operations such as:

* File operations.
* Rule persistence.
* Network/update checks.

Widgets should not directly contain file-system or networking logic when the operation belongs in a service.

---

# 6. Rule Form Contract

Before creating or modifying a rule or rule form, read:

```text
contracts.md
```

This file defines the contract between rule models and their UI forms.

Do not create a new rule form that violates the existing contract.

When adding a new rule, treat the model and form as two parts of the same feature.

---

# 7. Coding Principles

Apply these principles to every change.

## KISS — Keep It Simple

Prefer the simplest solution that correctly solves the problem.

Favor:

* Readability
* Maintainability
* Explicit behavior
* Small changes
* Existing project conventions

Avoid:

* Over-engineering
* Unnecessary abstractions
* Premature optimization
* Frameworks or packages that solve problems the project does not have

If a simple function solves the problem, do not introduce a class hierarchy.

---

## Avoid Unnecessary Design Patterns

Do not introduce design patterns simply because they are considered "best practice."

A pattern should only be introduced when it solves a real problem in this project.

Prefer:

```dart
switch
```

or a straightforward function over introducing a Factory, Strategy, Observer, Repository, or similar abstraction without a concrete need.

---

## Prefer `switch` for Value-Based Branching

When branching based on a single value, prefer a `switch` over a long `if / else if / else` chain.

For example:

```dart
switch (ruleType) {
  case RuleType.findReplace:
    ...
  case RuleType.insert:
    ...
  case RuleType.delete:
    ...
}
```

Use the most idiomatic Dart syntax supported by the project's configured SDK.

---

## Follow Existing Conventions

Before introducing a new approach:

1. Search the repository for existing implementations.
2. Follow the existing convention when practical.
3. Avoid creating multiple ways of doing the same thing.

Consistency is generally more valuable than introducing a theoretically superior approach.

---

# 8. Making Changes

Before modifying code:

1. Identify the files involved.
2. Read the relevant existing implementation.
3. Check related models/services/widgets.
4. Check `contracts.md` when modifying rules or rule forms.
5. Check existing tests.
6. Make the smallest reasonable change.

Do not rewrite unrelated code while implementing a feature or fixing a bug.

Avoid opportunistic refactoring unless it is necessary for the requested change.

---

# 9. Dependencies

Do not add a package unless it provides meaningful functionality that cannot reasonably be implemented with the existing Flutter/Dart APIs or current dependencies.

Before adding a dependency:

1. Check whether the project already provides the required functionality.
2. Consider whether the Dart/Flutter standard library can solve the problem.
3. Consider whether an existing dependency can solve it.
4. Check platform compatibility, particularly Windows desktop support.
5. Consider the maintenance impact.

Avoid adding dependencies for trivial functionality.

After modifying dependencies, run:

```bash
flutter pub get
```

---

# 10. VS Code Workflow

The preferred development workflow is:

### Open the project

Open the repository root in VS Code.

### Get dependencies

```bash
flutter pub get
```

### Check available devices

```bash
flutter devices
```

### Run Windows

```bash
flutter run -d windows
```

For normal development, use VS Code's **Run and Debug** functionality when practical.

The repository's `.vscode/launch.json` should provide convenient Flutter configurations for:

* Debug
* Profile
* Release
* Windows development

If modifying `.vscode/launch.json`, keep the existing configurations intact unless there is a specific reason to change them.

---

# 11. Formatting and Static Analysis

Format Dart code using:

```bash
dart format .
```

Run static analysis with:

```bash
flutter analyze
```

New code should not introduce analyzer errors or warnings.

Do not suppress analyzer warnings merely to make the analyzer pass unless the warning is demonstrably intentional.

---

# 12. Testing

Run all tests with:

```bash
flutter test
```

The current test suite is minimal, but new functionality should include appropriate tests.

### Rule changes

When adding or modifying a rule, add focused tests for:

```dart
Rule.apply(...)
```

Test:

* Normal input.
* Empty input where applicable.
* Boundary cases.
* Invalid input where applicable.
* Interactions with existing behavior when relevant.

### Stateful rules

For `SerializeRule`, test reset behavior as well as normal application behavior.

### UI changes

For meaningful UI changes, update or add widget tests where practical.

Do not rely exclusively on manually running the application when behavior can be tested automatically.

---

# 13. Validation Before Completing a Change

Before considering a change complete, run the appropriate checks.

For most code changes:

```bash
dart format .
flutter analyze
flutter test
```

For Windows-specific changes:

```bash
flutter analyze
flutter test
flutter run -d windows
```

For release/build-related changes:

```bash
flutter build windows --release
```

For MSIX packaging changes:

```bash
dart run msix:create
```

Do not claim that a change works if the relevant validation has not been performed.

If a command cannot be run because of the environment, clearly state that in the final response.

---

# 14. Building

### Windows

```bash
flutter build windows --release
```

### Linux

```bash
flutter build linux --release
```

### macOS

```bash
flutter build macos --release
```

### Windows MSIX

```bash
dart run msix:create
```

Windows is the primary platform, so Windows-specific behavior should receive priority when platform behavior differs.

---

# 15. File Renaming Safety

File renaming is a destructive operation.

When modifying `file_renaming.dart` or rule execution:

* Do not rename files during preview generation.
* Preview operations must only calculate the expected filename.
* Actual file-system changes should happen only during the explicit rename operation.
* Preserve the original file extension behavior unless the feature explicitly changes it.
* Be careful with duplicate filenames.
* Be careful with invalid Windows filenames.
* Consider conflicts where a generated filename already exists.
* Avoid partially completing a batch without handling errors appropriately.

Do not weaken existing safety checks without a clear reason.

---

# 16. Backward Compatibility

Be careful when changing:

* Rule serialization.
* `settings.json`.
* Rule `$type` identifiers.
* Existing rule behavior.
* User settings.
* File-renaming semantics.

Existing users may have saved configurations created by previous versions.

Prefer backward-compatible changes.

If a breaking change is unavoidable, document it clearly and add migration handling where practical.

---

# 17. Error Handling

Errors should be handled at the appropriate layer.

* UI code should present user-facing errors.
* Services should handle service-level failures and provide useful error information.
* Rule models should not display UI messages.
* Do not silently swallow exceptions unless there is a clear reason.

Avoid broad exception handling such as:

```dart
try {
  ...
} catch (_) {}
```

unless ignoring the error is explicitly intentional.

---

# 18. Scope Control

Keep changes focused.

When asked to fix a specific issue:

* Fix the issue.
* Do not rewrite unrelated code.
* Do not rename unrelated variables/files.
* Do not introduce architecture changes without necessity.
* Do not update dependencies unnecessarily.
* Do not change formatting across unrelated files.

If you discover an unrelated issue, mention it rather than silently expanding the scope of the task.

---

# 19. Git and Change Hygiene

Do not modify generated files unless the task specifically requires it.

Avoid committing:

* Build output
* Temporary files
* IDE caches
* Debug artifacts
* Generated files that are normally ignored by Git

Before finishing a task, inspect the changed files and ensure every change is related to the requested work.

Prefer small, logically grouped changes.

---

# 20. Agent Checklist

Before finishing any coding task, verify:

* [ ] The requested behavior has been implemented.
* [ ] Existing architecture and conventions were followed.
* [ ] `contracts.md` was checked when relevant.
* [ ] No unnecessary dependencies were introduced.
* [ ] No unrelated files were changed.
* [ ] Dart code has been formatted.
* [ ] `flutter analyze` passes.
* [ ] Relevant tests pass.
* [ ] New rule behavior has focused tests where appropriate.
* [ ] Windows behavior has been checked for Windows-specific changes.
* [ ] Serialization compatibility has been considered for rule changes.
* [ ] Stateful rule reset behavior has been considered where applicable.
* [ ] No destructive file operations occur during preview.
* [ ] The final response accurately reports what was changed and what validation was performed.

## Final Principle

**Prefer a small, clear, tested change that fits the existing application over a large, clever redesign.**
