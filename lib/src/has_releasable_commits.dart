import 'commit.dart';

/// These are the commit types that should trigger a release.
const releasableCommitTypes = <String>{'feat', 'fix'};

/// Checks whether a list of commits has commits that can be released.
bool hasReleasableCommits(List<Commit> commits) {
  for (final commit in commits) {
    if (releasableCommitTypes.contains(commit.type)) {
      return true;
    }
  }
  return false;
}
