import 'dart:convert';

import '../../core/errors/analysis_exception.dart';
import '../../core/network/http_native_client.dart';
import '../models/github_profile.dart';

/// Datasource de la API pública oficial de GitHub.
class GithubApiDatasource {
  final HttpNativeClient _client;

  const GithubApiDatasource(this._client);

  static const String _baseUrl = 'https://api.github.com/users/';

  Future<GithubProfile> fetchProfile(String username) async {
    final response = await _client.get(
      '$_baseUrl$username',
      headers: const {'Accept': 'application/vnd.github+json'},
    );

    if (response.statusCode == 404) {
      throw AnalysisException(
        'Perfil público de GitHub "$username" no encontrado (404).',
      );
    }
    if (!response.isSuccess) {
      throw AnalysisException(
        'GitHub API respondió con error (HTTP ${response.statusCode}).',
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw AnalysisException('Respuesta inválida de GitHub API.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw AnalysisException('Respuesta inválida de GitHub API.');
    }

    return GithubProfile.fromJson(decoded);
  }
}
