import '../../core/errors/analysis_exception.dart';
import '../../core/settings/ai_provider.dart';
import '../../core/settings/settings_datasource.dart';
import 'ai_datasource.dart';

/// Enrutador de IA con fallback automático entre proveedores.
///
/// Intenta primero el proveedor seleccionado en Ajustes; si falla (sin
/// clave, error de red, límite alcanzado o respuesta inválida) y el
/// fallback está habilitado, prueba los demás proveedores configurados.
class FailoverAiDatasource implements AiDatasource {
  final SettingsDatasource settings;
  final Map<AiProvider, AiDatasource> datasources;

  const FailoverAiDatasource({
    required this.settings,
    required this.datasources,
  });

  @override
  Future<SocialAiResponse> analyzeSocialContent({
    required String platform,
    required String content,
    String? url,
  }) async {
    final providerKeys = await _configuredProviders();
    if (providerKeys.isEmpty) {
      throw const AnalysisException(
        'No hay ningún proveedor de IA configurado. Agregá al menos una '
        'API key en Ajustes antes de analizar.',
      );
    }

    final preferred = await settings.getAiProvider();
    final fallbackEnabled = await settings.getAiFallbackEnabled();

    final attempts = <AiProvider>[];
    if (providerKeys.contains(preferred)) {
      attempts.add(preferred);
    }
    if (fallbackEnabled) {
      for (final provider in AiProvider.values) {
        if (provider != preferred && providerKeys.contains(provider)) {
          attempts.add(provider);
        }
      }
    }

    final errors = <String>[];
    for (final provider in attempts) {
      final datasource = datasources[provider];
      if (datasource == null) continue;
      try {
        return await datasource.analyzeSocialContent(
          platform: platform,
          content: content,
          url: url,
        );
      } catch (e) {
        errors.add('${provider.label}: $e');
      }
    }

    throw AnalysisException(
      'No se pudo completar el análisis con ningún proveedor de IA.\n'
      '${errors.join('\n')}',
    );
  }

  Future<Set<AiProvider>> _configuredProviders() async {
    final configured = <AiProvider>{};
    for (final provider in AiProvider.values) {
      final key = await settings.getAiApiKey(provider);
      if (key != null && key.isNotEmpty) configured.add(provider);
    }
    return configured;
  }
}