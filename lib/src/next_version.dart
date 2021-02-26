part of '../conventional.dart';

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

  int major = 0;
  int minor = 0;
  int patch = 0;

  if (isMajor) {
    major = 1;
  } else if (isMinor) {
    minor = 1;
  } else if (isPatch) {
    patch = 1;
  } else {
    return currentVersion;
  }

  return Version(
    currentVersion.major + major,
    currentVersion.minor + minor,
    currentVersion.patch + patch,
    build: currentVersion.build.isEmpty ? null : currentVersion.build.join('.'),
    pre: currentVersion.preRelease.isEmpty
        ? null
        : currentVersion.preRelease.join('.'),
  );
}
