/// Utilidades para validar y normalizar URLs de fuentes OSINT.
class UrlValidator {
  UrlValidator._();

  static final RegExp _githubProfile = RegExp(
    r'^https?://(www\.)?github\.com/([A-Za-z0-9_.-]+)/?$',
  );

  /// Devuelve un mensaje de error si la URL no es válida, o `null` si lo es.
  static String? validate(String input) {
    final uri = Uri.tryParse(input.trim());
    if (uri == null || !uri.hasScheme || uri.scheme.isEmpty) {
      return 'La URL debe incluir un esquema (http:// o https://).';
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return 'Solo se permiten URLs con esquema http:// o https://.';
    }
    if (uri.host.isEmpty) {
      return 'La URL debe incluir un host válido.';
    }
    return null;
  }

  static String normalize(String input) => input.trim();

  static bool isGithubProfile(String input) =>
      _githubProfile.hasMatch(input.trim());

  static String? githubUsername(String input) {
    final match = _githubProfile.firstMatch(input.trim());
    return match?.group(2);
  }
}
