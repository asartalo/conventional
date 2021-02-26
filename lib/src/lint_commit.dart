part of '../conventional.dart';

class LintConfig with EquatableMixin {
  final Set<String> types;
  final int maxHeaderLength;

  const LintConfig({
    required this.types,
    required this.maxHeaderLength,
  });

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

  String get typesDisplay => types.toList().join(',');

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

class LintResult with EquatableMixin {
  final bool valid;
  final String message;

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

typedef LintValidator = bool Function(LintContext context);
typedef LintInvalidMessage = String Function(LintContext context);

class LintContext {
  final String commitStr;
  final CommitMessage message;
  final LintConfig config;

  const LintContext({
    required this.commitStr,
    required this.message,
    required this.config,
  });
}

class LintRule {
  final String key;
  final LintValidator validator;
  final String? _invalidMessageString;
  final LintInvalidMessage? _invalidMessageFn;

  String invalidMessage(LintContext context) {
    if (_invalidMessageFn is LintInvalidMessage) {
      return _invalidMessageFn!(context);
    }
    return _invalidMessageString.toString();
  }

  const LintRule(
    this.key, {
    required this.validator,
    String? invalidMessage,
    LintInvalidMessage? invalidMessageFn,
  })  : _invalidMessageFn = invalidMessageFn,
        _invalidMessageString = invalidMessage;

  bool isValid(LintContext context) => validator(context);
}

final List<LintRule> rules = [
  LintRule(
    'header-max-length',
    validator: (context) =>
        context.config.maxHeaderLength > context.message.header.length,
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
        final header = message.header;
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

LintResult lintCommit(
  String commitMessage, {
  LintConfig? config,
}) {
  config ??= LintConfig.defaultConfig;
  bool valid = true;
  String errorMessage = '';
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
