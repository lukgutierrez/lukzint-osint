import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:osint_social_analyzer/core/errors/analysis_exception.dart';
import 'package:osint_social_analyzer/core/network/http_native_client.dart';
import 'package:osint_social_analyzer/data/datasources/github_api_datasource.dart';
import 'package:osint_social_analyzer/data/datasources/web_scraper_datasource.dart';
import 'package:osint_social_analyzer/data/repositories/analysis_repository_impl.dart';
import 'package:osint_social_analyzer/domain/entities/finding.dart';
import 'package:osint_social_analyzer/domain/entities/source.dart';

class _RoutingHttp extends HttpNativeClient {
  _RoutingHttp() : super(timeout: const Duration(seconds: 5));

  @override
  Future<NativeHttpResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    if (url.contains('api.github.com')) {
      final payload = {
        'login': 'octo',
        'name': 'Octocat',
        'bio': 'Bio pública',
        'company': null,
        'location': 'San Francisco',
        'blog': '',
        'twitter_username': null,
        'html_url': 'https://github.com/octo',
        'public_repos': 42,
        'followers': 100,
        'following': 10,
        'created_at': '2015-01-01T00:00:00Z',
      };
      return NativeHttpResponse(
        statusCode: 200,
        body: jsonEncode(payload),
        headers: const {},
        finalUrl: url,
      );
    }
    const html = '''
<html><head>
  <title>Sitio Web</title>
  <meta property="og:title" content="Título del Sitio">
  <meta name="description" content="Descripción del sitio">
  <meta property="og:site_name" content="Sitio Ejemplo">
</head><body><h1>Bienvenidos</h1></body></html>
''';
    return NativeHttpResponse(
      statusCode: 200,
      body: html,
      headers: const {},
      finalUrl: url,
    );
  }
}

AnalysisRepositoryImpl _repository() {
  final client = _RoutingHttp();
  return AnalysisRepositoryImpl(
    GithubApiDatasource(client),
    WebScraperDatasource(client),
  );
}

void main() {
  group('AnalysisRepositoryImpl', () {
    test('analiza perfiles públicos de GitHub', () async {
      final result = await _repository().analyzeUrl('https://github.com/octo');

      expect(result.sourceType, SourceType.github);
      expect(result.title, 'Octocat');
      expect(result.findings, isNotEmpty);
      expect(
        result.findings.any((f) => f.category == FindingCategory.identity),
        isTrue,
      );
      expect(
        result.findings.any((f) => f.description == 'Repositorios públicos'),
        isTrue,
      );
    });

    test('analiza páginas web generales', () async {
      final result = await _repository().analyzeUrl('https://example.com');

      expect(result.sourceType, SourceType.web);
      expect(result.title, 'Título del Sitio');
      expect(result.description, 'Descripción del sitio');
      expect(
        result.findings.any((f) => f.description == 'Título de la página'),
        isTrue,
      );
      expect(
        result.findings.any((f) => f.description == 'Encabezado principal'),
        isTrue,
      );
    });

    test('rechaza URLs inválidas', () {
      expect(
        () => _repository().analyzeUrl('no-scheme.com'),
        throwsA(isA<AnalysisException>()),
      );
    });
  });
}
