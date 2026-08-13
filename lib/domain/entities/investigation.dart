import '../../core/utils/id_generator.dart';
import 'finding.dart';
import 'relationship.dart';
import 'social_link.dart';
import 'source.dart';
import 'target_profile.dart';

/// Estado general de una investigación.
enum InvestigationStatus { draft, inProgress, completed }

extension InvestigationStatusLabel on InvestigationStatus {
  String get label => switch (this) {
        InvestigationStatus.draft => 'Borrador',
        InvestigationStatus.inProgress => 'En progreso',
        InvestigationStatus.completed => 'Completada',
      };
}

/// Investigación OSINT con sus fuentes y hallazgos.
class Investigation {
  final String id;
  final String title;
  final String objective;
  final InvestigationStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Source> sources;
  final List<Finding> findings;
  final TargetProfile? targetProfile;
  final List<SocialLink> socialLinks;
  final List<Relationship> relationships;

  const Investigation({
    required this.id,
    required this.title,
    required this.objective,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.sources,
    required this.findings,
    this.targetProfile,
    this.socialLinks = const [],
    this.relationships = const [],
  });

  factory Investigation.create({
    required String title,
    required String objective,
  }) {
    final now = DateTime.now();
    return Investigation(
      id: generateId(),
      title: title,
      objective: objective,
      status: InvestigationStatus.inProgress,
      createdAt: now,
      updatedAt: now,
      sources: const [],
      findings: const [],
      socialLinks: const [],
      relationships: const [],
    );
  }

  int get sourceCount => sources.length;

  int get findingCount => findings.length;

  bool containsUrl(String url) =>
      sources.any((s) => s.url == url || s.finalUrl == url);

  Investigation copyWith({
    String? title,
    String? objective,
    InvestigationStatus? status,
    DateTime? updatedAt,
    List<Source>? sources,
    List<Finding>? findings,
    TargetProfile? targetProfile,
    List<SocialLink>? socialLinks,
    List<Relationship>? relationships,
  }) {
    return Investigation(
      id: id,
      title: title ?? this.title,
      objective: objective ?? this.objective,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sources: sources ?? this.sources,
      findings: findings ?? this.findings,
      targetProfile: targetProfile ?? this.targetProfile,
      socialLinks: socialLinks ?? this.socialLinks,
      relationships: relationships ?? this.relationships,
    );
  }
}
