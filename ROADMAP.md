# Roadmap

Known issues and planned work for Bulk Renamer. Tick items off as they land,
and add new ones under the right priority.

Last reviewed: 2026-11-20 (v0.7.5).

## Release and distribution

- [ ] **Sign the Windows installer with a real certificate.**
  Releases are signed with msix's test certificate, so users must trust that
  certificate before the `.msix` installs. Get a code-signing certificate, add
  it as a CI secret, and set `certificate_path` / `certificate_password` in
  `msix_config`. The publisher will change to the certificate's, which
  Windows treats as a different app, so plan one manual reinstall.
- [ ] **Sign and notarise the macOS app.**
  The macOS build is unsigned, so Gatekeeper warns on first launch.
- [ ] **Shrink the macOS download (~215 MB).**
  The artifact is the whole `build/macos/Build/Products/Release/` folder,
  likely including debug symbols. Upload only `bulk_renamer.app`.
- [ ] **Add release notes.**
  GitHub releases are created with an empty description. Set
  `generate_release_notes: true` on `softprops/action-gh-release`, or write
  notes into the tag message.
- [ ] **Decide what to do with tags v0.7.2–v0.7.4.**
  They exist but never produced a release (their builds failed). Leave them
  or delete them, so the tag list matches the releases.

## Reliability

- [ ] **Undo after an app restart.**
  Undo only remembers the last rename while the app is open. Persisting it
  (like the rename journal) would let users undo after closing the app.
- [ ] **Recover a batch interrupted mid-way, not just stranded files.**
  After a crash, startup recovery moves files at temporary names back, but
  files that already got their new name stay renamed, so the batch is left
  half done with no undo. Recording the whole batch in the journal would
  allow a full rollback. See `lib/services/rename_journal.dart`.
- [ ] **Show progress for large folder drops.**
  Dropping a large folder tree lists every file with no progress indicator
  or cancel, and there's no limit on how many files are added.
  See `FileListingService.expand`.

## User interface

- [ ] **Fix rule form rows that overflow at larger text sizes.**
  Rows in the Insert and Clean Up forms overflow by about 40–60 px under the
  wide test font. They fit with normal fonts at normal size, but may
  overflow with a large system text scale. Let them wrap, and remove the
  text-scale workaround in `test/add_rule_dialog_test.dart`.
- [ ] **Count positions in user-perceived characters.**
  Positions in Delete, Insert and Serialize now count Unicode code points,
  so emoji aren't split. Characters built from several code points, such as
  some accented letters, flags and family emoji, still count as more than
  one.

## Testing

- [ ] **Manually test the latest features on each platform.**
  Folder drops, undo, crash recovery and the rules-file overwrite warning
  are covered by automated tests but haven't been tried in the running app.
  Linux and macOS builds haven't been run at all.
- [ ] **Add integration tests for the main flow.**
  Drag-and-drop, the file picker and a full rename are only tested in
  pieces. An `integration_test` run on Windows would cover them end to end.

## Maintenance

- [ ] **Update dependencies.**
  `flutter pub outdated` lists newer versions, including a major update for
  `file_picker` (12 → 13) and `desktop_drop` (0.8 → 0.9). Check the
  changelogs for Windows changes before upgrading.
- [ ] **Bring AGENTS.md up to date.**
  Its repository structure section is missing `file_list.dart`,
  `file_listing.dart`, `rename_journal.dart`, `contracts.md`, this file and
  the newer test files, and it still calls the test suite "minimal".
- [ ] **Decide whether `.serena/` belongs in the repository.**
  It's a local tool's configuration that was committed with other changes.
  Remove it and add it to `.gitignore` unless it's meant to be shared.
- [ ] **Trim the remaining template comments in `pubspec.yaml`.**
