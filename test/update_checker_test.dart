import 'package:bulk_renamer/services/update_checker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isNewer', () {
    test('compares each part numerically', () {
      expect(UpdateChecker.isNewer('0.7.4', '0.7.1'), isTrue);
      expect(UpdateChecker.isNewer('0.10.0', '0.9.9'), isTrue);
      expect(UpdateChecker.isNewer('1.0.0', '0.99.99'), isTrue);
      expect(UpdateChecker.isNewer('0.7.1', '0.7.4'), isFalse);
      expect(UpdateChecker.isNewer('0.7.1', '0.7.1'), isFalse);
    });

    test('treats missing parts as zero', () {
      expect(UpdateChecker.isNewer('0.7', '0.7.0'), isFalse);
      expect(UpdateChecker.isNewer('0.7.0', '0.7'), isFalse);
      expect(UpdateChecker.isNewer('0.7.1', '0.7'), isTrue);
    });

    test('ignores pre-release and build suffixes', () {
      expect(UpdateChecker.isNewer('0.8.0-beta', '0.7.4'), isTrue);
      expect(UpdateChecker.isNewer('0.7.4+5', '0.7.4'), isFalse);
    });

    test('rejects versions it cannot read', () {
      expect(
        () => UpdateChecker.isNewer('latest', '0.7.4'),
        throwsA(isA<UpdateCheckException>()),
      );
    });
  });
}
