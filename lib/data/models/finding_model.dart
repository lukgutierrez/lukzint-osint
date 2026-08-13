import '../../domain/entities/finding.dart';

/// Serialización JSON de un [Finding].
class FindingModel {
  FindingModel._();

  static Finding fromJson(Map<String, dynamic> json) {
    return Finding(
      id: json['id'] as String,
      sourceId: (json['sourceId'] as String?) ?? '',
      category:
          FindingCategory.values.asNameMap()[json['category']] ??
              FindingCategory.other,
      description: (json['description'] as String?) ?? '',
      content: (json['content'] as String?) ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      evidence: json['evidence'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  static Map<String, dynamic> toJson(Finding finding) {
    return {
      'id': finding.id,
      'sourceId': finding.sourceId,
      'category': finding.category.name,
      'description': finding.description,
      'content': finding.content,
      'confidence': finding.confidence,
      'evidence': finding.evidence,
      'timestamp': finding.timestamp.toIso8601String(),
    };
  }
}
