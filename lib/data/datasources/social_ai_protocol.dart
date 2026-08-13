import 'dart:convert';

import '../../core/errors/analysis_exception.dart';
import '../../domain/entities/finding.dart';
import 'ai_datasource.dart';

/// Prompt y parser JSON compartidos por todos los proveedores de IA.
///
/// Centraliza la construcción del mensaje OSINT y la interpretación de la
/// respuesta para que ningún proveedor repita esta lógica.
class SocialAiJsonProtocol {
  SocialAiJsonProtocol._();

  /// Instrucciones de sistema: pautas éticas y formato de respuesta.
  static String systemPrompt() {
    return [
      'Eres un asistente de análisis OSINT. Solo trabajas con información',
      'pública y aportada por el usuario en el mensaje. NO debes inventar',
      'datos ni acceder a perfiles privados. Debes diferenciar entre hechos',
      'observados, datos declarados y suposiciones, asignando un nivel de',
      'confianza honesto. No realices diagnósticos psicológicos ni infieras',
      'atributos sensibles.',
      'Responde SIEMPRE en JSON estricto con esta estructura:',
      '{',
      '  "username": "usuario o alias detectado (o cadena vacía)",',
      '  "summary": "resumen breve y objetivo del contenido en español",',
      '  "findings": [',
      '    {',
      '      "category": "identity|organization|project|content|metadata|other",',
      '      "description": "qué se observa",',
      '      "content": "dato o detalle extraído",',
      '      "confidence": 0.0,',
      '      "evidence": "texto literal de apoyo del contenido aportado o ',
      '                  nota indicando que es una inferencia razonable"',
      '    }',
      '  ]',
      '}',
    ].join('\n');
  }

  /// Mensaje de usuario con el contenido público aportado.
  static String userPrompt(String platform, String content, String? url) {
    return [
      'Plataforma: $platform',
      if (url != null && url.trim().isNotEmpty) 'URL del perfil: $url',
      '',
      'Contenido público aportado para analizar:',
      '---',
      content,
      '---',
      '',
      'Extrae los hallazgos relevantes siguiendo el formato JSON indicado.',
    ].join('\n');
  }

  /// Interpreta la respuesta textual de la IA como [SocialAiResponse].
  static SocialAiResponse parse(String raw) {
    final decoded = _decodeJsonObject(raw);

    final username = (decoded['username'] as String?)?.trim() ?? '';
    final summary = (decoded['summary'] as String?)?.trim() ?? '';
    final findings = <Finding>[];
    final rawFindings = (decoded['findings'] as List<dynamic>?) ?? const [];

    for (var i = 0; i < rawFindings.length; i++) {
      final item = rawFindings[i];
      if (item is! Map<String, dynamic>) continue;
      final description = (item['description'] as String?)?.trim() ?? '';
      final content = (item['content'] as String?)?.trim() ?? '';
      if (description.isEmpty || content.isEmpty) continue;

      var confidence = (item['confidence'] as num?)?.toDouble() ?? 0.5;
      confidence = confidence.clamp(0.0, 1.0);
      final evidence = (item['evidence'] as String?)?.trim();
      final categoryName = (item['category'] as String?) ?? '';

      findings.add(
        Finding(
          id: 'ai-${DateTime.now().microsecondsSinceEpoch}-$i',
          sourceId: '',
          category: FindingCategory.values.asNameMap()[categoryName] ??
              FindingCategory.other,
          description: description,
          content: content,
          confidence: confidence,
          evidence: evidence == null || evidence.isEmpty
              ? 'Análisis IA de contenido público aportado por el usuario'
              : evidence,
          timestamp: DateTime.now(),
        ),
      );
    }

    return SocialAiResponse(
      username: username,
      summary: summary,
      findings: findings,
    );
  }

  /// Decodifica el JSON de la respuesta tolerando bloques de código o
  /// texto adicional alrededor del objeto.
  static Map<String, dynamic> _decodeJsonObject(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text
          .replaceFirst(RegExp(r'^```[a-zA-Z0-9_-]*\n'), '')
          .replaceFirst(RegExp(r'\n```\s*$'), '');
    }

    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // Intenta extraer el primer objeto JSON embebido.
    }

    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start >= 0 && end > start) {
      final candidate = text.substring(start, end + 1);
      try {
        final decoded = jsonDecode(candidate);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {
        // Se propaga el error original.
      }
    }

    throw const AnalysisException('La IA devolvió JSON inválido.');
  }

  static String truncate(String value, [int limit = 300]) =>
      value.length <= limit ? value : '${value.substring(0, limit)}…';
}