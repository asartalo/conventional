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
  return str.trim().split('\n');
}

final _messageRegexp = RegExp(r'^(\w+)(\!?)(\((.+)\))?:\s?(.+)');

class CommitMessage with EquatableMixin {
  final String type;
  final String description;
  // final String header;
  final String scope;
  final String body;
  final bool breaking;
  final bool isConventional;

  const CommitMessage({
    // required this.header,
    required this.type,
    required this.description,
    this.breaking = false,
    this.scope = '',
    this.body = '',
    this.isConventional = true,
  });

  static CommitMessage parse(String str) {
    final lines = str.split('\n');
    return parseCommitLines(lines);
  }

  // ignore: prefer_constructors_over_static_methods
  static CommitMessage parseCommitLines(List<String> lines) {
    final firstLine = lines.removeAt(0);
    final match = _messageRegexp.firstMatch(firstLine.trim());
    String type = '';
    String description = firstLine.trim();
    String scope = '';
    bool breaking = false;
    if (match is RegExpMatch) {
      type = match.group(1)!;
      if (match.group(2) == '!') {
        breaking = true;
      }
      description = match.group(5)!;
      scope = match.group(4) ?? '';
    }
    final body = lines
        .map((String line) {
          if (line.contains('BREAKING')) {
            breaking = true;
          }
          return line.replaceFirst(RegExp('^    '), '');
        })
        .toList()
        .join('\n')
        .trim();
    return CommitMessage(
      type: type,
      description: description,
      body: body,
      scope: scope,
      breaking: breaking,
    );
  }

  @override
  List<Object?> get props =>
      [type, description, scope, body, breaking, isConventional];
}

CommitMessage _asCommit({
  String type = '',
  String description = '',
  bool? breaking,
  String? scope,
  String? body,
  bool? isConventional,
}) {
  return CommitMessage(
    type: type,
    description: description,
    breaking: breaking ?? false,
    scope: scope ?? '',
    body: body ?? '',
    isConventional: isConventional ?? true,
  );
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

  Commit({
    required this.id,
    required this.author,
    required this.date,
    CommitMessage? message,
    String type = '',
    String description = '',
    bool? breaking,
    String? scope,
    String? body,
    bool? isConventional,
  }) : message = message ??
            _asCommit(
              type: type,
              description: description,
              breaking: breaking,
              scope: scope,
              body: body,
              isConventional: isConventional,
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
type: $type,
breaking: $breaking,
scope: ${scope.isNotEmpty ? scope : 'none'},
description: $description,
body: $body,
''';
  }
}
