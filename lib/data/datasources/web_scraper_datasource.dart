import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../../core/errors/analysis_exception.dart';
import '../../core/network/http_native_client.dart';
import '../models/web_page_data.dart';

/// Datasource que consulta páginas web públicas y extrae metadatos
/// (OpenGraph, título y descripción).
class WebScraperDatasource {
  final HttpNativeClient _client;

  const WebScraperDatasource(this._client);

  Future<WebPageData> fetch(String url) async {
    final response = await _client.get(url);

    if (!response.isSuccess) {
      throw AnalysisException(
        'No se pudo acceder a la página (HTTP ${response.statusCode}).',
      );
    }

    final document = html_parser.parse(response.body);

    final title = _metaContent(document, property: 'og:title') ??
        document.querySelector('title')?.text.trim() ??
        '';
    final description = _metaContent(document, property: 'og:description') ??
        _metaContent(document, name: 'description') ??
        '';
    final siteName = _metaContent(document, property: 'og:site_name');
    final ogType = _metaContent(document, property: 'og:type');
    final canonical = document
        .querySelector('link[rel="canonical"]')
        ?.attributes['href']
        ?.trim();

    final headings = document
        .querySelectorAll('h1')
        .map((element) => element.text.trim())
        .where((text) => text.isNotEmpty)
        .take(5)
        .toList();

    return WebPageData(
      url: response.finalUrl,
      title: title,
      description: description,
      siteName: siteName,
      ogType: ogType,
      canonical: canonical,
      headings: headings,
    );
  }

  String? _metaContent(
    Document document, {
    String? property,
    String? name,
  }) {
    for (final meta in document.querySelectorAll('meta')) {
      final attributes = meta.attributes;
      if (property != null &&
          attributes['property']?.toLowerCase() == property.toLowerCase()) {
        final content = attributes['content']?.trim();
        if (content != null && content.isNotEmpty) return content;
      }
      if (name != null &&
          attributes['name']?.toLowerCase() == name.toLowerCase()) {
        final content = attributes['content']?.trim();
        if (content != null && content.isNotEmpty) return content;
      }
    }
    return null;
  }
}
