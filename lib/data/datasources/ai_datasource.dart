import '../../domain/entities/finding.dart';

/// Respuesta estructurada del análisis de IA.
class SocialAiResponse {
  final String username;
  final String summary;
  final List<Finding> findings;

  /// Nombre del proveedor que produjo el análisis (para mostrarlo en la UI).
  final String providerLabel;

  const SocialAiResponse({
    required this.username,
    required this.summary,
    required this.findings,
    this.providerLabel = 'IA',
  });
}

/// Contrato de análisis de contenido público asistido por IA.
abstract class AiDatasource {
  Future<SocialAiResponse> analyzeSocialContent({
    required String platform,
    required String content,
    String? url,
  });
}