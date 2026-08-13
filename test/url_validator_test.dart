import 'package:flutter_test/flutter_test.dart';
import 'package:osint_social_analyzer/core/utils/url_validator.dart';

void main() {
  group('UrlValidator.validate', () {
    test('acepta URLs http/https válidas', () {
      expect(UrlValidator.validate('https://example.com'), isNull);
      expect(UrlValidator.validate('http://example.com/path'), isNull);
      expect(UrlValidator.validate('  https://example.com  '), isNull);
    });

    test('rechaza URLs sin esquema', () {
      expect(UrlValidator.validate('example.com'), isNotNull);
      expect(UrlValidator.validate('ftp://example.com'), isNotNull);
      expect(UrlValidator.validate(''), isNotNull);
    });
  });

  group('UrlValidator.github', () {
    test('detecta perfiles de GitHub', () {
      expect(
        UrlValidator.isGithubProfile('https://github.com/torvalds'),
        isTrue,
      );
      expect(
        UrlValidator.isGithubProfile('https://www.github.com/torvalds'),
        isTrue,
      );
      expect(UrlValidator.isGithubProfile('https://github.com/'), isFalse);
      expect(
        UrlValidator.isGithubProfile('https://github.com/torvalds/repo'),
        isFalse,
      );
    });

    test('extrae el nombre de usuario', () {
      expect(
        UrlValidator.githubUsername('https://github.com/torvalds'),
        'torvalds',
      );
      expect(
        UrlValidator.githubUsername('https://www.github.com/octo-cat'),
        'octo-cat',
      );
    });
  });
}
