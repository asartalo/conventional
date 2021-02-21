# Conventional

A simple and light-weight library for parsing conventional commits and generating changelogs from them.

**NOTE:** At the moment, this library is only used on my projects. The Conventional Commit parser is not made to be comprehensive.

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

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/asartalo/conventional/issues
