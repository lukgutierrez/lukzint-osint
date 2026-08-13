import 'package:flutter_test/flutter_test.dart';
import 'package:osint_social_analyzer/core/network/http_native_client.dart';
import 'package:osint_social_analyzer/data/datasources/web_scraper_datasource.dart';

class _FakeNativeHttp extends HttpNativeClient {
  _FakeNativeHttp() : super(timeout: const Duration(seconds: 5));

  @override
  Future<NativeHttpResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    const html = '''
<!DOCTYPE html>
<html>
<head>
  <title>Mi Página</title>
  <meta name="description" content="Descripción meta">
  <meta property="og:title" content="Título OpenGraph">
  <meta property="og:description" content="Descripción OpenGraph">
  <meta property="og:site_name" content="Sitio Ejemplo">
  <meta property="og:type" content="website">
  <link rel="canonical" href="https://example.com/">
</head>
<body>
  <h1>Encabezado Uno</h1>
  <h1>Encabezado Dos</h1>
</body>
</html>
''';
    return NativeHttpResponse(
      statusCode: 200,
      body: html,
      headers: const {},
      finalUrl: url,
    );
  }
}

void main() {
  group('WebScraperDatasource', () {
    test('extrae metadatos OpenGraph, título y encabezados', () async {
      final scraper = WebScraperDatasource(_FakeNativeHttp());
      final page = await scraper.fetch('https://example.com');

      expect(page.url, 'https://example.com');
      expect(page.title, 'Título OpenGraph');
      expect(page.description, 'Descripción OpenGraph');
      expect(page.siteName, 'Sitio Ejemplo');
      expect(page.ogType, 'website');
      expect(page.canonical, 'https://example.com/');
      expect(page.headings, contains('Encabezado Uno'));
      expect(page.headings, contains('Encabezado Dos'));
    });

    test('lanza AnalysisException en errores HTTP', () async {
      final scraper = WebScraperDatasource(_ErrorHttp());
      expect(
        () => scraper.fetch('https://example.com'),
        throwsA(isA<Object>()),
      );
    });
  });
}

class _ErrorHttp extends HttpNativeClient {
  _ErrorHttp() : super(timeout: const Duration(seconds: 5));

  @override
  Future<NativeHttpResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    return NativeHttpResponse(
      statusCode: 403,
      body: '',
      headers: const {},
      finalUrl: url,
    );
  }
}
