part of 'conventional.dart';

Version buildlessVersion(Version version) {
  return Version.parse(
    '$version'.replaceAll(RegExp(r'\+.+$'), ''),
  );
}
