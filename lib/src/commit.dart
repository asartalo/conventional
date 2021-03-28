import 'package:equatable/equatable.dart';

import 'commit_author.dart';
import 'commit_logs_parser.dart';
import 'commit_message.dart';
import 'commit_message_footer.dart';
import 'commit_message_header.dart';
import 'commit_parser.dart';

final _commitParser = CommitParser();
final _commitLogsParser = CommitLogsParser();

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
  CommitMessageHeader get header => message.header;

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
    String? type,
    String? description,
    CommitMessageHeader? header,
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
    return _commitParser.parse(logItem);
  }

  /// Creates a list of [Commit]s from a `git log` output
  ///
  /// This differs from [Commit.parse] as the [logOutput] expects multiple git
  /// log items.
  ///
  /// See also [Commit.parse].
  static List<Commit> parseCommits(String logOutput) {
    return _commitLogsParser.parse(logOutput);
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
