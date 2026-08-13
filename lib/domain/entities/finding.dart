/// Categoría de un hallazgo OSINT.
enum FindingCategory {
  identity,
  organization,
  project,
  content,
  metadata,
  other,
}

extension FindingCategoryLabel on FindingCategory {
  String get label => switch (this) {
        FindingCategory.identity => 'Identidad',
        FindingCategory.organization => 'Organización',
        FindingCategory.project => 'Proyecto',
        FindingCategory.content => 'Contenido',
        FindingCategory.metadata => 'Metadatos',
        FindingCategory.other => 'Otro',
      };
}

/// Hallazgo asociado a una fuente dentro de una investigación.
class Finding {
  final String id;
  final String sourceId;
  final FindingCategory category;
  final String description;
  final String content;
  final double confidence;
  final String? evidence;
  final DateTime timestamp;

  const Finding({
    required this.id,
    required this.sourceId,
    required this.category,
    required this.description,
    required this.content,
    required this.confidence,
    required this.timestamp,
    this.evidence,
  });

  Finding copyWith({
    String? sourceId,
    FindingCategory? category,
    String? description,
    String? content,
    double? confidence,
    String? evidence,
    DateTime? timestamp,
  }) {
    return Finding(
      id: id,
      sourceId: sourceId ?? this.sourceId,
      category: category ?? this.category,
      description: description ?? this.description,
      content: content ?? this.content,
      confidence: confidence ?? this.confidence,
      evidence: evidence ?? this.evidence,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
