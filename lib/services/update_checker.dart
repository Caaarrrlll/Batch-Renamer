import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;

  UpdateInfo({
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
  });
}

class UpdateCheckException implements Exception {
  final String message;

  const UpdateCheckException(this.message);

  @override
  String toString() => message;
}

class UpdateChecker {
  static const _repo = 'Caaarrrlll/Batch-Renamer';

  /// Returns the newer release, or null if this version is up to date.
  /// Throws [UpdateCheckException] if the check itself fails.
  static Future<UpdateInfo?> check() async {
    final info = await PackageInfo.fromPlatform();

    final http.Response response;
    try {
      response = await http
          .get(
            Uri.parse('https://api.github.com/repos/$_repo/releases/latest'),
            headers: {
              'Accept': 'application/vnd.github.v3+json',
              'User-Agent': 'BulkRenamer',
            },
          )
          .timeout(const Duration(seconds: 15));
    } on Exception catch (e) {
      throw UpdateCheckException('Could not reach GitHub: $e');
    }
    if (response.statusCode != 200) {
      throw UpdateCheckException(
        'GitHub returned status ${response.statusCode}',
      );
    }

    final String tag;
    final String url;
    final String notes;
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      tag = data['tag_name'] as String;
      url = data['html_url'] as String;
      notes = data['body'] as String? ?? '';
    } on FormatException {
      throw const UpdateCheckException('GitHub sent an unexpected response');
    } on TypeError {
      throw const UpdateCheckException('GitHub sent an unexpected response');
    }

    final latest = tag.startsWith('v') ? tag.substring(1) : tag;
    if (!isNewer(latest, info.version)) return null;

    return UpdateInfo(
      latestVersion: latest,
      downloadUrl: url,
      releaseNotes: notes,
    );
  }

  /// Whether version [latest] is newer than [current]. Only the numeric
  /// `major.minor.patch` part is compared; suffixes like `-beta` or `+3`
  /// are ignored.
  static bool isNewer(String latest, String current) {
    final l = _parse(latest);
    final c = _parse(current);
    for (var i = 0; i < l.length || i < c.length; i++) {
      final a = i < l.length ? l[i] : 0;
      final b = i < c.length ? c[i] : 0;
      if (a != b) return a > b;
    }
    return false;
  }

  static List<int> _parse(String version) {
    final core = version.split(RegExp(r'[-+]')).first;
    final parts = core.split('.').map(int.tryParse).toList();
    if (parts.isEmpty || parts.contains(null)) {
      throw UpdateCheckException('Unrecognised version "$version"');
    }
    return parts.cast<int>();
  }
}
