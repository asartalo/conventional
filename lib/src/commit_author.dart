part of '../conventional.dart';

/// Represents the author of the commit
class CommitAuthor extends Equatable {
  /// Name of the author
  final String name;

  /// The author's email
  final String email;

  // ignore: public_member_api_docs
  const CommitAuthor({
    required this.name,
    required this.email,
  });

  @override
  String toString() {
    return '$name <$email>';
  }

  @override
  List<Object?> get props => [name, email];
}
