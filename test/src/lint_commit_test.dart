import 'package:conventional/conventional.dart';
import 'package:test/test.dart';

void main() {
  const defaultConfig = LintConfig.defaultConfig;
  group('LintConfig', () {
    group('#override()', () {
      late LintConfig config;

      setUp(() {
        config = defaultConfig.copyWith(maxHeaderLength: 72);
      });

      test('it can override maxHeaderLength', () {
        expect(config.maxHeaderLength, equals(72));
      });

      test('it retains types', () {
        expect(config.types, equals(defaultConfig.types));
      });
    });
  });

  group('lintCommit()', () {
    group('valid commit messages', () {
      final List<_ST> validTestData = [
        _ST('basic simple messages', commit: 'feat: jump feature'),
        _ST('basic with breaking', commit: 'feat!: null-safety'),
        _ST(
          'custom type',
          commit: 'foo: with custom type',
          config: defaultConfig.copyWith(
            types: Set<String>.from(
              defaultConfig.types.toList() + ['foo'],
            ),
          ),
        ),
      ];

      for (final data in validTestData) {
        test(data.description, () {
          final result = lintCommit(data.commit, config: data.config);
          expect(result.valid, true, reason: result.message);
        });
      }
    });

    group('invalid commit messages', () {
      final List<_FT> testData = [
        _FT(
          'header is too long',
          commit:
              'fix: hello this message is too long so i do not know if this should work but it should not',
          result: 'Header is too long.',
        ),
        _FT(
          'no type',
          commit: 'this is just the message',
          result: 'No commit type.',
        ),
        _FT(
          'bad scope format',
          commit: 'fix(head: quick fox',
          result:
              'Format header like "type: description", or "type(parser): description").',
        ),
        _FT(
          'no description',
          commit: 'chore: ',
          result: 'Please provide a valid description.',
        ),
        _FT(
          'invalid type',
          commit: 'foo: unknown type',
          result:
              'Type "foo" is unknown. Valid types are ${defaultConfig.typesDisplay}.',
        ),
        _FT(
          'type is not lowercase',
          commit: 'Fix: unknown type',
          result: 'Type should be in lowercase.',
        ),
        _FT(
          'scope should be lowercase',
          commit: 'fix(lEgs): unknown type',
          result: 'Scope should be in lowercase.',
        ),
      ];

      for (final data in testData) {
        test(data.description, () {
          final result = lintCommit(data.commit);
          expect(result.valid, false);
          expect(result.message, equals(data.result));
        });
      }
    });
  });
}

class _ST {
  final String description;
  final String commit;
  final LintConfig? config;

  _ST(
    this.description, {
    required this.commit,
    this.config,
  });
}

class _FT {
  final String description;
  final String commit;
  final String result;
  final LintConfig? config;

  _FT(
    this.description, {
    required this.commit,
    required this.result,
    this.config,
  });
}
