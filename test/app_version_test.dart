import 'package:hatgame/app_version.dart';
import 'package:test/test.dart';

void main() {
  group('versionsCompatibile', () {
    test('same version', () {
      expect(versionsCompatibile('v1.1-1-aaaa', 'v1.1-1-aaaa'), isTrue);
      expect(versionsCompatibile('v1.1-111-aaaa', 'v1.1-111-aaaa'), isTrue);
      expect(versionsCompatibile('v1.111-1-aaaa', 'v1.111-1-aaaa'), isTrue);
      expect(versionsCompatibile('v111.1-1-aaaa', 'v111.1-1-aaaa'), isTrue);
    });

    test('same modulo suffix', () {
      expect(versionsCompatibile('v1.1-1-aaaa:debug', 'v1.1-1-aaaa:debug'),
          isTrue);
      expect(versionsCompatibile('v1.1-1-aaaa:debug', 'v1.1-1-aaaa'), isTrue);

      expect(versionsCompatibile('v1.1-1-aaaa', 'v1.1-2-aaaa'), isTrue);
      expect(versionsCompatibile('v1.1-1-aaaa', 'v1.1-1-bbbb'), isTrue);
      expect(versionsCompatibile('v1.1-1-aaaa', 'v1.1-1'), isTrue);
      expect(versionsCompatibile('v1.1-1-aaaa', 'v1.1'), isTrue);
    });

    test('different version', () {
      expect(versionsCompatibile('v1.1-1-aaaa', 'v1.2-1-aaaa'), isFalse);
      expect(versionsCompatibile('v1.1-1-aaaa', 'v2.1-1-aaaa'), isFalse);
    });

    test('bad format', () {
      expect(versionsCompatibile('v1.1-1-aaaa', 'bad'), isFalse);
      expect(versionsCompatibile('bad', 'bad'), isFalse);
    });
  });
}
