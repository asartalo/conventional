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

class _Notes extends Equatable {
  final String type;
  final String description;
  final String body;
  final String scope;
  final bool breaking;

  const _Notes({
    required this.type,
    required this.description,
    required this.body,
    required this.scope,
    required this.breaking,
  });

  @override
  List<Object?> get props => [type, description, body, scope, breaking];
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

final _messageRegexp = RegExp(r'\s+(\w+\!?)(\((.+)\))?:\s?(.+)');
_Notes _parseNotes(List<String> lines) {
  final firstLine = lines.removeAt(0);
  final match = _messageRegexp.firstMatch(firstLine);
  String type = '';
  String description = firstLine.trim();
  String scope = '';
  bool breaking = false;
  if (match is RegExpMatch) {
    type = match.group(1)!;
    if (type.endsWith('!')) {
      breaking = true;
      type = type.replaceFirst(RegExp(r'\!$'), '');
    }
    description = match.group(4)!;
    scope = match.group(3) ?? '';
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
  return _Notes(
    type: type,
    description: description,
    body: body,
    scope: scope,
    breaking: breaking,
  );
}

class Commit extends Equatable {
  final String id;
  final CommitAuthor author;
  final DateTime date;
  final String type;
  final bool breaking;
  final String description;
  final String scope;
  final String body;

  @override
  List<Object?> get props => [
        id,
        author,
        date,
        type,
        breaking,
        description,
        scope,
        body,
      ];

  const Commit({
    required this.id,
    required this.author,
    required this.date,
    required this.type,
    required this.description,
    this.breaking = false,
    this.scope = '',
    this.body = '',
  });

  // ignore: prefer_constructors_over_static_methods
  static Commit parse(String str) {
    final lines = str.trim().split('\n');
    if (lines.isEmpty) {
      throw Exception('The commit log "$str" appears to be empty');
    }

    final notes = _parseNotes(_findDescriptionLines(lines));

    return Commit(
      id: _parseId(lines),
      author: _parseAuthor(lines),
      date: _parseDate(lines),
      type: notes.type,
      description: notes.description,
      body: notes.body,
      breaking: notes.breaking,
      scope: notes.scope,
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
