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
DateTime _parseDate(List<String> commitLines) {
  final dateLine =
      commitLines.where((String line) => _dateLineRegexp.hasMatch(line)).first;
  final match = _dateLineRegexp.firstMatch(dateLine);
  if (match == null) {
    return DateTime(1, 1, 0);
  }

  final year = match.group(4);
  final month = _zeroPad(_months.indexOf(match.group(1) ?? 'Jan') + 1);
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

/// Represents a git commit item.
class Commit with EquatableMixin {
  /// Represents the commit ID.
  ///
  /// Usually a SHA-1 hash (or SHA-256 if [it's implemented](https://git-scm.com/docs/hash-function-transition/).)
  final String id;

  /// The author of the commit
  final CommitAuthor author;

  /// When the commit was made
  final DateTime date;

  /// The commit message
  final CommitMessage message;

  @override
  List<Object?> get props => [
        id,
        author,
        date,
        message,
      ];

  /// See [CommitMessage.breaking]
  bool get breaking => message.breaking;

  /// See [CommitMessage.isConventional]
  bool get isConventional => message.isConventional;

  /// See [CommitMessage.type]
  String get type => message.type;

  /// See [CommitMessage.description]
  String get description => message.description;

  /// See [CommitMessage.scope]
  String get scope => message.scope;

  /// See [CommitMessage.body]
  String get body => message.body;

  /// See [CommitMessage.header]
  String get header => message.header;

  /// See [CommitMessage.footer]
  List<CommitMessageFooter> get footer => message.footer;

  /// Create a Commit
  ///
  /// If supplied with [message], will use that, else will create a [message]
  /// based on the supplied [type], [description], [header], [breaking],
  /// [scope], [body], and [footer].
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

  /// Parses a commit log item as returned from a `git log` item.
  ///
  /// Typical log item would be:
  ///
  /// ```
  /// commit 40f4x751f83770a4f681c2b40c2d90f33e658d2a
  /// Author: Jane Doe <jane.doe@example.com>
  /// Date:   Tue Nov 24 11:49:57 2020 +0100
  ///
  ///     Review page setup
  /// ```
  ///
  /// Will throw an Exception if [logItem] is empty.
  // ignore: prefer_constructors_over_static_methods
  static Commit parse(String logItem) {
    final lines = _retrieveLines(logItem);
    if (lines.isEmpty) {
      throw Exception('The commit log "$logItem" appears to be empty');
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

  /// Creates a list of [Commit]s from a `git log` output
  ///
  /// This differs from [Commit.parse] as the [logOutput] expects multiple git
  /// log items.
  ///
  /// See also [Commit.parse].
  static List<Commit> parseCommits(String logOutput) {
    final commitSections = logOutput
        .trim()
        .split('\ncommit ')
        .map((String group) => 'commit ${group.trim()}')
        .toList();
    return parseCommitsStringList(commitSections);
  }

  /// Creates a list of [Commit]s from git log items as list
  ///
  /// See [Commit.parseCommits] and [Commit.parse].
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
