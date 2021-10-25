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
Version nextVersion(
  Version currentVersion,
  List<Commit> commits, {
  bool incrementBuild = false,
  bool afterV1 = false,
  String? pre,
}) {
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

  late Version prepVersion;
  final isPre1 = currentVersion.major < 1;
  final basis =
      Version(currentVersion.major, currentVersion.minor, currentVersion.patch);

  if (isPre1 && afterV1 && (isMajor || isMinor || isPatch)) {
    prepVersion = currentVersion.nextMajor;
  } else {
    if (isMajor) {
      prepVersion = isPre1 ? basis.nextMinor : basis.nextMajor;
    } else if (isMinor) {
      prepVersion = isPre1 ? basis.nextPatch : basis.nextMinor;
    } else if (isPatch) {
      prepVersion = basis.nextPatch;
    } else {
      return currentVersion;
    }
  }

  return Version(
    prepVersion.major,
    prepVersion.minor,
    prepVersion.patch,
    build: currentVersion.build.isEmpty
        ? null
        : _addBuild(currentVersion, incrementBuild: incrementBuild),
    pre: pre is String
        ? pre
        : currentVersion.preRelease.isEmpty
            ? null
            : currentVersion.preRelease.join('.'),
  );
}

String _addBuild(Version version, {bool incrementBuild = false}) {
  return version.build
      .map(
          (section) => incrementBuild && section is int ? section + 1 : section)
      .join('.');
}
