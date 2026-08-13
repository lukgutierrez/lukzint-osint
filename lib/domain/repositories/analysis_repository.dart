import '../entities/analysis_result.dart';

/// Contrato de análisis de fuentes públicas OSINT.
abstract class AnalysisRepository {
  Future<AnalysisResult> analyzeUrl(String url);
}
