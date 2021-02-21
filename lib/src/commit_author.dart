part of '../conventional.dart';

class CommitAuthor extends Equatable {
  final String name;
  final String email;

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
