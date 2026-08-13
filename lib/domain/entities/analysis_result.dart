import 'finding.dart';
import 'source.dart';

/// Resultado normalizado del análisis de una fuente pública.
class AnalysisResult {
  final String url;
  final String finalUrl;
  final String title;
  final String description;
  final SourceType sourceType;
  final DateTime consultedAt;
  final List<Finding> findings;

  /// Proveedor de IA utilizado (solo para análisis asistido por IA).
  final String providerLabel;

  const AnalysisResult({
    required this.url,
    required this.finalUrl,
    required this.title,
    required this.description,
    required this.sourceType,
    required this.consultedAt,
    required this.findings,
    this.providerLabel = '',
  });
}
