// ignore_for_file: public_member_api_docs
import 'package:petitparser/petitparser.dart';

import 'commit.dart';
import 'commit_author.dart';
import 'commit_message.dart';
import 'parsing_elements.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec'
];

class CommitParser {
  final _CommitLogGrammarParser _parser;

  CommitParser() : _parser = _CommitLogGrammarParser();

  Commit parse(String input) {
    final result = _parser.parse(input);
    if (result is Failure) {
      throw ArgumentError(result.toString());
    }
    return result.value as Commit;
  }
}

class _Meta {
  final DateTime date;
  final CommitAuthor author;
  final Map<String, String> others;

  _Meta({
    required this.date,
    required this.author,
    required this.others,
  });
}

class _CommitMetaGrammarParser {
  final Parser parser;

  _CommitMetaGrammarParser() : parser = _CommitMetaGrammarDefinition().build();

  Result parse(String input) {
    return parser.parse(input);
  }
}

class _CommitMetaGrammarDefinition extends GrammarDefinition {
  @override
  Parser start() => ref0(meta).end();

  Parser<_Meta> meta() =>
      (ref0(authorLine) | ref0(dateLine) | ref0(genericMetaLine))
          .plusSeparated(newLine)
          .map((list) {
        late CommitAuthor author;
        late DateTime date;
        final Map<String, String> others = {};
        for (final val in list.elements) {
          if (val is DateTime) {
            date = val;
          } else if (val is CommitAuthor) {
            author = val;
          } else if (val is List<String>) {
            others[val[0]] = val[1];
          }
        }
        return _Meta(date: date, author: author, others: others);
      });

  Parser genericMetaLine() =>
      (wholeWord & colon & newLine.neg().plus().flatten())
          .map((parsed) => [parsed[0], parsed[1]]);

  Parser<CommitAuthor> authorLine() => (string('Author: ') & ref0(author))
      .map((parsed) => parsed[1] as CommitAuthor);
  Parser<CommitAuthor> author() =>
      (ref0(authorName) & char('<') & ref0(email) & char('>'))
          .map(transformAuthor);
  Parser authorName() => char('<').neg().plus().trim().flatten();
  Parser email() =>
      (char('@').neg().plus() & char('@') & char('>').neg().plus()).flatten();

  Parser<DateTime> dateLine() =>
      (string('Date:') & whitespace().plus() & ref0(date))
          .map((val) => val[2] as DateTime);
  Parser<DateTime> date() => (wholeWord &
          ref0(month) &
          ref0(day) &
          ref0(time) &
          ref0(year) &
          ref0(timezone))
      .map(transformDate);
  Parser month() => wholeWord;
  Parser day() => number;
  Parser time() => (d2 & colon & d2 & colon & d2).trim().flatten();
  Parser year() => d4.trim();
  Parser timezone() => whitespace().neg().plus().flatten();

  CommitAuthor transformAuthor(List<dynamic> parsed) {
    final name = (parsed[0] as String).trim();
    final email = parsed[2] as String;
    return CommitAuthor(name: name, email: email);
  }

  DateTime transformDate(List<dynamic> parsed) {
    final year = parsed[4] as String;
    final month = _zeroPad(_months.indexOf(parsed[1] as String) + 1);
    final day = _zeroPad(int.parse(parsed[2] as String));
    final time = parsed[3] as String;
    final timeZone = parsed[5] as String;
    return DateTime.parse('$year-$month-${day}T$time$timeZone');
  }
}

class _CommitLogGrammarParser {
  final Parser parser;
  _CommitLogGrammarParser() : parser = _CommitLogGrammarDefinition().build();

  Result parse(String input) {
    return parser.parse(input);
  }
}

String _zeroPad(int n) {
  return n < 10 ? '0$n' : '$n';
}

class _CommitLogGrammarDefinition extends GrammarDefinition {
  _CommitLogGrammarDefinition();

  final _CommitMetaGrammarParser _metaParser = _CommitMetaGrammarParser();

  @override
  Parser start() => ref0(log).end();

  Parser log() => (ref0(commitLine) &
          newLine &
          ref0(commitMeta) &
          blankLine &
          ref0(commitMessageSection))
      .map(transformCommit);

  Parser<_Meta> commitMeta() => blankLine.neg().plus().flatten().map((parsed) {
        final result = _metaParser.parse(parsed);
        if (result is Failure) {
          throw ArgumentError(result.message);
        }
        return result.value as _Meta;
      });

  Parser<String> commitLine() =>
      (string('commit ') & ref0(commitId)).map((val) => val[1] as String);
  Parser commitId() => word().plus().flatten();

  Parser<String> commitMessageSection() => ref0(indentedLine)
      .map((value) => (value is List<String>) ? value[1] : '')
      .plusSeparated(newLine)
      .map((list) => list.elements)
      .plus()
      .flatten();

  Parser indentedLine() => ref0(indentedFilledLine) | ref0(indentedBlankLine);

  Parser indentedFilledLine() =>
      ref0(optionalIndentation) & newLine.neg().plus().flatten();
  Parser indentedBlankLine() => ref0(optionalIndentation) & newLine;
  Parser optionalIndentation() => string('    ').optional();

  Commit transformCommit(List<dynamic> parsed) {
    final id = parsed[0] as String;
    final meta = parsed[2] as _Meta;

    final message = CommitMessage.parse(parsed[4] as String);
    return Commit(
        id: id, author: meta.author, date: meta.date, message: message);
  }
}
