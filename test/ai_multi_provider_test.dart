import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:osint_social_analyzer/core/errors/analysis_exception.dart';
import 'package:osint_social_analyzer/core/settings/ai_provider.dart';
import 'package:osint_social_analyzer/core/settings/settings_datasource.dart';
import 'package:osint_social_analyzer/core/storage/json_storage.dart';
import 'package:osint_social_analyzer/data/datasources/ai_datasource.dart';
import 'package:osint_social_analyzer/data/datasources/failover_ai_datasource.dart';
import 'package:osint_social_analyzer/data/datasources/social_ai_protocol.dart';
import 'package:osint_social_analyzer/domain/entities/relationship.dart';

SettingsDatasource _settings() {
  final dir = Directory.systemTemp.createTempSync('lukzint_ai_test_');
  addTearDown(() => dir.deleteSync(recursive: true));
  return SettingsDatasource(JsonStorage(dir));
}

class _FakeAi implements AiDatasource {
  final String label;
  final bool throws;

  _FakeAi(this.label, {this.throws = false});

  @override
  Future<SocialAiResponse> analyzeSocialContent({
    required String platform,
    required String content,
    String? url,
  }) async {
    if (throws) throw AnalysisException('$label falló');
    return SocialAiResponse(
      username: 'test',
      summary: 'resumen',
      findings: const [],
      providerLabel: label,
    );
  }
}

void main() {
  group('SettingsDatasource multi-proveedor', () {
    test('los valores por defecto son Gemini y fallback activado', () async {
      final settings = _settings();
      expect(await settings.getAiProvider(), AiProvider.gemini);
      expect(await settings.getAiFallbackEnabled(), isTrue);
    });

    test('guarda y recupera las claves de cada proveedor', () async {
      final settings = _settings();
      await settings.setAiApiKey(AiProvider.groq, 'groq-key');
      await settings.setAiApiKey(AiProvider.openrouter, 'or-key');

      expect(await settings.getAiApiKey(AiProvider.groq), 'groq-key');
      expect(await settings.getAiApiKey(AiProvider.openrouter), 'or-key');
      expect(await settings.getAiApiKey(AiProvider.gemini), isNull);
    });

    test('persiste el proveedor principal y el fallback', () async {
      final settings = _settings();
      await settings.setAiProvider(AiProvider.mistral);
      await settings.setAiFallbackEnabled(false);

      expect(await settings.getAiProvider(), AiProvider.mistral);
      expect(await settings.getAiFallbackEnabled(), isFalse);
    });

    test('setGeminiApiKey mantiene compatibilidad', () async {
      final settings = _settings();
      await settings.setGeminiApiKey('AIza-test');
      expect(await settings.getGeminiApiKey(), 'AIza-test');
      expect(await settings.getAiApiKey(AiProvider.gemini), 'AIza-test');
    });
  });

  group('SocialAiJsonProtocol', () {
    test('parsea JSON estricto con hallazgos', () {
      final response = SocialAiJsonProtocol.parse('''
      {
        "username": "@jperez",
        "summary": "Resumen de prueba",
        "findings": [
          {
            "category": "identity",
            "description": "Alias detectado",
            "content": "@jperez",
            "confidence": 0.9,
            "evidence": "bio del perfil"
          }
        ]
      }
      ''');
      expect(response.username, '@jperez');
      expect(response.findings, hasLength(1));
      expect(response.findings.first.content, '@jperez');
      expect(response.findings.first.confidence, closeTo(0.9, 0.001));
    });

    test('tolerante a bloques de código y texto alrededor', () {
      final response = SocialAiJsonProtocol.parse('''
      Aquí va el análisis:\n```json
      {"username": "jperez", "summary": "s", "findings": []}
      ```\nFin.
      ''');
      expect(response.username, 'jperez');
    });

    test('lanza AnalysisException con JSON inválido', () {
      expect(
        () => SocialAiJsonProtocol.parse('esto no es json'),
        throwsA(isA<AnalysisException>()),
      );
    });
  });

  group('FailoverAiDatasource', () {
    test('sin claves configuradas devuelve error claro', () async {
      final settings = _settings();
      final failover = FailoverAiDatasource(
        settings: settings,
        datasources: {
          AiProvider.gemini: _FakeAi('Gemini'),
          AiProvider.groq: _FakeAi('Groq'),
        },
      );

      expect(
        () => failover.analyzeSocialContent(
          platform: 'instagram',
          content: 'texto',
        ),
        throwsA(
          isA<AnalysisException>().having(
            (e) => e.message,
            'message',
            contains('No hay ningún proveedor'),
          ),
        ),
      );
    });

    test('usa el proveedor principal y cae de forma automática', () async {
      final settings = _settings();
      await settings.setAiApiKey(AiProvider.gemini, 'gemini-key');
      await settings.setAiApiKey(AiProvider.groq, 'groq-key');
      await settings.setAiProvider(AiProvider.gemini);

      final failover = FailoverAiDatasource(
        settings: settings,
        datasources: {
          AiProvider.gemini: _FakeAi('Google Gemini', throws: true),
          AiProvider.groq: _FakeAi('Groq'),
        },
      );

      final result = await failover.analyzeSocialContent(
        platform: 'instagram',
        content: 'texto',
      );
      expect(result.providerLabel, 'Groq');
    });

    test('respeta la elección del proveedor principal', () async {
      final settings = _settings();
      await settings.setAiApiKey(AiProvider.gemini, 'gemini-key');
      await settings.setAiApiKey(AiProvider.mistral, 'mistral-key');
      await settings.setAiProvider(AiProvider.mistral);

      final failover = FailoverAiDatasource(
        settings: settings,
        datasources: {
          AiProvider.gemini: _FakeAi('Google Gemini'),
          AiProvider.mistral: _FakeAi('Mistral AI'),
        },
      );

      final result = await failover.analyzeSocialContent(
        platform: 'instagram',
        content: 'texto',
      );
      expect(result.providerLabel, 'Mistral AI');
    });

    test('si fallback está desactivado no prueba los demás', () async {
      final settings = _settings();
      await settings.setAiApiKey(AiProvider.gemini, 'gemini-key');
      await settings.setAiApiKey(AiProvider.groq, 'groq-key');
      await settings.setAiFallbackEnabled(false);

      final failover = FailoverAiDatasource(
        settings: settings,
        datasources: {
          AiProvider.gemini: _FakeAi('Google Gemini', throws: true),
          AiProvider.groq: _FakeAi('Groq'),
        },
      );

      expect(
        () => failover.analyzeSocialContent(
          platform: 'instagram',
          content: 'texto',
        ),
        throwsA(isA<AnalysisException>()),
      );
    });
  });

  group('RelationshipType generaciones', () {
    test('asigna la generación correcta a cada vínculo', () {
      expect(RelationshipType.grandfather.generation, -2);
      expect(RelationshipType.father.generation, -1);
      expect(RelationshipType.brother.generation, 0);
      expect(RelationshipType.son.generation, 1);
      expect(RelationshipType.grandson.generation, 2);
    });
  });
}