import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/errors/analysis_exception.dart';
import '../../core/settings/ai_provider.dart';
import '../../core/settings/settings_datasource.dart';
import 'ai_datasource.dart';
import 'social_ai_protocol.dart';

/// Implementación de [AiDatasource] para APIs compatibles con el formato
/// OpenAI "chat completions".
///
/// Cubre proveedores gratuitos actuales como [AiProvider.groq],
/// [AiProvider.openrouter] y [AiProvider.mistral], configurados con su
/// URL base y modelo por defecto.
class OpenAiCompatibleAiDatasource implements AiDatasource {
  final SettingsDatasource settings;
  final AiProvider provider;
  final String baseUrl;
  final String model;
  final http.Client _client;

  OpenAiCompatibleAiDatasource({
    required this.settings,
    required this.provider,
    required this.baseUrl,
    required this.model,
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  Future<SocialAiResponse> analyzeSocialContent({
    required String platform,
    required String content,
    String? url,
  }) async {
    final apiKey = await settings.getAiApiKey(provider);
    if (apiKey == null || apiKey.isEmpty) {
      throw AnalysisException(
        'No hay API key configurada para ${provider.label}. Agregala en Ajustes.',
      );
    }

    final uri = Uri.parse('${baseUrl.replaceFirst(RegExp(r'/+$'), '')}/chat/completions');

    final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
              if (provider == AiProvider.openrouter) ...{
                'HTTP-Referer': 'https://localhost.lukzint',
                'X-Title': 'LUKZINT (OSINT Social Analyzer)',
              },
            },
            body: jsonEncode({
              'model': model,
              'messages': [
                {
                  'role': 'system',
                  'content': SocialAiJsonProtocol.systemPrompt(),
                },
                {
                  'role': 'user',
                  'content':
                      SocialAiJsonProtocol.userPrompt(platform, content, url),
                },
              ],
              'temperature': 0.2,
              'max_tokens': 2048,
            }),
          )
          .timeout(const Duration(seconds: 60));
    } on AnalysisException {
      rethrow;
    } catch (e) {
      throw AnalysisException('No se pudo contactar a ${provider.label}: $e');
    }

    if (response.statusCode != 200) {
      throw AnalysisException(
        '${provider.label} respondió ${response.statusCode}: '
        '${SocialAiJsonProtocol.truncate(response.body)}',
      );
    }

    final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (e) {
      throw AnalysisException('Respuesta de ${provider.label} no válida: $e');
    }

    final text = decoded['choices']?[0]?['message']?['content'] as String?;
    if (text == null || text.trim().isEmpty) {
      throw AnalysisException('${provider.label} no devolvió contenido analizable.');
    }

    final parsed = SocialAiJsonProtocol.parse(text);
    return SocialAiResponse(
      username: parsed.username,
      summary: parsed.summary,
      findings: parsed.findings,
      providerLabel: provider.label,
    );
  }
}