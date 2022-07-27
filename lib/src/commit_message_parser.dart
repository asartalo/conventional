import 'package:petitparser/petitparser.dart';

import 'commit_message.dart';
import 'commit_message_footer.dart';
import 'commit_message_header.dart';
import 'parsing_elements.dart';

/// A Parser for Commit Messages
class CommitMessageParser {
  final Parser parser;
  // ignore: public_member_api_docs
  CommitMessageParser()
      : parser = const _CommitMessageGrammarDefinition().build();

  Result parse(String input) {
    return parser.parse(input);
  }
}

class _CommitMessageGrammarDefinition extends GrammarDefinition {
  const _CommitMessageGrammarDefinition();

  @override
  Parser start() => ref0(commit).end();

  Parser<CommitMessage> commit() => (ref0(header) &
              blankLine.map((val) => 'BLANK').optional() &
              ref0(body).optional() &
              blankLine.optional() &
              ref0(footerSection).optional())
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
      (ref0(conventionalHeader) | ref0(regularHeader))
          .map((value) => value as CommitMessageHeader);
  Parser<ConventionalHeader> conventionalHeader() => (ref0(type) &
          ref0(scope).optional().map((value) => value is String ? value : '') &
          char('!').optional().map((value) => value is String) &
          char(':') &
          ref0(description)
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

  Parser type() => ref0(id);
  Parser id() => (letter() & word().star()).flatten();
  Parser scope() =>
      (char('(') & ref0(id).separatedBy(char('-')).plus().flatten() & char(')'))
          .map((values) => values[1]);
  Parser description() => ref0(singleLineString);

  Parser body() => (ref0(footerSection).neg() | newLine).plus().flatten();

  Parser<List<CommitMessageFooter>> footerSection() =>
      (ref0(footer) & endOfInput()).map((items) {
        final list = <CommitMessageFooter>[];
        final itemList = (items.first as List).first as List;
        for (final item in itemList) {
          if (item is CommitMessageFooter) {
            list.add(item);
          }
        }
        return list;
      });

  Parser footer() =>
      ref0(footerLine).separatedBy(newLine, includeSeparators: false).plus();

  Parser<CommitMessageFooter> footerLine() =>
      (ref0(footerToken) & ref0(footerSeparator) & ref0(footerValue)).map(
        (items) => CommitMessageFooter(
          key: items[0] as String,
          value: items[2] as String,
        ),
      );
  Parser footerToken() =>
      string('BREAKING CHANGE') |
      ref0(id).separatedBy(char('-')).plus().flatten();
  Parser footerSeparator() =>
      string(': ', 'no : separator wut') | string(' #', 'no # separator wut');
  Parser footerValue() => ref0(singleLineString);

  Parser singleLineString() => newLine.neg().plus().flatten();
}
