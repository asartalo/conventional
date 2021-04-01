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

class _CommitMetaGrammarParser extends GrammarParser {
  _CommitMetaGrammarParser() : super(_CommitMetaGrammarDefinition());
}

class _CommitMetaGrammarDefinition extends GrammarDefinition {
  @override
  Parser start() => ref(meta).end();

  Parser<_Meta> meta() =>
      (ref(authorLine) | ref(dateLine) | ref(genericMetaLine))
          .separatedBy(newLine, includeSeparators: false)
          .map((List<dynamic> parsed) {
        late CommitAuthor author;
        late DateTime date;
        final Map<String, String> others = {};
        for (final val in parsed) {
          if (val is DateTime) {
            date = val;
          } else if (val is CommitAuthor) {
            author = val;
          } else {
            others[val[0] as String] = val[1] as String;
          }
        }
        return _Meta(date: date, author: author, others: others);
      });

  Parser genericMetaLine() =>
      (wholeWord & colon & newLine.neg().plus().flatten())
          .map((parsed) => [parsed[0], parsed[1]]);

  Parser<CommitAuthor> authorLine() => (string('Author: ') & ref(author))
      .map((parsed) => parsed[1] as CommitAuthor);
  Parser<CommitAuthor> author() =>
      (ref(authorName) & char('<') & ref(email) & char('>'))
          .map(transformAuthor);
  Parser authorName() => char('<').neg().plus().trim().flatten();
  Parser email() =>
      (char('@').neg().plus() & char('@') & char('>').neg().plus()).flatten();

  Parser<DateTime> dateLine() =>
      (string('Date:') & whitespace().plus() & ref(date))
          .map((val) => val[2] as DateTime);
  Parser<DateTime> date() => (wholeWord &
          ref(month) &
          ref(day) &
          ref(time) &
          ref(year) &
          ref(timezone))
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

class _CommitLogGrammarParser extends GrammarParser {
  _CommitLogGrammarParser() : super(_CommitLogGrammarDefinition());
}

String _zeroPad(int n) {
  return n < 10 ? '0$n' : '$n';
}

class _CommitLogGrammarDefinition extends GrammarDefinition {
  _CommitLogGrammarDefinition();

  final _CommitMetaGrammarParser _metaParser = _CommitMetaGrammarParser();

  @override
  Parser start() => ref(log).end();

  Parser log() => (ref(commitLine) &
          newLine &
          ref(commitMeta) &
          blankLine &
          ref(commitMessageSection))
      .map(transformCommit);

  Parser<_Meta> commitMeta() => blankLine.neg().plus().flatten().map((parsed) {
        final result = _metaParser.parse(parsed);
        if (result is Failure) {
          throw ArgumentError(result.message);
        }
        return result.value as _Meta;
      });

  Parser<String> commitLine() =>
      (string('commit ') & ref(commitId)).map((val) => val[1] as String);
  Parser commitId() => word().plus().flatten();

  Parser<String> commitMessageSection() => ref(indentedLine)
      .map((value) => value[1] as String)
      .separatedBy(newLine, includeSeparators: true)
      .plus()
      .flatten();

  Parser indentedLine() => ref(indentedFilledLine) | ref(indentedBlankLine);

  Parser indentedFilledLine() =>
      ref(optionalIndentation) & newLine.neg().plus().flatten();
  Parser indentedBlankLine() => ref(optionalIndentation) & newLine;
  Parser optionalIndentation() => string('    ').optional();

  Commit transformCommit(List<dynamic> parsed) {
    final id = parsed[0] as String;
    final meta = parsed[2] as _Meta;

    final message = CommitMessage.parse(parsed[4] as String);
    return Commit(
        id: id, author: meta.author, date: meta.date, message: message);
  }
}
