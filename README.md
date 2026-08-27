# Bulk Renamer

A desktop Flutter application for batch renaming files on **Windows**, **Linux**,
and **macOS**.

## How It Works

Bulk Renamer lets you rename many files at once by building an **ordered list of
rules** and previewing the result before applying it.

1. **Add files** — drag and drop files (or folders) into the lower panel.
2. **Build rules** — click **Add Rule** to pick a rule type and configure it.
   Rules run in order, top to bottom, each one transforming the result of the
   previous rule. Reorder rules with the up/down arrows.
3. **Preview** — the lower panel shows each file's current name next to the
   previewed new name so you can verify the outcome before committing.
4. **Rename** — click **Rename File(s)** to apply the rules to the files on disk.

Rules are persisted automatically to a `settings.json` file in the app's
documents directory (the location is configurable via the **Settings** menu),
so your rule set survives restarts.

### Supported Rule Types

- **Find & Replace** — replace text in filenames, with occurrence, case, whole
  word, and extension options.
- **Insert** — add text as a prefix, suffix, or at a specific position.
- **Delete** — remove characters from a position, by count, or up to a delimiter.
- **Clean Up** — strip bracket content, replace characters, and normalize spaces.
- **Change Case** — capitalize, lowercase, uppercase, invert, or title-case.
- **Regex** — apply a regular expression find/replace.
- **Serialize** — add an incrementing number (start, step, padding, repeat).

## Prerequisites

- Flutter SDK (`^3.12.0`)
- Platform build tools for your target (Visual Studio for Windows, GTK toolchain
  for Linux, Xcode for macOS)

## Getting Started

Install dependencies:

```bash
flutter pub get
```

### Run the App

Run in debug mode (auto-detects the current platform):

```bash
flutter run
```

Run on a specific platform:

```bash
flutter run -d windows
flutter run -d linux
flutter run -d macos
```

### Lint & Test

```bash
flutter analyze
flutter test
```

### Build Release Binaries

```bash
flutter build windows --release
flutter build linux --release
flutter build macos --release
```

Build a Windows installer (MSIX):

```bash
dart run msix:create
```
