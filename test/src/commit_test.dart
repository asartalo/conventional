import 'package:conventional/conventional.dart';
import 'package:test/test.dart';

// ignore_for_file: avoid_print

void main() {
  group('Commit.parse()', () {
    group('successful parsing', () {
      testData.forEach((key, data) {
        test('parses $key correctly', () {
          expect(Commit.parse(data.input), equals(data.output));
        });
      });
    });
  });

  group('Commit.parseCommits()', () {
    late List<Commit> commits;

    setUp(() {
      commits = Commit.parseCommits(testLog);
    });

    test('it parses all logs', () {
      expect(commits.length, equals(6));
    });

    test('it correctly parses logs', () {
      expect(
        commits.first.id,
        equals('fc9d8117b1074c3c965c5c1ccf845d784c026ac7'),
      );
      expect(
        commits.last.id,
        equals('18bf98f5cddfecc69b26285b6edca063f1a8b1ec'),
      );
      expect(
        commits[3].footer.first.toString(),
        endsWith('BREAKING CHANGE: uses null-safety'),
      );
    });
  });
}

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

class _TestData {
  final String input;
  final Commit output;

  const _TestData(this.input, this.output);
}

final Map<String, _TestData> testData = {
  'basic': _TestData(
    '''
commit fc9d8117b1074c3c965c5c1ccf845d784c026ac7
Author: Jane Doe <jane.doe@example.com>
Date:   Mon Feb 8 15:26:09 2021 +0800

    fix: fix release workflow
''',
    Commit(
      id: 'fc9d8117b1074c3c965c5c1ccf845d784c026ac7',
      author: const CommitAuthor(
        name: 'Jane Doe',
        email: 'jane.doe@example.com',
      ),
      date: DateTime.parse('2021-02-08T15:26:09 +0800'),
      type: 'fix',
      description: 'fix release workflow',
    ),
  ),
  'with body and scope': _TestData(
    '''
commit 18bf98f5cddfecc69b26285b6edca063f1a8b1ec
Merge: b457270 dc60e12
Author: Jane Doe <jane.doe@example.com>
Date:   Sat Dec 19 13:28:47 2020 +0800

    ci(workflow): Merge pull request #3 from asartalo/semantic-release

    fixing semantic-release config
''',
    Commit(
      id: '18bf98f5cddfecc69b26285b6edca063f1a8b1ec',
      author: const CommitAuthor(
        name: 'Jane Doe',
        email: 'jane.doe@example.com',
      ),
      date: DateTime.parse('2020-12-19T13:28:47 +0800'),
      type: 'ci',
      scope: 'workflow',
      description: 'Merge pull request #3 from asartalo/semantic-release',
      body: 'fixing semantic-release config',
    ),
  ),
  'with breaking change in body': _TestData(
    '''
commit 43cf9b78f77a0180ad408cb87e8a774a530619ce
Author: Jane Doe <jane.doe@example.com>
Date:   Fri Feb 5 11:56:26 2021 +0800

    feat: null-safety and piechart cache

    - custom piechart code

    BREAKING CHANGE: uses null-safety
''',
    Commit(
      id: '43cf9b78f77a0180ad408cb87e8a774a530619ce',
      author: const CommitAuthor(
        name: 'Jane Doe',
        email: 'jane.doe@example.com',
      ),
      date: DateTime.parse('2021-02-05T11:56:26 +0800'),
      type: 'feat',
      breaking: true,
      description: 'null-safety and piechart cache',
      body: '- custom piechart code',
      footer: [CommitMessageFooter.parse('BREAKING CHANGE: uses null-safety')],
    ),
  ),
  'with breaking indication in description': _TestData(
    '''
commit cf6080079cd96cb4ccc2edca2ba9cacbcfd64704
Author: Jane Doe <jane.doe@example.com>
Date:   Sun Feb 7 12:58:06 2021 +0800

    fix!: try fixing problem with release''',
    Commit(
      id: 'cf6080079cd96cb4ccc2edca2ba9cacbcfd64704',
      author: const CommitAuthor(
        name: 'Jane Doe',
        email: 'jane.doe@example.com',
      ),
      date: DateTime.parse('2021-02-07T12:58:06 +0800'),
      type: 'fix',
      breaking: true,
      description: 'try fixing problem with release',
    ),
  ),
  'with description with wrong format': _TestData(
    '''
commit fc9d8117b1074c3c965c5c1ccf845d784c026ac7
Author: Jane Doe <jane.doe@example.com>
Date:   Mon Feb 8 15:26:09 2021 +0800

    fix fix release workflow
''',
    Commit(
      id: 'fc9d8117b1074c3c965c5c1ccf845d784c026ac7',
      author: const CommitAuthor(
        name: 'Jane Doe',
        email: 'jane.doe@example.com',
      ),
      date: DateTime.parse('2021-02-08T15:26:09 +0800'),
      description: 'fix fix release workflow',
    ),
  ),
};
