import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osint_social_analyzer/core/settings/settings_datasource.dart';
import 'package:osint_social_analyzer/core/storage/json_storage.dart';
import 'package:osint_social_analyzer/data/repositories/pdf_report_generator.dart';
import 'package:osint_social_analyzer/domain/entities/analysis_result.dart';
import 'package:osint_social_analyzer/domain/entities/finding.dart';
import 'package:osint_social_analyzer/domain/entities/investigation.dart';
import 'package:osint_social_analyzer/domain/entities/source.dart';
import 'package:osint_social_analyzer/domain/repositories/analysis_repository.dart';
import 'package:osint_social_analyzer/domain/repositories/investigation_repository.dart';
import 'package:osint_social_analyzer/domain/repositories/social_analysis_repository.dart';
import 'package:osint_social_analyzer/domain/usecases/analyze_social.dart';
import 'package:osint_social_analyzer/domain/usecases/analyze_url.dart';
import 'package:osint_social_analyzer/domain/usecases/create_investigation.dart';
import 'package:osint_social_analyzer/domain/usecases/generate_pdf.dart';
import 'package:osint_social_analyzer/main.dart';
import 'package:osint_social_analyzer/presentation/controllers/investigation_controller.dart';

class _MemoryInvestigationRepository implements InvestigationRepository {
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

class _NoopAnalysisRepository implements AnalysisRepository {
  @override
  Future<AnalysisResult> analyzeUrl(String url) async {
    return AnalysisResult(
      url: url,
      finalUrl: url,
      title: url,
      description: '',
      sourceType: SourceType.web,
      consultedAt: DateTime(2026, 1, 1),
      findings: const [],
    );
  }
}

class _FakeSocialAnalysisRepository implements SocialAnalysisRepository {
  @override
  Future<AnalysisResult> analyzeSocial({
    required String platform,
    required String content,
    String? url,
  }) async {
    return AnalysisResult(
      url: url ?? '',
      finalUrl: url ?? '',
      title: 'Perfil de $platform',
      description: '',
      sourceType: SourceType.social,
      consultedAt: DateTime(2026, 1, 1),
      findings: const [],
    );
  }
}

SettingsDatasource _testSettings() {
  final dir = Directory.systemTemp.createTempSync('lukzint_test_');
  addTearDown(() => dir.deleteSync(recursive: true));
  return SettingsDatasource(JsonStorage(dir));
}

Future<InvestigationController> _buildController(
  List<Investigation> seed,
) async {
  final repository = _MemoryInvestigationRepository();
  for (final investigation in seed) {
    await repository.save(investigation);
  }
  return InvestigationController(
    repository,
    CreateInvestigation(repository),
    AnalyzeUrl(_NoopAnalysisRepository(), repository),
    GeneratePdf(PdfReportGenerator()),
    AnalyzeSocial(_FakeSocialAnalysisRepository()),
    _testSettings(),
  );
}

Investigation _sampleInvestigation() {
  final investigation = Investigation.create(
    title: 'Análisis de ejemplo',
    objective: 'Verificar datos públicos',
  );
  return investigation.copyWith(
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
        timestamp: DateTime(2026, 1, 10),
      ),
    ],
  );
}

void main() {
  testWidgets('el dashboard se renderiza correctamente', (tester) async {
    final controller = await _buildController([]);

    await tester.pumpWidget(OsintApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('LUKZINT'), findsOneWidget);
    expect(find.text('Nueva investigación'), findsOneWidget);
    expect(find.text('Analizador'), findsOneWidget);
  });

  testWidgets('el dashboard muestra el estado vacío sin investigaciones',
      (tester) async {
    final controller = await _buildController([]);

    await tester.pumpWidget(OsintApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Aún no hay investigaciones'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('el dashboard lista las investigaciones existentes',
      (tester) async {
    final controller = await _buildController([_sampleInvestigation()]);

    await tester.pumpWidget(OsintApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Análisis de ejemplo'), findsOneWidget);
    expect(find.textContaining('1 fuentes'), findsOneWidget);
    expect(find.textContaining('1 hallazgos'), findsOneWidget);
  });
}
