import 'package:conventional/conventional.dart';
import 'package:conventional/src/commit_message_footer.dart';
import 'package:conventional/src/commit_message_parser.dart';
import 'package:test/test.dart';

class _TestData {
  final String description;
  final String input;
  final CommitMessage expected;
  final String? expectedHeader;
  final bool? expectedConventional;

  const _TestData(
    this.description, {
    required this.input,
    required this.expected,
    this.expectedHeader,
    this.expectedConventional,
  });
}

_TestData _t(
  String description, {
  required String input,
  required CommitMessage expected,
  String? expectedHeader,
  bool? expectedConventional,
}) {
  return _TestData(
    description,
    input: input,
    expected: expected,
    expectedHeader: expectedHeader,
    expectedConventional: expectedConventional,
  );
}

void main() {
  group(CommitMessageParser, () {
    final testData = [
      _t(
        'normal commit message',
        input: 'this is just a description',
        expected: CommitMessage(
          description: 'this is just a description',
        ),
        expectedConventional: false,
        expectedHeader: 'this is just a description',
      ),
      _t(
        'conventional feature',
        input: 'feat: it can jump',
        expected: CommitMessage(
          type: 'feat',
          description: 'it can jump',
        ),
        expectedConventional: true,
        expectedHeader: 'feat: it can jump',
      ),
      _t(
        'breaking header',
        input: 'feat!: it can eat',
        expected: CommitMessage(
          type: 'feat',
          description: 'it can eat',
          breaking: true,
        ),
        expectedConventional: true,
        expectedHeader: 'feat!: it can eat',
      ),
      _t(
        'conventional fix with scope',
        input: 'fix(legs): tend to wounds',
        expected: CommitMessage(
          type: 'fix',
          description: 'tend to wounds',
          scope: 'legs',
        ),
        expectedConventional: true,
        expectedHeader: 'fix(legs): tend to wounds',
      ),
      _t(
        'invalid scope format',
        input: 'fix(legs: tend to wounds',
        expected: CommitMessage(
          type: '',
          description: 'fix(legs: tend to wounds',
          scope: '',
        ),
        expectedConventional: false,
        expectedHeader: 'fix(legs: tend to wounds',
      ),
      _t(
        'commit with body',
        input: 'fix: tend to wounds\n\nUse warm water and soap.',
        expected: CommitMessage(
          type: 'fix',
          description: 'tend to wounds',
          body: 'Use warm water and soap.',
        ),
        expectedConventional: true,
      ),
      _t(
        'commit with body improperly formatted',
        input: 'fix: tend to wounds\nUse warm water and soap.',
        expected: CommitMessage(
          type: 'fix',
          description: 'tend to wounds',
          body: 'Use warm water and soap.',
          parsingErrors: ['no-blank-line-before-body'],
        ),
        expectedConventional: false,
      ),
      _t(
        'commit with footer',
        input:
            'fix: foo bar\n\nAuthored-by: John Doe\nBREAKING-CHANGE: break break',
        expected: CommitMessage(
          type: 'fix',
          description: 'foo bar',
          footer: [
            CommitMessageFooter(value: 'John Doe', key: 'Authored-by'),
            CommitMessageFooter(value: 'break break', key: 'BREAKING-CHANGE'),
          ],
        ),
      ),
    ];

    for (final data in testData) {
      group('parsing ${data.description}', () {
        late CommitMessage message;
        setUp(() {
          message = CommitMessage.parse(data.input);
        });

        test('it can be parsed', () {
          expect(message, equals(data.expected));
        });

        if (data.expectedConventional is bool) {
          test('.isConventional is ${data.expectedConventional}', () {
            expect(message.isConventional, data.expectedConventional);
          });
        }
        if (data.expectedHeader is String) {
          test('.header is correct', () {
            expect(message.header.toString(), data.expectedHeader);
          });
        }
      });
    }
  });
}
