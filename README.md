# Conventional

A light-weight library for working with commits that follow the [Conventional Commits](https://www.conventionalcommits.org) specification.

**NOTE:** At the moment, this library is only used on my projects and the API is a moving target. The Conventional Commit parser is not comprehensive. If you need a more mature solution, try [conventional_commits](https://pub.dev/packages/conventional_commit).

## Features

- [Commit.parseCommits()][Commit.parseCommits] for parsing commits from a `git --no-pager log --no-decorate` command output.
- [hasReleasableCommits()][hasReleasableCommits] for checking if a list `Commit` items has releasable commits following the convention.
- [writeChangelog()][writeChangelog] for automated authoring of CHANGELOGs based on commits that follow the conventional commits spec.
- [lintCommit()][lintCommit] for checking whether commit messages follow the conventional commit spec. Useful when used alongside [git_hooks](https://pub.dev/packages/git_hooks).
- [nextVersion()][nextVersion] for bumping to a next version based on releasable commits.

## Usage

A simple usage example:

```dart
import 'package:conventional/conventional.dart';

main() {
  final List<Commit> commits = Commit.parseCommits(testLog);
  if (hasReleasableCommits(commits)) {
    writeChangelog(
      commits: commits,
      changelogFilePath: 'CHANGELOG.md',
      version: '1.2.0',
      now: DateTime.now(),
    );
  }
}
```

## Feature Requests and Bugs

Please file feature requests and bugs at the [issue tracker][tracker]. PR's are welcome and appreciated!

[tracker]: https://github.com/asartalo/conventional/issues
[Commit.parseCommits]: https://pub.dev/documentation/conventional/latest/conventional/Commit/parseCommits.html
[hasReleasableCommits]: https://pub.dev/documentation/conventional/latest/conventional/hasReleasableCommits.html
[writeChangelog]: https://pub.dev/documentation/conventional/latest/conventional/writeChangelog.html
[lintCommit]: https://pub.dev/documentation/conventional/latest/conventional/lintCommit.html
[nextVersion]: https://pub.dev/documentation/conventional/latest/conventional/nextVersion.html