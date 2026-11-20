import 'dart:io';

class FileListing {
  /// Paths of the files to rename.
  final List<String> files;

  /// Folders that could not be read, so their files are missing.
  final List<String> unreadableFolders;

  const FileListing(this.files, this.unreadableFolders);
}

class FileListingService {
  /// Turns dropped or picked [paths] into the files to rename. Files are
  /// kept as-is; folders are replaced by every file inside them, at any
  /// depth. Folders themselves are never included, and links to folders are
  /// not followed, so a link can't pull in files from elsewhere or loop.
  static Future<FileListing> expand(Iterable<String> paths) async {
    final files = <String>[];
    final unreadable = <String>[];

    Future<void> walk(Directory dir) async {
      final List<FileSystemEntity> entries;
      try {
        entries = await dir.list(followLinks: false).toList();
      } on FileSystemException {
        unreadable.add(dir.path);
        return;
      }
      for (final entry in entries) {
        switch (entry) {
          case Directory():
            await walk(entry);
          case File():
            files.add(entry.path);
          case Link():
            // A link to a file is renamed like a file; links to folders
            // are skipped.
            if (await FileSystemEntity.isFile(entry.path)) {
              files.add(entry.path);
            }
          default:
            break;
        }
      }
    }

    for (final path in paths) {
      if (await FileSystemEntity.isDirectory(path)) {
        await walk(Directory(path));
      } else {
        files.add(path);
      }
    }
    return FileListing(files, unreadable);
  }
}
