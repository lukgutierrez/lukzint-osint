import '../entities/analysis_result.dart';

/// Contrato de análisis asistido por IA sobre contenido público
/// de redes sociales aportado por el usuario.
abstract class SocialAnalysisRepository {
  Future<AnalysisResult> analyzeSocial({
    required String platform,
    required String content,
    String? url,
  });
}
