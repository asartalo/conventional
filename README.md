# Conventional

A simple and light-weight library for working with commits that follow the [Conventional Commits](https://www.conventionalcommits.org) specification.

**NOTE:** At the moment, this library is only used on my projects. The API is a moving target at the moment. The Conventional Commit parser is not comprehensive. If you need a more mature solution, I recommend [conventional_commits](https://pub.dev/packages/conventional_commit).

## Features

- `Commit.parseCommits()` for parsing commits from a `git --no-pager log --no-decorate` command.
- `hasReleasableCommits()` for checking if a list `Commit` items has releasable commits following the convention.
- `writeChangelog()` for automated authoring of CHANGELOGs based on commits that follow the conventional commits spec.
- `lintCommit()` for checking whether commit messages follow the conventional commit convention. Useful when used alongside [git_hooks](https://pub.dev/packages/git_hooks).

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
