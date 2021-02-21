A simple and light-weight library for parsing conventional commits and generating changelogs from them.
## Usage

A simple usage example:

```dart
import 'package:conventional/conventional.dart';

main() {
  final List<Commit> commits = Commit.parseCommits(testLog);
  if (hasReleasableCommits(commits))
}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/asartalo/conventional/issues
