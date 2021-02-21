part of '../conventional.dart';

Future<ChangeSummary?> writeChangelog({
  required List<Commit> commits,
  required String changelogFilePath,
  required String version,
  required DateTime now,
}) async {
  if (hasReleasableCommits(commits)) {
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

class CommitSections extends Equatable {
  final List<Commit> bugFixes = [];
  final List<Commit> features = [];
  final List<Commit> breakingChanges = [];

  bool get isEmpty =>
      (bugFixes.length + features.length + breakingChanges.length) > 0;
  bool get isNotEmpty => !isEmpty;

  @override
  List<Object?> get props => [bugFixes, features, breakingChanges];

  CommitSections fromCommits(List<Commit> commits) {
    final section = CommitSections();
    for (final commit in commits) {
      section.add(commit);
    }
    return section;
  }

  void add(Commit commit) {
    if (commit.breaking) {
      breakingChanges.add(commit);
    } else if (commit.type == 'fix') {
      bugFixes.add(commit);
    } else if (commit.type == 'feat') {
      features.add(commit);
    }
  }
}

class ChangeSummary extends Equatable {
  final Version version;
  final CommitSections sections;
  final DateTime date;

  bool get isNotEmpty => sections.isNotEmpty;
  bool get isEmpty => sections.isEmpty;

  const ChangeSummary({
    required this.version,
    required this.sections,
    required this.date,
  });

  @override
  List<Object?> get props => [version, sections, date];

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
