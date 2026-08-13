import '../../domain/entities/source.dart';

/// Serialización JSON de una [Source].
class SourceModel {
  SourceModel._();

  static Source fromJson(Map<String, dynamic> json) {
    return Source(
      id: json['id'] as String,
      url: json['url'] as String,
      finalUrl: (json['finalUrl'] as String?) ?? (json['url'] as String),
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      type: SourceType.values.asNameMap()[json['type']] ?? SourceType.web,
      status:
          SourceStatus.values.asNameMap()[json['status']] ??
              SourceStatus.analyzed,
      consultedAt: DateTime.parse(json['consultedAt'] as String),
      error: json['error'] as String?,
    );
  }

  static Map<String, dynamic> toJson(Source source) {
    return {
      'id': source.id,
      'url': source.url,
      'finalUrl': source.finalUrl,
      'title': source.title,
      'description': source.description,
      'type': source.type.name,
      'status': source.status.name,
      'consultedAt': source.consultedAt.toIso8601String(),
      'error': source.error,
    };
  }
}
