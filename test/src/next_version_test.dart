import 'package:conventional/conventional.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

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

class TestItem {
  final String expected;
  final String description;
  final String originalVersion;
  final List<String> commits;
  final bool incrementBuild;
  final bool afterV1;
  final String? pre;

  const TestItem(
    this.description, {
    required this.expected,
    required this.originalVersion,
    required this.commits,
    this.incrementBuild = false,
    this.afterV1 = false,
    this.pre,
  });
}

void main() {
  group(nextVersion, () {
    const originalReleasedVersion = '1.0.1';
    const versionWithBuild = '1.0.1+8';
    const preV1Version = '0.1.1';

    const Map<String, List<TestItem>> testGroups = {
      'with released version': [
        TestItem(
          'it does not change version when there is no need',
          originalVersion: originalReleasedVersion,
          commits: [chore, docs],
          expected: '1.0.1',
        ),
        TestItem(
          'it bumps patch version when there is fix',
          originalVersion: originalReleasedVersion,
          commits: [chore, docs, fix],
          expected: '1.0.2',
        ),
        TestItem(
          'it bumps minor version when there is feature',
          originalVersion: originalReleasedVersion,
          commits: [feat, chore, fix, docs],
          expected: '1.1.0',
        ),
        TestItem(
          'it bumps major version when there is a breaking change',
          originalVersion: originalReleasedVersion,
          commits: [feat, breaking, chore, fix, docs],
          expected: '2.0.0',
        ),
      ],
      'with released version and build number': [
        TestItem(
          'it does not change version when there is no need',
          originalVersion: versionWithBuild,
          commits: [chore, docs],
          expected: '1.0.1+8',
        ),
        TestItem(
          'it retains build number by default',
          originalVersion: versionWithBuild,
          commits: [chore, docs, fix],
          expected: '1.0.2+8',
        ),
      ],
      'with pre-released version': [
        TestItem(
          'it does not change version when there is no need',
          originalVersion: preV1Version,
          commits: [chore, docs],
          expected: preV1Version,
        ),
        TestItem(
          'it bumps patch version when there is fix',
          originalVersion: preV1Version,
          commits: [fix, chore, docs],
          expected: '0.1.2',
        ),
        TestItem(
          'it bumps minor version when there is feature',
          originalVersion: preV1Version,
          commits: [fix, chore, docs, feat],
          expected: '0.1.2',
        ),
        TestItem(
          'it bumps major version when there is a breaking change',
          originalVersion: preV1Version,
          commits: [fix, chore, docs, breaking, feat],
          expected: '0.2.0',
        ),
      ],
      'with pre-V1 and afterV1 flag': [
        TestItem(
          'it does not change version when there is no need',
          originalVersion: preV1Version,
          commits: [chore, docs],
          afterV1: true,
          expected: preV1Version,
        ),
        TestItem(
          'it jumps to version 1 for fix',
          originalVersion: preV1Version,
          commits: [fix, chore, docs],
          afterV1: true,
          expected: '1.0.0',
        ),
        TestItem(
          'it jumps to version 1 for feature',
          originalVersion: preV1Version,
          commits: [fix, chore, docs, feat],
          afterV1: true,
          expected: '1.0.0',
        ),
        TestItem(
          'it jumps to version 1 for breaking change',
          originalVersion: preV1Version,
          commits: [fix, chore, docs, breaking, feat],
          afterV1: true,
          expected: '1.0.0',
        ),
      ],
      'with build number and incrementBuild set': [
        TestItem(
          'it does not change version when there is no need',
          originalVersion: versionWithBuild,
          commits: [chore, docs],
          expected: '1.0.1+8',
          incrementBuild: true,
        ),
        TestItem(
          'it retains build number by default',
          originalVersion: versionWithBuild,
          commits: [chore, docs, fix],
          expected: '1.0.2+9',
          incrementBuild: true,
        ),
        TestItem(
          'it bumps build number for prerelease versions',
          originalVersion: '0.1.2+13',
          commits: [chore, docs, fix, feat],
          expected: '0.1.3+14',
          incrementBuild: true,
        ),
      ],
      'with pre-release versions': [
        TestItem(
          'it retains pre-release information',
          originalVersion: '1.4.0-beta',
          commits: [fix, chore, docs, feat],
          pre: 'beta',
          expected: '1.5.0-beta',
        ),
        TestItem(
          'it adds pre-release information as specified',
          originalVersion: '1.4.0',
          commits: [fix, chore, docs, feat, breaking],
          pre: 'beta',
          expected: '2.0.0-beta',
        ),
      ],
    };

    testGroups.forEach((groupDescription, testItems) {
      group(groupDescription, () {
        for (final testItem in testItems) {
          test(testItem.description, () {
            final newVersion = nextVersion(
              Version.parse(testItem.originalVersion),
              parseCommits(testItem.commits),
              incrementBuild: testItem.incrementBuild,
              afterV1: testItem.afterV1,
              pre: testItem.pre,
            );
            expect(newVersion.toString(), equals(testItem.expected));
          });
        }
      });
    });
  });
}
