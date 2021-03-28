import 'package:equatable/equatable.dart';

final _keyRegExp = RegExp(
    r'^(BREAKING|BREAKING CHANGE|BREAKING-CHANGE|[A-Za-z][A-Za-z\-]*[A-Za-z])$');
final _footerRegexp = RegExp(
    r'^(BREAKING|BREAKING CHANGE|BREAKING-CHANGE|[A-Za-z][A-Za-z\-]*[A-Za-z]): (.+)');

const _breakingKeys = <String>{
  'BREAKING',
  'BREAKING-CHANGE',
  'BREAKING CHANGE',
};

/// A footer item of a [CommitMessage]
///
/// Typical footer items:
///
/// ```
/// Reviewed-by: James <james@somewhere.com>
/// BREAKING CHANGE: changes behavior of sleep().
/// ```
class CommitMessageFooter with EquatableMixin {
  /// Footer key
  final String key;

  /// Footer value
  final String value;

  /// Whether the footer follows Conventional Commit spec
  bool get isValid => _keyRegExp.hasMatch(key) && value.isNotEmpty;

  /// Whether it represents a BREAKING CHANGE item.
  ///
  /// Will be true if [key] is either 'BREAKING', 'BREAKING-CHANGE', or
  /// 'BREAKING CHANGE':
  bool get breaking => _breakingKeys.contains(key);

  /// Creates a CommitMessageFooter
  CommitMessageFooter({this.key = '', required this.value});

  /// A helper static function for checking if a line of text looks like a
  /// footer.
  static bool looksLikeFooter(String str) {
    return _footerRegexp.firstMatch(str) is RegExpMatch;
  }

  /// Parses a possible line of string
  // ignore: prefer_constructors_over_static_methods
  static CommitMessageFooter parse(String str) {
    final match = _footerRegexp.firstMatch(str);
    if (match is RegExpMatch) {
      return CommitMessageFooter(
        key: match.group(1)!,
        value: match.group(2)!,
      );
    }
    return CommitMessageFooter(value: str);
  }

  @override
  List<Object> get props => [key.toUpperCase(), value];

  @override
  String toString() {
    return key.isEmpty ? value : '$key: $value';
  }
}
