# 0.5.0 (2023-11-27)

## Bug Fixes

- updating dependencies ([e75630e](commit/e75630e))
- parsing logs when empty [#2](issues/2) ([4c48f79](commit/4c48f79))
- parsing with 'commit' in message ([3eb9399](commit/3eb9399))
- bug in version increment logic ([8dcc381](commit/8dcc381))

## Features

- **changelog:** perf commit types [#1](issues/1) ([4af7934](commit/4af7934))
- updated petitparser to v5 ([cd20213](commit/cd20213))
- wrteChangelogToFile() ([8a15b50](commit/8a15b50))
- better commit log parsing ([e6aa322](commit/e6aa322))
- lintCommits and API docs ([713d38c](commit/713d38c))
- lintCommit() for validating commits ([5a02eb2](commit/5a02eb2))
- nextVersion() for bumping versions ([c320713](commit/c320713))

## BREAKING CHANGES

- upgrade to dart 3 plus libraries esp. petitparser ([17517f6](commit/17517f6))
- incrementBuild, afterV1, and pre flags ([8d24c86](commit/8d24c86))

# 0.4.0 (2023-11-24)

## BREAKING CHANGES

- upgrade to dart 3 plus libraries esp. petitparser ([17517f6](commit/17517f6))

# 0.3.1 (2022-07-27)

## Bug Fixes

- updating dependencies ([e75630e](commit/e75630e))

## Features

- updated petitparser to v5 ([cd20213](commit/cd20213))

# 0.3.0 (2021-10-25)

## BREAKING CHANGES

- incrementBuild, afterV1, and pre flags ([8d24c86](commit/8d24c86))

# 0.2.4 (2021-04-03)

## Bug Fixes

- parsing logs when empty [#2](issues/2) ([4c48f79](commit/4c48f79))

## Features

- **changelog:** perf commit types [#1](issues/1) ([4af7934](commit/4af7934))

## 0.2.3

- `writeChangelogToFile()` for writing changelogs to `File`

## 0.2.2

- Fix parsing problem when there is 'commit' in commit message

## 0.2.1

- Fix next_version increment logic

## 0.2.0

- Use petite_parser for robust commit parsing

## 0.1.0

- Updated equatable dependency

## 0.1.0-pre

- Added `lintCommit()` for linting commit messages based on Conventional Commit
  logs
- Added some API documentation

## 0.0.2-pre

- Added `nextVersion()` for determining the next version based on commits

## 0.0.1-pre

- Initial version
