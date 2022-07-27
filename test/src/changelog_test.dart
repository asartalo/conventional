import 'dart:io';

import 'package:conventional/conventional.dart';
import 'package:mutex/mutex.dart';
import 'package:path/path.dart' as paths;
import 'package:test/test.dart';

import '../fixtures.dart';

final _startDir = Directory.current.path;
final _tmpDir = paths.join(_startDir, 'tmp');

bool _exists(String path) {
  return FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound;
}

void main() {
  final m = ReadWriteMutex();
  group('writeChangelog()', () {
    final tmpDir = Directory(_tmpDir);
    final changelogFilePath = paths.join(_tmpDir, 'CHANGELOG.md');
    final now = DateTime.parse('2021-02-09 12:00:00');
    const version = '1.0.0';
    late List<Commit> commits;

    setUpAll(() async {
      if (!(await tmpDir.exists())) {
        await tmpDir.create();
      }
    });

    setUp(() async {
      if (_exists(changelogFilePath)) {
        await m.protectWrite(() async {
          await File(changelogFilePath).delete();
        });
      }
    });

    tearDown(() async {
      if (_exists(changelogFilePath)) {
        await m.protectWrite(() async {
          await File(changelogFilePath).delete();
        });
      }
    });

    tearDownAll(() async {
      if (await tmpDir.exists()) {
        await tmpDir.delete();
      }
    });

    group('when CHANGELOG should not be generated or updated', () {
      final Map<String, List<String>> noChangeLogs = {
        'there are no updates': [],
        'there are no releasable updates': [chore, docs],
      };

      noChangeLogs.forEach((condition, commitsStrings) {
        Future<void> setupFunction() async {
          commits = Commit.parseCommitsStringList(commitsStrings);
          await m.protectWrite(() async {
            await writeChangelog(
              commits: commits,
              changelogFilePath: changelogFilePath,
              version: version,
              now: now,
            );
          });
        }

        group('if $condition', () {
          group('if there is no changelog file yet', () {
            setUp(() async {
              await setupFunction();
            });

            test('does not create a changelog if $condition', () async {
              await m.protectRead(() async {
                expect(_exists(changelogFilePath), false);
              });
            });
          });

          group('if there is an existing changelog file', () {
            setUp(() async {
              final file = File(changelogFilePath);
              await m.protectWrite(() async {
                await file.writeAsString('');
              });
              await setupFunction();
            });

            test('does not update a file if $condition', () async {
              final file = File(changelogFilePath);
              await m.protectRead(() async {
                expect(await file.readAsString(), equals(''));
              });
            });
          });
        });
      });
    });

    group('when CHANGELOG can be generated or updated', () {
      final Map<String, _Test> testData = {
        'all stuff': const _Test(
          [chore, docs, fix, feat, feat2, feat3, feat4, breaking, perf],
          '''
# 1.0.0 (2021-02-09)

## Bug Fixes

- eat healthy ([#3](issues/3)) ([cf60800](commit/cf60800))

## Features

- **movement:** it jumps ([#1](issues/1)) ([925fcd3](commit/925fcd3))
- **movement:** it pounces ([#2](issues/2)) ([a25fcd3](commit/a25fcd3))
- **communication:** it talks ([#4](issues/4)) ([a25fcd3](commit/a25fcd3))
- **communication:** it sends sms ([#5](issues/5)) ([b25fcd3](commit/b25fcd3))

## Performance Improvements

- make jumping faster ([40a511b](commit/40a511b))

## BREAKING CHANGES

- null-safety ([#6](issues/6)) ([43cf9b7](commit/43cf9b7))
''',
        ),
        'fix and features only': const _Test(
          [fix, feat, feat2],
          '''
# 1.0.0 (2021-02-09)

## Bug Fixes

- eat healthy ([#3](issues/3)) ([cf60800](commit/cf60800))

## Features

- **movement:** it jumps ([#1](issues/1)) ([925fcd3](commit/925fcd3))
- **communication:** it talks ([#4](issues/4)) ([a25fcd3](commit/a25fcd3))
''',
        ),
      };

      testData.forEach((key, data) {
        Future<void> setupProper() async {
          commits = Commit.parseCommitsStringList(data.commits);
          await m.protectWrite(() async {
            await writeChangelog(
              commits: commits,
              changelogFilePath: changelogFilePath,
              version: version,
              now: now,
            );
          });
        }

        group('$key and no changelog file yet', () {
          setUp(() async {
            await setupProper();
          });

          test('writes the changelog file', () async {
            await m.protectRead(() async {
              expect(_exists(changelogFilePath), true);
            });
          });

          test('writes changelog contents to the file', () async {
            await m.protectRead(() async {
              final contents = await File(changelogFilePath).readAsString();
              expect(contents, equals(data.content));
            });
          });
        });

        group('$key and a changelog file already exists', () {
          setUp(() async {
            await m.protectWrite(() async {
              final file = File(changelogFilePath);
              await file.writeAsString('Hello world.\n');
            });
            await setupProper();
          });

          test('writes changelog contents to the file', () async {
            await m.protectRead(() async {
              final contents = await File(changelogFilePath).readAsString();
              expect(contents, equals('${data.content}\nHello world.\n'));
            });
          });
        });
      });
    });
  });
}

class _Test {
  final List<String> commits;
  final String content;

  const _Test(this.commits, this.content);
}
