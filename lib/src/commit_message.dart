import 'package:conventional/src/commit_message_parser.dart';
import 'package:equatable/equatable.dart';
import 'package:petitparser/petitparser.dart';

final _keyRegExp = RegExp(
    r'^(BREAKING|BREAKING CHANGE|BREAKING-CHANGE|[A-Za-z][A-Za-z\-]*[A-Za-z])$');
final _footerRegexp = RegExp(
    r'^(BREAKING|BREAKING CHANGE|BREAKING-CHANGE|[A-Za-z][A-Za-z\-]*[A-Za-z]): (.+)');

const _breakingKeys = <String>{
  'BREAKING',
  'BREAKING-CHANGE',
  'BREAKING CHANGE',
};

/// Represents a commit message header
abstract class CommitHeader {
  external String get type;
  external String get description;
  external String get scope;
  external bool get breaking;
  external String toString();
}

/// A commit header that follows the Conventional Commit spec
class ConventionalHeader with EquatableMixin implements CommitHeader {
  final String type;
  final String scope;
  final bool breaking;
  final String description;

  ConventionalHeader({
    required this.type,
    required this.scope,
    required this.breaking,
    required this.description,
  });

  @override
  String toString() {
    final scopeText = scope.isEmpty ? '' : '($scope)';
    return '$type$scopeText${breaking ? '!' : ''}: $description';
  }

  @override
  List<Object> get props => [type, scope, breaking, description];
}

/// A commit header that doesn't follow the Conventional Commit spec
class RegularHeader with EquatableMixin implements CommitHeader {
  String get type => '';
  String get scope => '';
  bool get breaking => false;
  final String description;
  RegularHeader({required this.description});

  @override
  String toString() => description;

  @override
  // TODO: implement props
  List<Object> get props => [description];
}

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
  List<Object> get props => [key.toUpperCase(), value];

  @override
  String toString() {
    return key.isEmpty ? value : '$key: $value';
  }
}

CommitHeader _headerFromProps({
  bool? breaking,
  String? scope,
  String? type,
  String? description,
}) {
  if (description is! String) {
    throw ArgumentError(
      'If header is not present, please provide a description',
    );
  }
  if (type is String) {
    return ConventionalHeader(
      type: type,
      scope: scope ?? '',
      breaking: breaking ?? false,
      description: description,
    );
  } else {
    return RegularHeader(description: description);
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
  /// The commit message header
  ///
  /// This is the first line of a commit. For commits following the Conventional
  /// Commit format, it will be formatted as "[type]: [description]".
  final CommitHeader header;

  /// A commit type following Conventional Commit
  String get type => header.type;

  /// The commit description
  String get description => header.description;

  /// The scope of the commit
  String get scope => header.scope;

  /// The commit body
  final String body;

  /// Whether this commit is a breaking change
  bool get breaking =>
      header.breaking || footer.any((footerLine) => footerLine.breaking);

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

  /// Creates a CommitMessage
  CommitMessage({
    String? type,
    CommitHeader? header,
    String? description,
    bool? breaking,
    String? scope,
    String? body,
    List<CommitMessageFooter>? footer,
    List<String>? parsingErrors,
  })  : header = header is CommitHeader
            ? header
            : _headerFromProps(
                breaking: breaking,
                scope: scope,
                type: type,
                description: description,
              ),
        body = body ?? '',
        footer = footer ?? const [],
        _parsingErrors = parsingErrors ?? const [];

  /// Parses a commit message string
  ///
  /// If the [commitMessageStr] does not follow the Conventional Commit format,
  /// it will still be parsed but [isConventional] will be false and the only
  /// fields that are populated are [description] and [body] if available along
  /// with [parsingErrors] populated.
  static CommitMessage parse(String commitMessageStr) {
    final result = CommitMessageParser().parse(commitMessageStr.trim());
    if (result is Success) {
      return result.value as CommitMessage;
    }
    throw Exception('Unable to parse Commit Message $commitMessageStr');
  }

  /// Parses a [List<String>] from a commit message string
  ///
  /// See [CommitMessage.parse]
  // ignore: prefer_constructors_over_static_methods
  static CommitMessage parseCommitLines(List<String> lines) {
    return parse(lines.join('\n'));
  }

  @override
  List<Object?> get props => [
        type,
        description,
        scope,
        body,
        breaking,
        isConventional,
        footer,
        parsingErrors,
      ];

  @override
  String toString() {
    return '''
type: ${_noneIfEmpty(type)}
description: ${_noneIfEmpty(description)}
scope: ${_noneIfEmpty(scope)}
breaking: $breaking
header: $header
body: ${_noneIfEmpty(_bodyDisplay())}
footer: ${_noneIfEmpty(_footerDisplay())}
parsingErrors: $_parsingErrors''';
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
