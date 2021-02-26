part of '../conventional.dart';

final _messageRegexp = RegExp(r'^(\w+)(\!?)(\((.+)\))?:(.*)');

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

/// A footer item of a [CommitMessage]
///
/// Typical footer items:
///
/// ```
/// Reviewed-by: James <james@somewhere.com>
/// BREAKING CHANGE: changes behavior of sleep().
/// ```
class CommitMessageFooter with EquatableMixin {
  /// Footer key
  final String key;

  /// Footer value
  final String value;

  /// Whether the footer follows Conventional Commit spec
  bool get isValid => _keyRegExp.hasMatch(key) && value.isNotEmpty;

  /// Whether it represents a BREAKING CHANGE item.
  ///
  /// Will be true if [key] is either 'BREAKING', 'BREAKING-CHANGE', or
  /// 'BREAKING CHANGE':
  bool get breaking => _breakingKeys.contains(key);

  /// Creates a CommitMessageFooter
  CommitMessageFooter({this.key = '', required this.value});

  /// A helper static function for checking if a line of text looks like a
  /// footer.
  static bool looksLikeFooter(String str) {
    return _footerRegexp.firstMatch(str) is RegExpMatch;
  }

  /// Parses a possible line of string
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
  List<Object> get props => [key.toLowerCase(), value];

  @override
  String toString() {
    return key.isEmpty ? value : '$key: $value';
  }
}

/// Represents a git commit message
///
/// A rough format of a typical Conventional Commit is:
///
/// [type]([scope]): [description]
///
/// [body]
///
/// [footer]
///
/// See [conventionalcommits.org](https://www.conventionalcommits.org/) for more
/// information on how to format commits. following the spec.
class CommitMessage with EquatableMixin {
  final String _header;

  /// A commit type following Conventional Commit
  final String type;

  /// The commit description
  final String description;

  /// The scope of the commit
  final String scope;

  /// The commit body
  final String body;

  /// Whether this commit is a breaking change
  final bool breaking;

  /// Footer of the commits
  final List<CommitMessageFooter> footer;

  // Use this to store parsing errors
  final List<String> _parsingErrors;

  /// See all the parsing errors generated from [Commit.parse]
  ///
  /// TODO: Currently is not used much. Add more errors here.
  List<String> get parsingErrors => _parsingErrors;

  /// Whether this follows the Conventional Commit format
  ///
  /// Typically more useful when [Commit] is created using [Commit.parse].
  bool get isConventional =>
      type.isNotEmpty && description.isNotEmpty & _parsingErrors.isEmpty;

  /// The commit message header
  ///
  /// This is the first line of a commit. For commits following the Conventional
  /// Commit format, it will be formatted as "[type]: [description]".
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

  /// Creates a CommitMessage
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
        footer = footer ?? const [],
        _header = header ?? '',
        _parsingErrors = parsingErrors ?? const [];

  /// Parses a commit message string
  ///
  /// If the [commitMessageStr] does not follow the Conventional Commit format,
  /// it will still be parsed but [isConventional] will be false and the only
  /// fields that are populated are [description] and [body] if available along
  /// with [parsingErrors] populated.
  static CommitMessage parse(String commitMessageStr) {
    final lines = commitMessageStr.split('\n');
    return parseCommitLines(lines);
  }

  /// Parses a [List<String>] from a commit message string
  ///
  /// See [CommitMessage.parse]
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
