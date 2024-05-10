import 'package:hatgame/app_version.dart';
import 'package:test/test.dart';

void main() {
  group('versionsCompatible', () {
    test('same version', () {
      expect(versionsCompatible('v1.1-1-aaaa', 'v1.1-1-aaaa'), isTrue);
      expect(versionsCompatible('v1.1-111-aaaa', 'v1.1-111-aaaa'), isTrue);
      expect(versionsCompatible('v1.111-1-aaaa', 'v1.111-1-aaaa'), isTrue);
      expect(versionsCompatible('v111.1-1-aaaa', 'v111.1-1-aaaa'), isTrue);
    });

    test('same modulo suffix', () {
      expect(
          versionsCompatible('v1.1-1-aaaa:debug', 'v1.1-1-aaaa:debug'), isTrue);
      expect(versionsCompatible('v1.1-1-aaaa:debug', 'v1.1-1-aaaa'), isTrue);

      expect(versionsCompatible('v1.1-1-aaaa', 'v1.1-2-aaaa'), isTrue);
      expect(versionsCompatible('v1.1-1-aaaa', 'v1.1-1-bbbb'), isTrue);
      expect(versionsCompatible('v1.1-1-aaaa', 'v1.1-1'), isTrue);
      expect(versionsCompatible('v1.1-1-aaaa', 'v1.1'), isTrue);
    });

    test('different version', () {
      expect(versionsCompatible('v1.1-1-aaaa', 'v1.2-1-aaaa'), isFalse);
      expect(versionsCompatible('v1.1-1-aaaa', 'v2.1-1-aaaa'), isFalse);
    });

    test('bad format', () {
      expect(versionsCompatible('v1.1-1-aaaa', 'bad'), isFalse);
      expect(versionsCompatible('bad', 'bad'), isFalse);
    });
  });
}
