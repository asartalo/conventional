library conventional;

import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:pub_semver/pub_semver.dart';

part 'src/changelog.dart';
part 'src/commit.dart';
part 'src/commit_author.dart';
part 'src/commit_message.dart';
part 'src/lint_commit.dart';
part 'src/next_version.dart';
part 'src/version.dart';

const releasableCommitTypes = <String>{'feat', 'fix'};

bool hasReleasableCommits(List<Commit> commits) {
  for (final commit in commits) {
    if (releasableCommitTypes.contains(commit.type)) {
      return true;
    }
  }
  return false;
}
