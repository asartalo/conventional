part of '../conventional.dart';

Version nextVersion(Version before, List<Commit> commits) {
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
    return before;
  }

  return Version(
    before.major + major,
    before.minor + minor,
    before.patch + patch,
    build: before.build.isEmpty ? null : before.build.join('.'),
    pre: before.preRelease.isEmpty ? null : before.preRelease.join('.'),
  );
}
