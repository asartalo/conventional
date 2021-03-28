import 'package:petitparser/petitparser.dart';

import 'commit.dart';
import 'commit_parser.dart';
import 'parsing_elements.dart';

/// Parses the result from `git log --no-decorate`
class CommitLogsParser {
  final CommitParser _commitParser = CommitParser();
  final Parser _commitStart = newLine.optional() & string('commit ');
  late final Parser<List<Commit>> _logsParser;

  // ignore: public_member_api_docs
  CommitLogsParser() {
    _logsParser = (_commitStart & (_commitStart.neg().plus().flatten()))
        .map((parsed) => _commitParser.parse('${parsed[1]}${parsed[2]}'))
        .plus()
        .end();
  }

  /// Parse commit logs
  ///
  /// The value of [input] should be what should appear from doing
  /// `git log --no decorate`
  List<Commit> parse(String input) {
    final result = _logsParser.parse(input);
    if (result is Failure) {
      throw ArgumentError(result.toString());
    }
    return result.value;
  }
}
