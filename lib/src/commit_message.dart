import 'package:equatable/equatable.dart';
import 'package:petitparser/petitparser.dart';

import 'commit_message_footer.dart';
import 'commit_message_header.dart';
import 'commit_message_parser.dart';

CommitMessageHeader _headerFromProps({
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
  final CommitMessageHeader header;

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
    CommitMessageHeader? header,
    String? description,
    bool? breaking,
    String? scope,
    String? body,
    List<CommitMessageFooter>? footer,
    List<String>? parsingErrors,
  })  : header = header is CommitMessageHeader
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
