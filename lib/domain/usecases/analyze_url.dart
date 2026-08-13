import '../../core/utils/id_generator.dart';
import '../entities/analysis_result.dart';
import '../entities/investigation.dart';
import '../entities/source.dart';
import '../repositories/analysis_repository.dart';
import '../repositories/investigation_repository.dart';

/// Caso de uso: analizar una URL pública y adjuntar sus resultados
/// a una investigación.
class AnalyzeUrl {
  final AnalysisRepository _analysisRepository;
  final InvestigationRepository _investigationRepository;

  const AnalyzeUrl(
    this._analysisRepository,
    this._investigationRepository,
  );

  /// Analiza una URL sin persistir resultados (modo previsualización).
  Future<AnalysisResult> preview(String url) => _analysisRepository.analyzeUrl(url);

  /// Adjunta el resultado de un análisis a una investigación, evitando
  /// fuentes duplicadas.
  Future<Investigation> attach(
    Investigation investigation,
    AnalysisResult result,
  ) async {
    if (investigation.containsUrl(result.url)) {
      return investigation;
    }

    final sourceId = generateId();
    final source = Source(
      id: sourceId,
      url: result.url,
      finalUrl: result.finalUrl,
      title: result.title,
      description: result.description,
      type: result.sourceType,
      status: SourceStatus.analyzed,
      consultedAt: result.consultedAt,
    );

    final findings = result.findings
        .map((finding) => finding.copyWith(sourceId: sourceId))
        .toList();

    final updated = investigation.copyWith(
      sources: [...investigation.sources, source],
      findings: [...investigation.findings, ...findings],
      updatedAt: DateTime.now(),
    );

    return _investigationRepository.save(updated);
  }
}
