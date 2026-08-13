/// Tipo de fuente OSINT analizada.
enum SourceType { web, github, organization, social }

/// Estado del análisis de una fuente.
enum SourceStatus { pending, analyzing, analyzed, failed }

extension SourceTypeLabel on SourceType {
  String get label => switch (this) {
        SourceType.web => 'Web',
        SourceType.github => 'GitHub',
        SourceType.organization => 'Organización',
        SourceType.social => 'Red social',
      };
}

extension SourceStatusLabel on SourceStatus {
  String get label => switch (this) {
        SourceStatus.pending => 'Pendiente',
        SourceStatus.analyzing => 'Analizando',
        SourceStatus.analyzed => 'Analizada',
        SourceStatus.failed => 'Fallida',
      };
}

/// Fuente pública registrada en una investigación.
class Source {
  final String id;
  final String url;
  final String finalUrl;
  final String title;
  final String description;
  final SourceType type;
  final SourceStatus status;
  final DateTime consultedAt;
  final String? error;

  const Source({
    required this.id,
    required this.url,
    required this.finalUrl,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.consultedAt,
    this.error,
  });

  Source copyWith({
    String? url,
    String? finalUrl,
    String? title,
    String? description,
    SourceType? type,
    SourceStatus? status,
    DateTime? consultedAt,
    String? error,
  }) {
    return Source(
      id: id,
      url: url ?? this.url,
      finalUrl: finalUrl ?? this.finalUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      consultedAt: consultedAt ?? this.consultedAt,
      error: error ?? this.error,
    );
  }
}
