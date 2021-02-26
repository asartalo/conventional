part of '../conventional.dart';

/// Writes to a changelog file based on commits.
///
/// It first checks if [commits] have "releaseable" commits using
/// [hasReleasableCommits]. If it doesn't, it will return `null`. If it does,
/// it will write to the [changelogFilePath] with given [version] string for the
/// changes within within [commits] and [now] for the date. This will then
/// return with a [ChangeSummary].
///
/// If [now] isn't provided, it will default to `DateTime.now()`.
Future<ChangeSummary?> writeChangelog({
  required List<Commit> commits,
  required String changelogFilePath,
  required String version,
  DateTime? now,
}) async {
  if (hasReleasableCommits(commits)) {
    now ??= DateTime.now();
    final file = File(changelogFilePath);
    String oldContents = '';
    if (await file.exists()) {
      oldContents = (await file.readAsString()).trim();
    }
    final summary = _writeContents(commits, Version.parse(version), now);
    await file.writeAsString(oldContents.isEmpty
        ? summary.toMarkdown()
        : '${summary.toMarkdown()}\n$oldContents\n');
    return summary;
  }
  return null;
}

String _commitLink(Commit commit) {
  final hash = commit.id.substring(0, 7);
  return '([$hash](commit/$hash))';
}

final _issueRegexp = RegExp(r'\#(\d+)');
String _linkIssues(String description) {
  return description.replaceAllMapped(_issueRegexp, (match) {
    final issueNumber = match.group(1);
    return '[#$issueNumber](issues/$issueNumber)';
  });
}

String _formatLog(Commit commit) {
  final scopePart = commit.scope.isEmpty ? '' : '**${commit.scope}:** ';
  return '- $scopePart${_linkIssues(commit.description)} ${_commitLink(commit)}';
}

String? _changeSection(String header, List<Commit> commits) {
  if (commits.isEmpty) {
    return null;
  }
  commits.sort((a, b) {
    if (a.scope == b.scope) {
      return a.scope.compareTo(b.scope);
    }
    return a.date.compareTo(b.date);
  });
  final contents = commits.map(_formatLog).toList().join('\n');
  return '## $header\n\n$contents';
}

/// A grouping of commit changes.
///
/// Groups are for [bugFixes], [features], and [breakingChanges].
class CommitSections extends Equatable {
  /// Bug fix commits
  final List<Commit> bugFixes = [];

  /// Commits that add new features
  final List<Commit> features = [];

  /// Commits that have breaking changes
  final List<Commit> breakingChanges = [];

  /// Whether there are no items in all commit groups.
  bool get isEmpty =>
      (bugFixes.length + features.length + breakingChanges.length) > 0;

  /// Whether there are items in commit groups
  bool get isNotEmpty => !isEmpty;

  @override
  List<Object?> get props => [bugFixes, features, breakingChanges];

  /// Create a [CommitSections] based on [commits].
  CommitSections fromCommits(List<Commit> commits) {
    final section = CommitSections();
    for (final commit in commits) {
      section.add(commit);
    }
    return section;
  }

  /// Adds a commit to the [CommitSections].
  ///
  /// Returns `true` if the [commit] was added to any of the group or `false`
  /// when it wasn't.
  bool add(Commit commit) {
    var added = true;
    if (commit.breaking) {
      breakingChanges.add(commit);
    } else if (commit.type == 'fix') {
      bugFixes.add(commit);
    } else if (commit.type == 'feat') {
      features.add(commit);
    } else {
      added = false;
    }
    return added;
  }
}

/// A summary of changes
///
/// Mainly used for writing changelogs.
class ChangeSummary extends Equatable {
  /// The version for the change
  final Version version;

  /// The releasable commits
  final CommitSections sections;

  /// The date for releasing the change
  final DateTime date;

  /// Whether there are any commits included in this summary
  bool get isNotEmpty => sections.isNotEmpty;

  /// Wheter there are no commits included in this summary
  bool get isEmpty => sections.isEmpty;

  /// Create a ChangeSummary
  const ChangeSummary({
    required this.version,
    required this.sections,
    required this.date,
  });

  @override
  List<Object?> get props => [version, sections, date];

  /// Returns a Markdown string of changes
  String toMarkdown() {
    final List<String> parts = [
      _versionHeadline(version.toString(), date),
      _changeSection('Bug Fixes', sections.bugFixes),
      _changeSection('Features', sections.features),
      _changeSection('BREAKING CHANGES', sections.breakingChanges),
    ].whereType<String>().toList();

    return '${parts.join('\n\n').trim()}\n';
  }
}

ChangeSummary _writeContents(
    List<Commit> commits, Version version, DateTime now) {
  final logs = CommitSections();
  for (final commit in commits) {
    logs.add(commit);
  }

  return ChangeSummary(version: version, sections: logs, date: now);
}

String _versionHeadline(String version, DateTime now) {
  final date = '${now.year}-${_zeroPad(now.month)}-${_zeroPad(now.day)}';
  return '# $version ($date)';
}
