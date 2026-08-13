import '../../domain/entities/analysis_result.dart';
import '../../domain/entities/source.dart';
import '../../domain/repositories/social_analysis_repository.dart';
import '../datasources/ai_datasource.dart';

/// Implementación del análisis social asistido por IA.
class SocialAnalysisRepositoryImpl implements SocialAnalysisRepository {
  final AiDatasource _aiDatasource;

  const SocialAnalysisRepositoryImpl(this._aiDatasource);

  @override
  Future<AnalysisResult> analyzeSocial({
    required String platform,
    required String content,
    String? url,
  }) async {
    final response = await _aiDatasource.analyzeSocialContent(
      platform: platform,
      content: content,
      url: url,
    );

    final trimmedUrl = url?.trim() ?? '';
    final consultedAt = DateTime.now();

    return AnalysisResult(
      url: trimmedUrl.isEmpty ? 'perfil://${platform.toLowerCase()}' : trimmedUrl,
      finalUrl: trimmedUrl,
      title: response.username.isEmpty ? 'Perfil de $platform' : response.username,
      description: response.summary,
      sourceType: SourceType.social,
      consultedAt: consultedAt,
      findings: response.findings,
      providerLabel: response.providerLabel,
    );
  }
}
