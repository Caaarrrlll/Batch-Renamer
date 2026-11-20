import 'dart:io';

import 'package:bulk_renamer/services/file_listing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  final sep = Platform.pathSeparator;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('bulk_renamer_listing');
  });

  tearDown(() async {
    await dir.delete(recursive: true);
  });

  String create(String relative) {
    final file = File('${dir.path}$sep$relative');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(relative);
    return file.path;
  }

  List<String> relative(List<String> paths) =>
      paths.map((p) => p.substring(dir.path.length + 1)).toList()..sort();

  test('keeps files as they are', () async {
    final a = create('a.txt');

    final listing = await FileListingService.expand([a]);

    expect(listing.files, [a]);
    expect(listing.unreadableFolders, isEmpty);
  });

  test('replaces folders with all their files, at any depth', () async {
    create('top${sep}a.txt');
    create('top${sep}sub${sep}b.txt');
    create('top${sep}sub${sep}deeper${sep}c.txt');
    Directory('${dir.path}${sep}top${sep}empty').createSync();

    final listing = await FileListingService.expand(['${dir.path}${sep}top']);

    expect(relative(listing.files), [
      'top${sep}a.txt',
      'top${sep}sub${sep}b.txt',
      'top${sep}sub${sep}deeper${sep}c.txt',
    ]);
  });

  test('mixes files and folders', () async {
    final loose = create('loose.txt');
    create('folder${sep}inside.txt');

    final listing = await FileListingService.expand([
      loose,
      '${dir.path}${sep}folder',
    ]);

    expect(relative(listing.files), ['folder${sep}inside.txt', 'loose.txt']);
  });

  test('does not follow links to folders', () async {
    create('real${sep}a.txt');
    final top = Directory('${dir.path}${sep}top')..createSync();
    try {
      Link('${top.path}${sep}shortcut').createSync('${dir.path}${sep}real');
    } on FileSystemException {
      markTestSkipped('Creating links needs extra permissions here');
      return;
    }

    final listing = await FileListingService.expand([top.path]);

    expect(listing.files, isEmpty);
  });
}
