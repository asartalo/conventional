import 'package:conventional/conventional.dart';
import 'package:test/test.dart';
import 'package:pub_semver/pub_semver.dart';

const chore = '''
commit fc9d8117b1074c3c965c5c1ccf845d784c026ac7
Author: Jane Doe <jane.doe@example.com>
Date:   Mon Feb 8 15:26:49 2021 +0800

    chore: clean up
''';

const docs = '''
commit fc9d8117b1074c3c965c5c1ccf845d784c026ac7
Author: Jane Doe <jane.doe@example.com>
Date:   Mon Feb 8 15:26:49 2021 +0800

    docs: you and me
''';

const fix = '''
commit cf6080079cd96cb4ccc2edca2ba9cacbcfd64704
Author: Jane Doe <jane.doe@example.com>
Date:   Sun Feb 7 12:58:06 2021 +0800

    fix: plug holes
''';

const feat = '''
commit 925fcd38fe8bd2653ea70d67155b8e31082cf4b2
Author: Jane Doe <jane.doe@example.com>
Date:   Fri Feb 5 16:24:38 2021 +0800

    feat: it jumps
''';

const breaking = '''
commit 43cf9b78f77a0180ad408cb87e8a774a530619ce
Author: Jane Doe <jane.doe@example.com>
Date:   Fri Feb 5 11:56:26 2021 +0800

    feat!: null-safety
''';

List<Commit> parseCommits(List<String> commitList) {
  return commitList.map((String str) => Commit.parse(str)).toList();
}

void main() {
  group(nextVersion, () {
    group('with released version', () {
      final originalVersion = Version.parse('1.0.1+8');

      test('it does not change version when there is no need', () {
        final newVersion =
            nextVersion(originalVersion, parseCommits([chore, docs]));

        expect(newVersion.toString(), equals('1.0.1+8'));
      });

      test('it bumps patch version when there is fix', () {
        final newVersion =
            nextVersion(originalVersion, parseCommits([chore, docs, fix]));

        expect(newVersion.toString(), equals('1.0.2+8'));
      });

      test('it bumps minor version when there is feature', () {
        final newVersion = nextVersion(
            originalVersion, parseCommits([chore, docs, fix, feat]));

        expect(newVersion.toString(), equals('1.1.0+8'));
      });

      test('it bumps major version when there is a breaking change', () {
        final newVersion = nextVersion(
            originalVersion, parseCommits([chore, docs, fix, feat, breaking]));

        expect(newVersion.toString(), equals('2.0.0+8'));
      });
    });

    group('with pre-released version', () {
      final originalVersion = Version.parse('0.1.1+8');

      test('it does not change version when there is no need', () {
        final newVersion =
            nextVersion(originalVersion, parseCommits([chore, docs]));

        expect(newVersion.toString(), equals('0.1.1+8'));
      });

      test('it bumps patch version when there is fix', () {
        final newVersion =
            nextVersion(originalVersion, parseCommits([chore, docs, fix]));

        expect(newVersion.toString(), equals('0.1.2+8'));
      });

      test('it bumps minor version when there is feature', () {
        final newVersion = nextVersion(
            originalVersion, parseCommits([chore, docs, fix, feat]));

        expect(newVersion.toString(), equals('0.1.2+8'));
      });

      test('it bumps major version when there is a breaking change', () {
        final newVersion = nextVersion(
            originalVersion, parseCommits([chore, docs, fix, feat, breaking]));

        expect(newVersion.toString(), equals('0.2.0+8'));
      });
    });
  });
}
