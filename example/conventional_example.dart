import 'package:conventional/conventional.dart';

// ignore_for_file: avoid_print

const testLog = '''
commit fc9d8117b1074c3c965c5c1ccf845d784c026ac7
Author: Jane Doe <jane.doe@example.com>
Date:   Mon Feb 8 15:26:49 2021 +0800

    ci: fix release workflow

commit cf6080079cd96cb4ccc2edca2ba9cacbcfd64704
Author: Jane Doe <jane.doe@example.com>
Date:   Sun Feb 7 12:58:06 2021 +0800

    ci: try fixing problem with release

commit 925fcd38fe8bd2653ea70d67155b8e31082cf4b2
Author: Jane Doe <jane.doe@example.com>
Date:   Fri Feb 5 16:24:38 2021 +0800

    chore: fix analysis errors

    - disabled checking for non null-safe libraries (temporary)
    - annotation for DatabaseLogWrapper

commit 43cf9b78f77a0180ad408cb87e8a774a530619ce
Author: Jane Doe <jane.doe@example.com>
Date:   Fri Feb 5 11:56:26 2021 +0800

    feat: null-safety and piechart cache

    BREAKING CHANGE: uses null-safety

commit e86efaced15f875ae9e11fd0d79b72d85578f79a
Author: Jane Doe <jane.doe@example.com>
Date:   Wed Jan 27 18:20:41 2021 +0800

    chore: wip to null-safety

commit 18bf98f5cddfecc69b26285b6edca063f1a8b1ec
Merge: b457270 dc60e12
Author: Jane Doe <jane.doe@example.com>
Date:   Sat Dec 19 13:28:47 2020 +0800

    ci: Merge pull request #3 from asartalo/semantic-release

    ci: fixing semantic-release config
''';

void main() {
  // Parse commits
  final List<Commit> commits = Commit.parseCommits(testLog);
  final firstCommit = commits.first;
  print(firstCommit.author.name); // "Jane Doe"
  print(firstCommit.author.email); // "jane.doe@example.com"
  print(firstCommit.breaking); // false
  print(firstCommit.type); // "ci"
  print(firstCommit.description); // "fix release workflow"

  // Check if we have releasable commits
  final shouldRelease = hasReleasableCommits(commits);
  print(shouldRelease); // true

  if (shouldRelease) {
    // Write to a changelog file
    writeChangelog(
      commits: commits,
      changelogFilePath: 'CHANGELOG.md',
      version: '1.2.0',
      now: DateTime.now(),
    );
  }
}
