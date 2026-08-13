import '../../core/errors/analysis_exception.dart';
import '../entities/analysis_result.dart';
import '../repositories/social_analysis_repository.dart';

/// Caso de uso: analizar con IA el contenido público aportado por el
/// usuario sobre un perfil de red social.
class AnalyzeSocial {
  final SocialAnalysisRepository _repository;

  const AnalyzeSocial(this._repository);

  Future<AnalysisResult> call({
    required String platform,
    required String content,
    String? url,
  }) async {
    if (content.trim().isEmpty) {
      throw const AnalysisException('Introduce contenido público para analizar.');
    }
    return _repository.analyzeSocial(
      platform: platform,
      content: content,
      url: url,
    );
  }
}
