import '../../domain/entities/investigation.dart';
import 'finding_model.dart';
import 'relationship_model.dart';
import 'social_link_model.dart';
import 'source_model.dart';
import 'target_profile_model.dart';

/// Serialización JSON de una [Investigation].
class InvestigationModel {
  InvestigationModel._();

  static Investigation fromJson(Map<String, dynamic> json) {
    final sources = (json['sources'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(SourceModel.fromJson)
        .toList();
    final findings = (json['findings'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(FindingModel.fromJson)
        .toList();
    final socialLinks = (json['socialLinks'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(SocialLinkModel.fromJson)
        .toList();
    final relationships = (json['relationships'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(RelationshipModel.fromJson)
        .toList();

    return Investigation(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? 'Sin título',
      objective: (json['objective'] as String?) ?? '',
      status: InvestigationStatus.values.asNameMap()[json['status']] ??
          InvestigationStatus.inProgress,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      sources: sources,
      findings: findings,
      targetProfile: TargetProfileModel.fromJson(
        json['targetProfile'] as Map<String, dynamic>?,
      ),
      socialLinks: socialLinks,
      relationships: relationships,
    );
  }

  static Map<String, dynamic> toJson(Investigation investigation) {
    return {
      'id': investigation.id,
      'title': investigation.title,
      'objective': investigation.objective,
      'status': investigation.status.name,
      'createdAt': investigation.createdAt.toIso8601String(),
      'updatedAt': investigation.updatedAt.toIso8601String(),
      'sources': investigation.sources.map(SourceModel.toJson).toList(),
      'findings': investigation.findings.map(FindingModel.toJson).toList(),
      'targetProfile': investigation.targetProfile == null
          ? null
          : TargetProfileModel.toJson(investigation.targetProfile!),
      'socialLinks':
          investigation.socialLinks.map(SocialLinkModel.toJson).toList(),
      'relationships':
          investigation.relationships.map(RelationshipModel.toJson).toList(),
    };
  }
}
