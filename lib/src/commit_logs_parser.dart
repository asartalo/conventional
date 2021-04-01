import 'commit.dart';
import 'commit_parser.dart';

/// Parses the result from `git log --no-decorate`
class CommitLogsParser {
  final CommitParser _commitParser = CommitParser();

  /// Parse commit logs
  ///
  /// The value of [input] should be what should appear from doing
  /// `git log --no decorate`
  List<Commit> parse(String input) {
    final splitted = input.trim().split(RegExp(r'[\r\n]+commit '));
    final List<Commit> list = [];
    for (var i = 0; i < splitted.length; i++) {
      var section = splitted[i].trim();
      if (!section.startsWith('commit ')) {
        section = 'commit $section';
      }
      list.add(_commitParser.parse(section));
    }
    return list;
  }
}
