import 'dart:convert';

import 'package:http/http.dart' as http;

/// Cliente HTTP nativo para peticiones OSINT a fuentes públicas.
class HttpNativeClient {
  final http.Client _client;
  final Duration timeout;
  final Map<String, String> _defaultHeaders;

  HttpNativeClient({
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
    String? userAgent,
  })  : _client = client ?? http.Client(),
        _defaultHeaders = {
          'User-Agent':
              userAgent ?? 'OSINT-Social-Analyzer/1.0 (Flutter; public-info)',
          'Accept': 'text/html,application/json,application/xhtml+xml,*/*',
        };

  Future<NativeHttpResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse(url);
    final request = http.Request('GET', uri);
    request.headers.addAll(_defaultHeaders);
    if (headers != null) {
      request.headers.addAll(headers);
    }

    final streamed = await _client.send(request).timeout(timeout);
    final response =
        await http.Response.fromStream(streamed).timeout(timeout);

    return NativeHttpResponse(
      statusCode: response.statusCode,
      body: utf8.decode(response.bodyBytes, allowMalformed: true),
      headers: response.headers,
      finalUrl: response.request?.url.toString() ?? url,
    );
  }

  void close() => _client.close();
}

/// Respuesta normalizada de una petición HTTP.
class NativeHttpResponse {
  final int statusCode;
  final String body;
  final Map<String, String> headers;
  final String finalUrl;

  NativeHttpResponse({
    required this.statusCode,
    required this.body,
    required this.headers,
    required this.finalUrl,
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}
