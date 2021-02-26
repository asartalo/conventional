part of '../conventional.dart';

final _idLineRegexp = RegExp(r'commit (\w+)$');
String _parseId(List<String> commitLines) {
  final str = commitLines.first;
  final id = _idLineRegexp.firstMatch(str)?.group(1);
  if (id is String) {
    return id;
  }
  return '';
}

final _authorLineRegexp = RegExp('Author: ([^<]+) <([^>]+)>');
CommitAuthor _parseAuthor(List<String> commitLines) {
  final authorLine = commitLines
      .where((String line) => _authorLineRegexp.hasMatch(line))
      .first;
  final match = _authorLineRegexp.firstMatch(authorLine);

  return CommitAuthor(
    name: match?.group(1) ?? '',
    email: match?.group(2) ?? '',
  );
}

int _parseIntOr(String? str, [int def = 0]) {
  try {
    return int.parse(str?.trim() ?? '');
  } on FormatException {
    return def;
  }
}

String _zeroPad(int n) {
  return n < 10 ? '0$n' : '$n';
}

final _dateLineRegexp =
    RegExp(r'Date:\s+\w+ (\w+) (\d+) (\d+:\d+:\d+) (\d+)(.+)$');
const months = [
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
DateTime _parseDate(List<String> commitLines) {
  final dateLine =
      commitLines.where((String line) => _dateLineRegexp.hasMatch(line)).first;
  final match = _dateLineRegexp.firstMatch(dateLine);
  if (match == null) {
    return DateTime(1, 1, 0);
  }

  final year = match.group(4);
  final month = _zeroPad(months.indexOf(match.group(1) ?? 'Jan') + 1);
  final day = _zeroPad(_parseIntOr(match.group(2), 1));
  final time = match.group(3);
  final timeZone = match.group(5) ?? '';
  return DateTime.parse('$year-$month-${day}T$time$timeZone');
}

List<String> _findDescriptionLines(List<String> original) {
  final List<String> lines = [];
  bool blankLineStart = false;
  for (final line in original) {
    if (blankLineStart) {
      lines.add(line);
    }
    if (line.isEmpty) {
      blankLineStart = true;
    }
  }
  return lines;
}

List<String> _retrieveLines(String str) {
  return str.split('\n');
}

class Commit with EquatableMixin {
  final String id;
  final CommitAuthor author;
  final DateTime date;
  final CommitMessage message;

  @override
  List<Object?> get props => [
        id,
        author,
        date,
        message,
      ];

  bool get breaking => message.breaking;
  bool get isConventional => message.isConventional;
  String get type => message.type;
  String get description => message.description;
  String get scope => message.scope;
  String get body => message.body;
  List<CommitMessageFooter> get footer => message.footer;

  Commit({
    required this.id,
    required this.author,
    required this.date,
    CommitMessage? message,
    String type = '',
    String description = '',
    String header = '',
    bool? breaking,
    String? scope,
    String? body,
    List<CommitMessageFooter>? footer,
  }) : message = message ??
            CommitMessage(
              type: type,
              description: description,
              breaking: breaking,
              scope: scope,
              header: header,
              body: body,
              footer: footer,
            );

  // ignore: prefer_constructors_over_static_methods
  static Commit parse(String str) {
    final lines = _retrieveLines(str);
    if (lines.isEmpty) {
      throw Exception('The commit log "$str" appears to be empty');
    }

    final message =
        CommitMessage.parseCommitLines(_findDescriptionLines(lines));

    return Commit(
      id: _parseId(lines),
      author: _parseAuthor(lines),
      date: _parseDate(lines),
      message: message,
    );
  }

  static List<Commit> parseCommits(String str) {
    final commitSections = str
        .trim()
        .split('\ncommit ')
        .map((String group) => 'commit ${group.trim()}')
        .toList();
    return parseCommitsStringList(commitSections);
  }

  static List<Commit> parseCommitsStringList(List<String> strings) {
    final List<Commit> commits = [];
    for (final group in strings) {
      commits.add(Commit.parse(group));
    }
    return commits;
  }

  @override
  String toString() {
    return '''
id: $id,
author: $author,
date: $date,
$message
''';
  }
}
