part of '../conventional.dart';

final _messageRegexp = RegExp(r'^(\w+)(\!?)(\((.+)\))?:(.*)');

enum CommitMessageParsingErrors { eff }

class _PartialHeaderResult {
  bool isHeader = false;
  bool breaking = false;
  String description = '';
  String indentation = '';
  String type = '';
  String scope = '';
  String header = '';
}

final _indentRegexp = RegExp(r'^(\s*)(\S.*)\s*$');
_PartialHeaderResult _parseHeader(String headerLine) {
  final result = _PartialHeaderResult();
  final headerMatch = _indentRegexp.firstMatch(headerLine);
  if (headerMatch is RegExpMatch) {
    result.header = headerMatch.group(2)!;
    result.indentation = headerMatch.group(1)!;

    final match = _messageRegexp.firstMatch(result.header);
    if (match is RegExpMatch) {
      result.type = match.group(1)!;
      if (match.group(2) == '!') {
        result.breaking = true;
      }
      result.description = match.group(5)!.trim();
      result.scope = match.group(4) ?? '';
    } else {
      result.description = result.header;
    }
  }
  return result;
}

final _keyRegExp = RegExp(
    r'^(BREAKING|BREAKING CHANGE|BREAKING-CHANGE|[A-Za-z][A-Za-z\-]*[A-Za-z])$');
final _footerRegexp = RegExp(
    r'^(BREAKING|BREAKING CHANGE|BREAKING-CHANGE|[A-Za-z][A-Za-z\-]*[A-Za-z]): (.+)');

const _breakingKeys = <String>{
  'BREAKING',
  'BREAKING-CHANGE',
  'BREAKING CHANGE',
};

class CommitMessageFooter with EquatableMixin {
  final String key;
  final String value;

  bool get isValid => _keyRegExp.hasMatch(key) && value.isNotEmpty;
  bool get breaking => _breakingKeys.contains(key);

  CommitMessageFooter({this.key = '', required this.value});

  static bool looksLikeFooter(String str) {
    return _footerRegexp.firstMatch(str) is RegExpMatch;
  }

  // ignore: prefer_constructors_over_static_methods
  static CommitMessageFooter parse(String str) {
    final match = _footerRegexp.firstMatch(str);
    if (match is RegExpMatch) {
      return CommitMessageFooter(
        key: match.group(1)!,
        value: match.group(2)!,
      );
    }
    return CommitMessageFooter(value: str);
  }

  @override
  List<Object> get props => [key, value];

  @override
  String toString() {
    return key.isEmpty ? value : '$key: $value';
  }
}

class CommitMessage with EquatableMixin {
  final String _header;
  final String type;
  final String description;
  final String scope;
  final String body;
  final bool breaking;
  final List<CommitMessageFooter> footer;
  final List<String> _parsingErrors;

  bool get isConventional =>
      type.isNotEmpty && description.isNotEmpty & _parsingErrors.isEmpty;

  String get header {
    if (_header.isNotEmpty) {
      return _header;
    }
    if (isConventional) {
      return scope.isEmpty
          ? '$type: $description'
          : '$type($scope): $description';
    }
    return description;
  }

  CommitMessage({
    required this.type,
    required this.description,
    String? header,
    bool? breaking,
    String? scope,
    String? body,
    List<CommitMessageFooter>? footer,
    List<String>? parsingErrors,
  })  : breaking = breaking ?? false,
        scope = scope ?? '',
        body = body ?? '',
        _header = header ?? '',
        footer = footer ?? const [],
        _parsingErrors = parsingErrors ?? const [];

  static CommitMessage parse(String str) {
    final lines = str.split('\n');
    return parseCommitLines(lines);
  }

  // ignore: prefer_constructors_over_static_methods
  static CommitMessage parseCommitLines(List<String> lines) {
    final List<String> bodyLines = [];
    var breaking = false;
    var parsedHeader = _PartialHeaderResult();

    var headerLineFound = false;
    var indentation = '';
    final List<String> parsingErrors = [];
    final List<CommitMessageFooter> footerItems = [];
    for (final line in lines) {
      if (!headerLineFound) {
        if (line.trim().isEmpty) {
          // Skip empty lines before header
          continue;
        }
        headerLineFound = true;
        parsedHeader = _parseHeader(line);
        indentation = parsedHeader.indentation;
        breaking = parsedHeader.breaking;
      } else {
        final trimmedLine = line.replaceFirst(indentation, '');
        bodyLines.add(trimmedLine);
      }
    }

    if (bodyLines.isNotEmpty) {
      // Go through the body lines starting from the bottom
      var bodyFound = false;
      var notEmptyLineFound = false;
      for (var i = bodyLines.length - 1; i > -1; i--) {
        if (bodyFound) {
          continue;
        }
        final line = bodyLines[i];
        if (line.trim().isEmpty) {
          if (!bodyFound) {
            // remove it and continue
            bodyLines.removeAt(i);
          }
          if (!notEmptyLineFound) {
            continue;
          }
        }
        notEmptyLineFound = true;
        if (CommitMessageFooter.looksLikeFooter(line)) {
          final footerItem = CommitMessageFooter.parse(line);
          if (footerItem.breaking) {
            breaking = true;
          }
          footerItems.insert(0, footerItem);

          bodyLines.removeAt(i);
          continue;
        }
        bodyFound = true;
      }
    }

    if (bodyLines.isNotEmpty) {
      if (bodyLines.first.trim().isNotEmpty) {
        parsingErrors.add('no-blank-line-before-body');
      } else {
        bodyLines.removeAt(0);
      }
    }

    return CommitMessage(
      type: parsedHeader.type,
      description: parsedHeader.description,
      body: bodyLines.join('\n'),
      scope: parsedHeader.scope,
      breaking: breaking,
      header: parsedHeader.header,
      footer: footerItems,
      parsingErrors: parsingErrors,
    );
  }

  @override
  List<Object?> get props =>
      [type, description, scope, body, breaking, isConventional, footer];

  @override
  String toString() {
    return '''
type: ${_noneIfEmpty(type)}
description: ${_noneIfEmpty(description)}
scope: ${_noneIfEmpty(scope)}
breaking: $breaking
header: ${_noneIfEmpty(header)}
body: ${_noneIfEmpty(_bodyDisplay())}
footer: ${_noneIfEmpty(_footerDisplay())}''';
  }

  String _bodyDisplay() {
    return body.isEmpty ? body : '\n${_indent(body)}\n';
  }

  String _footerDisplay() {
    return footer.isEmpty ? '' : '\n${_indentLines(footer)}';
  }
}

String _indent(String str) {
  return _indentLines(str.split("\n"));
}

String _indentLines(List lines) {
  return lines.map((e) => '  $e').toList().join('\n');
}

String _noneIfEmpty(String str) {
  return str.isEmpty ? 'none' : str;
}
