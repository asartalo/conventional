import 'package:pub_semver/pub_semver.dart';
import 'commit.dart';

/// Bump up a [currentVersion] based on a list of [commits]
///
/// If [commits] has any breaking changes, it will be bumped to the next
/// major version. If not and the [commits] have any new features, it will be
/// bumped to the next minor version. If not and the [commits] have patch-level
/// changes, it will be bumped to the next patch version.
///
/// NOTE: I would have loved to use [Version.nextMajor] methods and the like.
/// However, they discarded the build numbers and release parts so I had to
/// create my own.
///
/// TODO: Perhaps asks the kind people at pub_semver to have this feature.
Version nextVersion(Version currentVersion, List<Commit> commits) {
  bool isMajor = false;
  bool isMinor = false;
  bool isPatch = false;

  for (final commit in commits) {
    if (commit.breaking) {
      isMajor = true;
    } else if (commit.type == 'feat') {
      isMinor = true;
    } else if (commit.type == 'fix') {
      isPatch = true;
    }
  }

  late Version preVersion;
  final isPre1 = currentVersion.major < 1;

  if (isMajor) {
    preVersion = isPre1 ? currentVersion.nextMinor : currentVersion.nextMajor;
  } else if (isMinor) {
    preVersion = isPre1 ? currentVersion.nextPatch : currentVersion.nextMinor;
  } else if (isPatch) {
    preVersion = currentVersion.nextPatch;
  } else {
    return currentVersion;
  }

  return Version(
    preVersion.major,
    preVersion.minor,
    preVersion.patch,
    build: currentVersion.build.isEmpty ? null : currentVersion.build.join('.'),
    pre: currentVersion.preRelease.isEmpty
        ? null
        : currentVersion.preRelease.join('.'),
  );
}
