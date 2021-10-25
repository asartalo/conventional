import 'package:pub_semver/pub_semver.dart';

/// Generates a version that doesn't have build numbers
Version buildlessVersion(Version version) {
  return Version.parse(
    '$version'.replaceAll(RegExp(r'\+.+$'), ''),
  );
}
