import 'package:flutter_test/flutter_test.dart';
import 'package:osint_social_analyzer/core/utils/date_formatter.dart';
import 'package:osint_social_analyzer/data/models/finding_model.dart';
import 'package:osint_social_analyzer/data/models/investigation_model.dart';
import 'package:osint_social_analyzer/data/models/social_link_model.dart';
import 'package:osint_social_analyzer/data/models/source_model.dart';
import 'package:osint_social_analyzer/data/models/target_profile_model.dart';
import 'package:osint_social_analyzer/domain/entities/finding.dart';
import 'package:osint_social_analyzer/domain/entities/investigation.dart';
import 'package:osint_social_analyzer/domain/entities/social_link.dart';
import 'package:osint_social_analyzer/domain/entities/source.dart';
import 'package:osint_social_analyzer/domain/entities/target_profile.dart';

void main() {
  group('SourceModel', () {
    test('round-trip conserva los datos', () {
      final source = Source(
        id: 's1',
        url: 'https://github.com/torvalds',
        finalUrl: 'https://github.com/torvalds',
        title: 'Linus Torvalds',
        description: 'Bio',
        type: SourceType.github,
        status: SourceStatus.analyzed,
        consultedAt: DateTime(2026, 1, 10, 9, 30),
        error: null,
      );

      final restored = SourceModel.fromJson(SourceModel.toJson(source));

      expect(restored.id, 's1');
      expect(restored.type, SourceType.github);
      expect(restored.status, SourceStatus.analyzed);
      expect(restored.title, 'Linus Torvalds');
      expect(restored.consultedAt, DateTime(2026, 1, 10, 9, 30));
    });
  });

  group('FindingModel', () {
    test('round-trip conserva los datos', () {
      final finding = Finding(
        id: 'f1',
        sourceId: 's1',
        category: FindingCategory.identity,
        description: 'Nombre',
        content: 'Linus',
        confidence: 0.95,
        evidence: 'API GitHub',
        timestamp: DateTime(2026, 1, 10, 9, 30),
      );

      final restored = FindingModel.fromJson(FindingModel.toJson(finding));

      expect(restored.id, 'f1');
      expect(restored.sourceId, 's1');
      expect(restored.category, FindingCategory.identity);
      expect(restored.confidence, closeTo(0.95, 0.0001));
      expect(restored.evidence, 'API GitHub');
    });

    test('usa valores por defecto ante campos ausentes', () {
      final restored = FindingModel.fromJson(const {
        'id': 'x',
        'content': 'c',
        'confidence': 0.3,
        'timestamp': '2026-01-01T00:00:00.000',
      });

      expect(restored.category, FindingCategory.other);
      expect(restored.sourceId, '');
    });
  });

  group('InvestigationModel', () {
    test('round-trip conserva la investigación completa', () {
      final source = Source(
        id: 's1',
        url: 'https://example.com',
        finalUrl: 'https://example.com',
        title: 'Ejemplo',
        description: '',
        type: SourceType.web,
        status: SourceStatus.analyzed,
        consultedAt: DateTime(2026, 1, 10),
      );
      final finding = Finding(
        id: 'f1',
        sourceId: 's1',
        category: FindingCategory.metadata,
        description: 'Título',
        content: 'Ejemplo',
        confidence: 0.8,
        timestamp: DateTime(2026, 1, 10),
      );
      final investigation = Investigation(
        id: 'inv1',
        title: 'Análisis',
        objective: 'Objetivo',
        status: InvestigationStatus.inProgress,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 10),
        sources: [source],
        findings: [finding],
        targetProfile: const TargetProfile(
          fullName: 'María López',
          dni: '40.123.456',
          alias: '@mlopez',
          location: 'Buenos Aires',
          photoBase64: 'aGVsbG8=',
        ),
        socialLinks: const [
          SocialLink(
            id: 'sl1',
            platform: SocialPlatform.instagram,
            url: 'https://instagram.com/mlopez',
            username: 'mlopez',
          ),
        ],
      );

      final restored =
          InvestigationModel.fromJson(InvestigationModel.toJson(investigation));

      expect(restored.id, 'inv1');
      expect(restored.title, 'Análisis');
      expect(restored.objective, 'Objetivo');
      expect(restored.status, InvestigationStatus.inProgress);
      expect(restored.sources, hasLength(1));
      expect(restored.findings, hasLength(1));
      expect(restored.sources.first.id, 's1');
      expect(restored.findings.first.sourceId, 's1');
      expect(restored.targetProfile?.fullName, 'María López');
      expect(restored.targetProfile?.dni, '40.123.456');
      expect(restored.targetProfile?.alias, '@mlopez');
      expect(restored.targetProfile?.photoBase64, 'aGVsbG8=');
      expect(restored.socialLinks, hasLength(1));
      expect(restored.socialLinks.first.platform, SocialPlatform.instagram);
      expect(restored.socialLinks.first.url, 'https://instagram.com/mlopez');
    });
  });

  group('TargetProfileModel', () {
    test('round-trip conserva los datos y la foto', () {
      const profile = TargetProfile(
        fullName: 'Juan Pérez',
        dni: '30.654.321',
        cuit: '20-30654321-2',
        alias: '@jperez',
        birthDate: '15/03/1990',
        age: '30',
        location: 'CDMX',
        coordinates: '-34.6037, -58.3816',
        occupation: 'Analista',
        phone: '+54 9 11 5555-1234',
        phoneCarrier: 'Movistar',
        email: 'juan@correo.com',
        notes: 'Nota',
        photoBase64: 'aW1hZ2VuYmluYXJ5',
      );

      final restored = TargetProfileModel.fromJson(
        TargetProfileModel.toJson(profile),
      );

      expect(restored.fullName, 'Juan Pérez');
      expect(restored.dni, '30.654.321');
      expect(restored.cuit, '20-30654321-2');
      expect(restored.birthDate, '15/03/1990');
      expect(restored.coordinates, '-34.6037, -58.3816');
      expect(restored.phone, '+54 9 11 5555-1234');
      expect(restored.phoneCarrier, 'Movistar');
      expect(restored.email, 'juan@correo.com');
      expect(restored.occupation, 'Analista');
      expect(restored.photoBase64, 'aW1hZ2VuYmluYXJ5');
      expect(restored.isEmpty, isFalse);
    });

    test('usa valores por defecto ante campos ausentes', () {
      final restored = TargetProfileModel.fromJson(null);
      expect(restored.isEmpty, isTrue);
    });
  });

  group('SocialLinkModel', () {
    test('round-trip conserva los datos', () {
      const link = SocialLink(
        id: 'sl1',
        platform: SocialPlatform.linkedin,
        url: 'https://linkedin.com/in/jperez',
        username: 'jperez',
      );

      final restored =
          SocialLinkModel.fromJson(SocialLinkModel.toJson(link));

      expect(restored.id, 'sl1');
      expect(restored.platform, SocialPlatform.linkedin);
      expect(restored.url, 'https://linkedin.com/in/jperez');
      expect(restored.username, 'jperez');
    });
  });

  group('DateFormatter', () {
    test('formatea fecha y hora', () {
      expect(
        DateFormatter.dateTime(DateTime(2026, 3, 5, 7, 4)),
        '2026-03-05 07:04',
      );
      expect(DateFormatter.dateOnly(DateTime(2026, 12, 25)), '2026-12-25');
    });
  });
}
