import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:osint_social_analyzer/data/repositories/pdf_report_generator.dart';
import 'package:osint_social_analyzer/domain/entities/finding.dart';
import 'package:osint_social_analyzer/domain/entities/investigation.dart';
import 'package:osint_social_analyzer/domain/entities/relationship.dart';
import 'package:osint_social_analyzer/domain/entities/source.dart';

void main() {
  group('PdfReportGenerator', () {
    test('genera un documento PDF válido', () async {
      final investigation = Investigation(
        id: 'inv-1',
        title: 'Informe de prueba',
        objective: 'Verificar datos públicos de ejemplo.',
        status: InvestigationStatus.inProgress,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 10),
        sources: [
          Source(
            id: 's1',
            url: 'https://example.com',
            finalUrl: 'https://example.com',
            title: 'Ejemplo',
            description: 'Sitio de ejemplo',
            type: SourceType.web,
            status: SourceStatus.analyzed,
            consultedAt: DateTime(2026, 1, 10),
          ),
        ],
        findings: [
          Finding(
            id: 'f1',
            sourceId: 's1',
            category: FindingCategory.metadata,
            description: 'Título de la página',
            content: 'Ejemplo',
            confidence: 0.8,
            evidence: 'og:title',
            timestamp: DateTime(2026, 1, 10),
          ),
        ],
      );

      final report = await PdfReportGenerator().generate(investigation);

      expect(report.bytes, isNotEmpty);
      expect(report.fileName, contains('.pdf'));
      final header = utf8.decode(report.bytes.take(5).toList(), allowMalformed: true);
      expect(header, '%PDF-');
    });

    test('genera un documento PDF aunque la investigación esté vacía', () async {
      final investigation = Investigation.create(
        title: 'Informe vacío',
        objective: '',
      );

      final report = await PdfReportGenerator().generate(investigation);

      expect(report.bytes, isNotEmpty);
    });

    test('incluye la red de relaciones con foto base64', () async {
      const pngPixel =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
      final investigation = Investigation.create(
        title: 'Informe con familia',
        objective: '',
      ).copyWith(
        relationships: [
          Relationship(
            id: 'r1',
            name: 'Ana López',
            type: RelationshipType.mother,
            notes: 'Vive en Buenos Aires',
            photoBase64: pngPixel,
          ),
        ],
        sources: [
          Source(
            id: 's2',
            url: 'https://instagram.com/mlopez',
            finalUrl: 'https://instagram.com/mlopez',
            title: 'mlopez',
            description: 'Perfil público',
            type: SourceType.social,
            status: SourceStatus.analyzed,
            consultedAt: DateTime(2026, 1, 10),
          ),
        ],
      );

      final report = await PdfReportGenerator().generate(investigation);

      expect(report.bytes, isNotEmpty);
      expect(report.fileName, contains('.pdf'));
    });
  });
}
