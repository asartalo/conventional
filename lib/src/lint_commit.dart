import 'package:equatable/equatable.dart';

import 'commit_message.dart';

/// A configuration for linting rules
///
/// Currently sparse at the moment.
class LintConfig with EquatableMixin {
  /// The list of commit types allowed
  final Set<String> types;

  /// The maximum length of the header
  final int maxHeaderLength;

  // ignore: public_member_api_docs
  const LintConfig({
    required this.types,
    required this.maxHeaderLength,
  });

  /// The default configuration
  static const defaultConfig = LintConfig(
    maxHeaderLength: 72,
    types: <String>{
      'build',
      'ci',
      'docs',
      'feat',
      'fix',
      'perf',
      'refactor',
      'revert',
      'style',
      'test',
      'chore',
    },
  );

  /// For printing the types
  String get typesDisplay => types.toList().join(',');

  /// Return a new config based on another while overriding some fields
  LintConfig copyWith({
    Set<String>? types,
    int? maxHeaderLength,
  }) {
    return LintConfig(
      types: types ?? this.types,
      maxHeaderLength: maxHeaderLength ?? this.maxHeaderLength,
    );
  }

  @override
  List<Object?> get props => [];
}

/// A result for a LintRule pass
class LintResult with EquatableMixin {
  /// Whether the message passed the rule
  final bool valid;

  /// The message if the the message passed
  ///
  /// Should be empty if [valid] is true.
  final String message;

  // ignore: public_member_api_docs
  const LintResult({
    required this.valid,
    required this.message,
  });

  @override
  List<Object?> get props => [valid, message];

  @override
  String toString() {
    return '''
valid: $valid
message: $message
''';
  }
}

/// A validator function for validating messages
typedef LintValidator = bool Function(LintContext context);

/// A function for generating [LintResult.message]
typedef LintInvalidMessage = String Function(LintContext context);

/// The context of a [LintRule] pass
class LintContext {
  /// The raw commit message string
  final String commitStr;

  /// The parsed commit message
  final CommitMessage message;

  /// The configuration used for the rules
  final LintConfig config;

  // ignore: public_member_api_docs
  const LintContext({
    required this.commitStr,
    required this.message,
    required this.config,
  });
}

/// A rule used to validate commit messages.
class LintRule {
  /// A unique identifier for this rule
  ///
  /// NOTE: Currently unused
  final String key;

  /// The validator function for this rule
  final LintValidator validator;

  final String? _invalidMessageString;
  final LintInvalidMessage? _invalidMessageFn;

  /// Generate an message when the message does not pass this rule.
  ///
  /// See [LintRule] constructor.
  String invalidMessage(LintContext context) {
    if (_invalidMessageFn is LintInvalidMessage) {
      return _invalidMessageFn(context);
    }
    return _invalidMessageString.toString();
  }

  /// Creates a LintRule
  ///
  /// If an [invalidMessageFn] is provided, it will be used to create the
  /// feedback [LintContext.message] when the message does not pass the rule.
  /// Otherwise, [invalidMessage] is used.
  const LintRule(
    this.key, {
    required this.validator,
    String? invalidMessage,
    LintInvalidMessage? invalidMessageFn,
  })  : _invalidMessageFn = invalidMessageFn,
        _invalidMessageString = invalidMessage ?? 'NO MESSAGE';

  /// Checks whether the provided [context] (specifically [LintContext.message])
  /// is valid
  bool isValid(LintContext context) => validator(context);
}

/// The default rules used for linting
final List<LintRule> defaultRules = [
  LintRule(
    'header-max-length',
    validator: (context) =>
        context.config.maxHeaderLength >
        context.message.header.toString().length,
    invalidMessage: 'Header is too long.',
  ),
  LintRule(
    'has-description',
    validator: (context) => context.message.description.isNotEmpty,
    invalidMessage: 'Please provide a valid description.',
  ),
  LintRule(
    'scope-format',
    validator: (context) {
      final message = context.message;
      if (!message.isConventional) {
        final header = message.header.toString();
        if (header.contains(':')) {
          final typePart = header.split(':').first;
          if ((typePart.contains('(') || typePart.contains(')')) &&
              message.type.isEmpty) {
            return false;
          }
        }
      }
      return true;
    },
    invalidMessage:
        'Format header like "type: description", or "type(parser): description").',
  ),
  LintRule(
    'type-empty',
    validator: (context) => context.message.type.isNotEmpty,
    invalidMessage: 'No commit type.',
  ),
  LintRule(
    'type-case',
    validator: (context) => _isLowerCase(context.message.type),
    invalidMessageFn: (context) => 'Type should be in lowercase.',
  ),
  LintRule(
    'scope-case',
    validator: (context) => _isLowerCase(context.message.scope),
    invalidMessageFn: (context) => 'Scope should be in lowercase.',
  ),
  LintRule(
    'has-valid-type',
    validator: (context) => context.config.types.contains(context.message.type),
    invalidMessageFn: (context) =>
        'Type "${context.message.type}" is unknown. Valid types are ${context.config.typesDisplay}.',
  ),
];

bool _isLowerCase(String str) {
  return str == str.toLowerCase();
}

/// Checks whether a commit message follows [rules]
LintResult lintCommit(
  String commitMessage, {
  LintConfig? config,
  List<LintRule>? rules,
}) {
  config ??= LintConfig.defaultConfig;
  bool valid = true;
  String errorMessage = '';
  rules ??= defaultRules;
  final message = CommitMessage.parse(commitMessage);
  final context = LintContext(
    commitStr: commitMessage,
    config: config,
    message: message,
  );
  for (final rule in rules) {
    if (!rule.isValid(context)) {
      valid = false;
      errorMessage = rule.invalidMessage(context);
      break;
    }
  }
  return LintResult(valid: valid, message: errorMessage);
}
