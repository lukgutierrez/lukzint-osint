import 'package:flutter_test/flutter_test.dart';
import 'package:osint_social_analyzer/domain/entities/analysis_result.dart';
import 'package:osint_social_analyzer/domain/entities/finding.dart';
import 'package:osint_social_analyzer/domain/entities/investigation.dart';
import 'package:osint_social_analyzer/domain/entities/source.dart';
import 'package:osint_social_analyzer/domain/repositories/analysis_repository.dart';
import 'package:osint_social_analyzer/domain/repositories/investigation_repository.dart';
import 'package:osint_social_analyzer/domain/usecases/analyze_url.dart';

class _FakeAnalysisRepository implements AnalysisRepository {
  @override
  Future<AnalysisResult> analyzeUrl(String url) async {
    return AnalysisResult(
      url: url,
      finalUrl: url,
      title: 'Título de prueba',
      description: 'Descripción de prueba',
      sourceType: SourceType.web,
      consultedAt: DateTime(2026, 1, 1),
      findings: [
        Finding(
          id: 'raw-1',
          sourceId: '',
          category: FindingCategory.metadata,
          description: 'Título',
          content: 'Título de prueba',
          confidence: 0.8,
          evidence: 'og:title',
          timestamp: DateTime(2026, 1, 1),
        ),
      ],
    );
  }
}

class _InMemoryInvestigationRepository implements InvestigationRepository {
  final Map<String, Investigation> store = {};

  @override
  Future<void> delete(String id) async => store.remove(id);

  @override
  Future<List<Investigation>> findAll() async => store.values.toList();

  @override
  Future<Investigation?> findById(String id) async => store[id];

  @override
  Future<Investigation> save(Investigation investigation) async {
    store[investigation.id] = investigation;
    return investigation;
  }
}

void main() {
  group('AnalyzeUrl', () {
    test('preview devuelve el resultado del análisis', () async {
      final useCase = AnalyzeUrl(
        _FakeAnalysisRepository(),
        _InMemoryInvestigationRepository(),
      );

      final result = await useCase.preview('https://example.com');

      expect(result.title, 'Título de prueba');
      expect(result.sourceType, SourceType.web);
    });

    test('attach guarda la fuente y asigna sourceId a los hallazgos', () async {
      final repo = _InMemoryInvestigationRepository();
      final useCase = AnalyzeUrl(_FakeAnalysisRepository(), repo);
      final investigation = Investigation.create(
        title: 'Análisis de ejemplo',
        objective: 'Verificar datos públicos',
      );

      final result = await useCase.preview('https://example.com');
      final updated = await useCase.attach(investigation, result);

      expect(updated.sources, hasLength(1));
      expect(updated.findings, hasLength(1));
      expect(updated.findings.first.sourceId, updated.sources.first.id);
      expect(repo.findById(updated.id), isNotNull);
    });

    test('attach evita fuentes duplicadas', () async {
      final repo = _InMemoryInvestigationRepository();
      final useCase = AnalyzeUrl(_FakeAnalysisRepository(), repo);
      final investigation = Investigation.create(
        title: 'Análisis de ejemplo',
        objective: '',
      );

      final result = await useCase.preview('https://example.com');
      await useCase.attach(investigation, result);
      final doubled = await useCase.attach(investigation, result);

      expect(doubled.sources, hasLength(1));
      expect(doubled.findings, hasLength(1));
    });
  });
}
