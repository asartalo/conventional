import 'package:conventional/conventional.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

// These tests are a holdover for when I was still using a custom Version
// parser which is not great.
void main() {
  group('Version', () {
    group('parse and toString()', () {
      final testData = {
        '1.0.0': Version(1, 0, 0),
        '2.3.0': Version(2, 3, 0),
        '4.5.6': Version(4, 5, 6),
        '5.0.0-rc.1': Version(5, 0, 0, pre: 'rc.1'),
        '6.0.0-rc.1+8': Version(6, 0, 0, pre: 'rc.1', build: '8'),
        '7.1.0+20': Version(7, 1, 0, build: '20'),
      };

      testData.forEach((key, value) {
        late Version version;
        setUp(() {
          version = Version.parse(key);
        });

        test('expect "$key" to be parsed', () {
          expect(version, equals(value));
        });

        test('expect "$key" toString() is correct', () {
          expect('$version', equals(key));
        });

        test('primary buildLessVersion("$key") is correct', () {
          expect(
            buildlessVersion(version),
            equals(
              Version.parse(
                '$version'.replaceAll(RegExp(r'\+.+$'), ''),
              ),
            ),
          );
        });
      });
    });
  });
}
