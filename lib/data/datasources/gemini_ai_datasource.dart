import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/errors/analysis_exception.dart';
import '../../core/settings/settings_datasource.dart';
import 'ai_datasource.dart';
import 'social_ai_protocol.dart';

/// Implementación de [AiDatasource] usando la API de Google Gemini.
///
/// El modelo devuelve JSON estructurado con los hallazgos detectados
/// en el contenido público aportado por el usuario.
class GeminiAiDatasource implements AiDatasource {
  final SettingsDatasource settings;
  final http.Client _client;
  final String model;

  GeminiAiDatasource({
    required this.settings,
    http.Client? client,
    this.model = 'gemini-3.5-flash',
  }) : _client = client ?? http.Client();

  @override
  Future<SocialAiResponse> analyzeSocialContent({
    required String platform,
    required String content,
    String? url,
  }) async {
    final apiKey = await settings.getGeminiApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw const AnalysisException(
        'No hay API key configurada para Google Gemini. Agregala en Ajustes.',
      );
    }

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
    );

    final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'systemInstruction': {
                'parts': [
                  {'text': SocialAiJsonProtocol.systemPrompt()},
                ],
              },
              'contents': [
                {
                  'parts': [
                    {
                      'text': SocialAiJsonProtocol.userPrompt(platform, content, url),
                    },
                  ],
                },
              ],
              'generationConfig': {'responseMimeType': 'application/json'},
            }),
          )
          .timeout(const Duration(seconds: 60));
    } catch (e) {
      throw AnalysisException('No se pudo contactar a Google Gemini: $e');
    }

    if (response.statusCode != 200) {
      throw AnalysisException(
        'Google Gemini respondió ${response.statusCode}: '
        '${SocialAiJsonProtocol.truncate(response.body)}',
      );
    }

    final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (e) {
      throw AnalysisException('Respuesta de Google Gemini no válida: $e');
    }

    final text =
        decoded['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
    if (text == null || text.trim().isEmpty) {
      throw const AnalysisException('Google Gemini no devolvió contenido analizable.');
    }

    final parsed = SocialAiJsonProtocol.parse(text);
    return SocialAiResponse(
      username: parsed.username,
      summary: parsed.summary,
      findings: parsed.findings,
      providerLabel: 'Google Gemini',
    );
  }
}