import 'dart:io';

import 'package:bulk_renamer/models/rule.dart';

/// One file in a [RenamePlan].
class RenamePlanEntry {
  final String oldPath;
  final String oldName;
  final String newName;
  final String newPath;

  /// Why this rename is not allowed, or null when it is safe.
  final String? problem;

  const RenamePlanEntry({
    required this.oldPath,
    required this.oldName,
    required this.newName,
    required this.newPath,
    this.problem,
  });

  bool get changed => newName != oldName;
}

/// The calculated result of applying rules to a batch of files.
///
/// Building a plan never touches the file system except to check whether
/// target names already exist.
class RenamePlan {
  final List<RenamePlanEntry> entries;
  final bool caseInsensitive;

  const RenamePlan(this.entries, {required this.caseInsensitive});

  Iterable<RenamePlanEntry> get changes => entries.where((e) => e.changed);

  Iterable<RenamePlanEntry> get problems =>
      entries.where((e) => e.problem != null);

  bool get hasProblems => problems.isNotEmpty;

  String key(String path) => caseInsensitive ? path.toLowerCase() : path;
}

class RenameFailure {
  final String path;
  final String message;

  const RenameFailure(this.path, this.message);
}

class RenameResult {
  /// The new path of each renamed file, keyed by its old path.
  final Map<String, String> moves;
  final List<RenameFailure> failures;

  const RenameResult(this.moves, this.failures);

  int get renamed => moves.length;
  int get failed => failures.length;
}

class FileRenamingService {
  static final _windowsInvalidChars = RegExp(r'[<>:"/\\|?*\x00-\x1F]');
  static final _windowsReservedNames = RegExp(
    r'^(CON|PRN|AUX|NUL|COM[0-9]|LPT[0-9])$',
    caseSensitive: false,
  );

  /// Calculates the new name of every file and checks each rename for
  /// problems. All names are calculated synchronously, so stateful rules
  /// such as [SerializeRule] cannot be reset part-way through a batch.
  static RenamePlan plan(
    List<String> paths,
    List<Rule> rules, {
    bool? windowsNames,
  }) {
    final windows = windowsNames ?? Platform.isWindows;

    for (final rule in rules) {
      rule.reset();
    }

    final sep = Platform.pathSeparator;
    final names = <({String oldPath, String newName})>[];
    for (final oldPath in paths) {
      var newName = oldPath.split(sep).last;
      for (final rule in rules) {
        newName = rule.apply(newName);
      }
      names.add((oldPath: oldPath, newName: newName));
    }
    return _check(names, windows: windows, checkNames: true);
  }

  /// Plans undoing a previous rename: each file in [moves] (old path to new
  /// path, as in [RenameResult.moves]) goes back to its old name. The undo
  /// gets the same checks as any rename, so it never overwrites a file that
  /// has since taken an old name.
  static RenamePlan planUndo(Map<String, String> moves) {
    final sep = Platform.pathSeparator;
    return _check(
      [
        for (final MapEntry(key: oldPath, value: newPath) in moves.entries)
          (oldPath: newPath, newName: oldPath.split(sep).last),
      ],
      windows: Platform.isWindows,
      // The old names were valid names on disk already.
      checkNames: false,
    );
  }

  /// Checks each rename of a file at `oldPath` to `newName` in the same
  /// folder for problems.
  static RenamePlan _check(
    List<({String oldPath, String newName})> names, {
    required bool windows,
    required bool checkNames,
  }) {
    final caseInsensitive = Platform.isWindows || Platform.isMacOS;
    String key(String path) => caseInsensitive ? path.toLowerCase() : path;
    final sep = Platform.pathSeparator;
    final raw = [
      for (final n in names)
        (
          oldPath: n.oldPath,
          oldName: n.oldPath.split(sep).last,
          newName: n.newName,
        ),
    ];

    String newPathOf(String oldPath, String newName) =>
        '${File(oldPath).parent.path}$sep$newName';

    // Paths that will be vacated during the rename, and how many files
    // want each target path.
    final movingSources = <String>{};
    final targetCounts = <String, int>{};
    for (final r in raw) {
      if (r.newName == r.oldName) continue;
      movingSources.add(key(r.oldPath));
      final target = key(newPathOf(r.oldPath, r.newName));
      targetCounts[target] = (targetCounts[target] ?? 0) + 1;
    }

    // Names already on disk, listed once per folder rather than checking
    // every target separately.
    final existingByDir = <String, Set<String>?>{};
    bool exists(String path) {
      final dir = File(path).parent.path;
      final names = existingByDir.putIfAbsent(dir, () {
        try {
          return {
            for (final e in Directory(dir).listSync(followLinks: false))
              key(e.path.split(sep).last),
          };
        } on PathNotFoundException {
          return {}; // The folder is gone, so nothing in it exists.
        } on FileSystemException {
          return null; // Can't list it; check each path instead.
        }
      });
      return names != null
          ? names.contains(key(path.split(sep).last))
          : FileSystemEntity.typeSync(path, followLinks: false) !=
                FileSystemEntityType.notFound;
    }

    final entries = <RenamePlanEntry>[];
    for (final r in raw) {
      final newPath = newPathOf(r.oldPath, r.newName);
      String? problem;
      if (r.newName != r.oldName) {
        final target = key(newPath);
        problem = checkNames
            ? nameProblem(r.newName, oldName: r.oldName, windows: windows)
            : null;
        if (problem == null && targetCounts[target]! > 1) {
          problem = 'Another file would get the same name';
        }
        // A target that another file in the batch is moving away from is
        // fine; anything else already on disk would be overwritten.
        if (problem == null &&
            !movingSources.contains(target) &&
            exists(newPath)) {
          problem = 'A file with this name already exists';
        }
      }
      entries.add(
        RenamePlanEntry(
          oldPath: r.oldPath,
          oldName: r.oldName,
          newName: r.newName,
          newPath: newPath,
          problem: problem,
        ),
      );
    }

    return RenamePlan(entries, caseInsensitive: caseInsensitive);
  }

  /// Returns why [name] cannot be used as a file name, or null if it can.
  static String? nameProblem(
    String name, {
    required String oldName,
    required bool windows,
  }) {
    if (name.trim().isEmpty) return 'Name is empty';
    if (name.lastIndexOf('.') == 0 && !oldName.startsWith('.')) {
      return 'Name would be only an extension';
    }
    if (name == '.' || name == '..') return 'Name is not allowed';
    if (name.contains('/') || name.contains('\x00')) {
      return 'Name contains an invalid character';
    }
    if (windows) {
      if (_windowsInvalidChars.hasMatch(name)) {
        return 'Name contains a character Windows does not allow';
      }
      if (name.endsWith('.') || name.endsWith(' ')) {
        return 'Windows does not allow names ending in a space or dot';
      }
      final base = name.split('.').first.trimRight();
      if (_windowsReservedNames.hasMatch(base)) {
        return '"$base" is a reserved name on Windows';
      }
    }
    return null;
  }

  /// Performs the renames in [plan]. Throws [StateError] if the plan has
  /// problems; callers must check [RenamePlan.hasProblems] first.
  ///
  /// Files whose current path is the target of another rename in the batch
  /// are first moved to a temporary name, so chained renames (a→b, b→c) and
  /// swaps never overwrite each other. Existing files are never overwritten.
  static Future<RenameResult> execute(RenamePlan plan) async {
    if (plan.hasProblems) {
      throw StateError('Cannot rename: the plan has problems');
    }

    final changes = plan.changes.toList();
    final targets = changes.map((e) => plan.key(e.newPath)).toSet();
    final current = <RenamePlanEntry, String>{
      for (final e in changes) e: e.oldPath,
    };
    final stamp = DateTime.now().microsecondsSinceEpoch;

    // Phase 1: move files out of the way of other renames in the batch.
    var tempIndex = 0;
    for (final e in changes) {
      final source = plan.key(e.oldPath);
      if (!targets.contains(source) || plan.key(e.newPath) == source) {
        continue;
      }
      final temp = '${e.oldPath}.bulk-renamer-$stamp-${tempIndex++}.tmp';
      try {
        await _move(e.oldPath, temp);
        current[e] = temp;
      } on FileSystemException catch (error) {
        // Undo phase 1 and stop before any file gets its new name.
        final failures = [RenameFailure(e.oldPath, _describe(error))];
        for (final moved in changes) {
          final from = current[moved]!;
          if (from == moved.oldPath) continue;
          try {
            await _move(from, moved.oldPath);
          } on FileSystemException catch (undoError) {
            failures.add(
              RenameFailure(
                moved.oldPath,
                'Left at temporary name "$from": ${_describe(undoError)}',
              ),
            );
          }
        }
        return RenameResult(const {}, failures);
      }
    }

    // Phase 2: give every file its new name.
    final renamed = <String, String>{};
    final failures = <RenameFailure>[];
    for (final e in changes) {
      final from = current[e]!;
      try {
        if (plan.key(from) != plan.key(e.newPath) &&
            await FileSystemEntity.type(e.newPath, followLinks: false) !=
                FileSystemEntityType.notFound) {
          throw FileSystemException(
            'A file with this name already exists',
            e.newPath,
          );
        }
        await _move(from, e.newPath);
        renamed[e.oldPath] = e.newPath;
      } on FileSystemException catch (error) {
        var message = _describe(error);
        if (from != e.oldPath) {
          message = await _restore(from, e.oldPath, message);
        }
        failures.add(RenameFailure(e.oldPath, message));
      }
    }

    return RenameResult(renamed, failures);
  }

  /// Moves a file back from its temporary name after a failed rename,
  /// without overwriting anything that has since taken its original name.
  static Future<String> _restore(
    String temp,
    String original,
    String message,
  ) async {
    if (await FileSystemEntity.type(original, followLinks: false) !=
        FileSystemEntityType.notFound) {
      return '$message. File was left at "$temp"';
    }
    try {
      await _move(temp, original);
      return message;
    } on FileSystemException catch (error) {
      return '$message. File was left at "$temp": ${_describe(error)}';
    }
  }

  static Future<void> _move(String from, String to) async {
    if (await FileSystemEntity.isDirectory(from)) {
      await Directory(from).rename(to);
    } else {
      await File(from).rename(to);
    }
  }

  static String _describe(FileSystemException error) =>
      error.osError?.message.trim().isNotEmpty == true
      ? error.osError!.message.trim()
      : error.message;
}
