import 'package:equatable/equatable.dart';

/// Represents a commit message header
abstract class CommitMessageHeader {
  /// The commit type
  ///
  /// e.g. fix, feat, chore, etc.
  external String get type;

  /// The description for this commit
  external String get description;

  /// The scope of the commit
  external String get scope;

  /// Whether the commit is breaking or not
  external bool get breaking;

  @override
  external String toString();
}

/// A commit header that follows the Conventional Commit spec
class ConventionalHeader with EquatableMixin implements CommitMessageHeader {
  @override
  final String type;
  @override
  final String scope;
  @override
  final bool breaking;
  @override
  final String description;

  // ignore: public_member_api_docs
  ConventionalHeader({
    required this.type,
    required this.scope,
    required this.breaking,
    required this.description,
  });

  @override
  String toString() {
    final scopeText = scope.isEmpty ? '' : '($scope)';
    return '$type$scopeText${breaking ? '!' : ''}: $description';
  }

  @override
  List<Object> get props => [type, scope, breaking, description];
}

/// A commit header that doesn't follow the Conventional Commit spec
class RegularHeader with EquatableMixin implements CommitMessageHeader {
  @override
  String get type => '';
  @override
  String get scope => '';
  @override
  bool get breaking => false;
  @override
  final String description;

  // ignore: public_member_api_docs
  RegularHeader({required this.description});

  @override
  String toString() => description;

  @override
  // TODO: implement props
  List<Object> get props => [description];
}
