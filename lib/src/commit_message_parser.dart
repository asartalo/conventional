import 'package:petitparser/petitparser.dart';

import 'commit_message.dart';
import 'commit_message_footer.dart';
import 'commit_message_header.dart';
import 'parsing_elements.dart';

/// A Parser for Commit Messages
class CommitMessageParser extends GrammarParser {
  // ignore: public_member_api_docs
  CommitMessageParser() : super(const _CommitMessageGrammarDefinition());
}

class _CommitMessageGrammarDefinition extends GrammarDefinition {
  const _CommitMessageGrammarDefinition();

  @override
  Parser start() => ref(commit).end();

  Parser<CommitMessage> commit() => (ref(header) &
              blankLine.map((val) => 'BLANK').optional() &
              ref(body).optional() &
              blankLine.optional() &
              ref(footerSection).optional())
          .map((parsed) {
        final header = parsed[0] as CommitMessageHeader;
        final body = parsed[2];
        final List<String> parsingErrors = [];
        if (header is ConventionalHeader) {
          if (body is String && parsed[1] != 'BLANK') {
            parsingErrors.add('no-blank-line-before-body');
          }
        }

        final List<CommitMessageFooter> footerList =
            parsed[4] != null ? parsed[4] as List<CommitMessageFooter> : [];

        return CommitMessage(
          header: header,
          body: body is String ? body.trim() : '',
          parsingErrors: parsingErrors,
          footer: footerList,
        );
      });

  Parser<CommitMessageHeader> header() =>
      (ref(conventionalHeader) | ref(regularHeader))
          .map((value) => value as CommitMessageHeader);
  Parser<ConventionalHeader> conventionalHeader() => (ref(type) &
          ref(scope).optional().map((value) => value is String ? value : '') &
          char('!').optional().map((value) => value is String) &
          char(':') &
          ref(description)
              .optional()
              .map((value) => value is String ? value : ''))
      .map((value) => ConventionalHeader(
            type: value[0] as String,
            scope: value[1] as String,
            breaking: value[2] as bool,
            description: (value[4] as String).trim(),
          ));
  Parser<RegularHeader> regularHeader() => singleLineString()
      .map((value) => RegularHeader(description: value as String));

  Parser type() => ref(id);
  Parser id() => (letter() & word().star()).flatten();
  Parser scope() =>
      (char('(') & ref(id).separatedBy(char('-')).plus().flatten() & char(')'))
          .map((values) => values[1]);
  Parser description() => ref(singleLineString);

  Parser body() => (ref(footerSection).neg() | newLine).plus().flatten();

  Parser<List<CommitMessageFooter>> footerSection() =>
      (ref(footer) & endOfInput()).map((items) {
        final list = <CommitMessageFooter>[];
        for (final item in items.first.first) {
          if (item is CommitMessageFooter) {
            list.add(item);
          }
        }
        return list;
      });

  Parser footer() =>
      ref(footerLine).separatedBy(newLine, includeSeparators: false).plus();

  Parser<CommitMessageFooter> footerLine() =>
      (ref(footerToken) & ref(footerSeparator) & ref(footerValue)).map(
        (items) => CommitMessageFooter(
          key: items[0] as String,
          value: items[2] as String,
        ),
      );
  Parser footerToken() =>
      string('BREAKING CHANGE') |
      ref(id).separatedBy(char('-')).plus().flatten();
  Parser footerSeparator() =>
      string(': ', 'no : separator wut') | string(' #', 'no # separator wut');
  Parser footerValue() => ref(singleLineString);

  Parser singleLineString() => newLine.neg().plus().flatten();
}
