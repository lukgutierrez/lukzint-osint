import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osint_social_analyzer/core/settings/settings_datasource.dart';
import 'package:osint_social_analyzer/core/storage/json_storage.dart';
import 'package:osint_social_analyzer/data/repositories/pdf_report_generator.dart';
import 'package:osint_social_analyzer/domain/entities/analysis_result.dart';
import 'package:osint_social_analyzer/domain/entities/investigation.dart';
import 'package:osint_social_analyzer/domain/entities/source.dart';
import 'package:osint_social_analyzer/domain/entities/target_profile.dart';
import 'package:osint_social_analyzer/domain/repositories/analysis_repository.dart';
import 'package:osint_social_analyzer/domain/repositories/investigation_repository.dart';
import 'package:osint_social_analyzer/domain/repositories/social_analysis_repository.dart';
import 'package:osint_social_analyzer/domain/usecases/analyze_social.dart';
import 'package:osint_social_analyzer/domain/usecases/analyze_url.dart';
import 'package:osint_social_analyzer/domain/usecases/create_investigation.dart';
import 'package:osint_social_analyzer/domain/usecases/generate_pdf.dart';
import 'package:osint_social_analyzer/presentation/controllers/investigation_controller.dart';
import 'package:osint_social_analyzer/presentation/screens/investigation_detail_screen.dart';

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
  final dir = Directory.systemTemp.createTempSync('lukzint_detail_');
  addTearDown(() => dir.deleteSync(recursive: true));
  return SettingsDatasource(JsonStorage(dir));
}

Future<Investigation> _sampleInvestigation() async {
  final investigation = Investigation.create(
    title: 'Análisis de ejemplo',
    objective: 'Verificar datos públicos',
  );
  return investigation.copyWith(
    targetProfile: const TargetProfile(
      fullName: 'María López',
      alias: '@mlopez',
      location: 'Buenos Aires',
    ),
  );
}

Future<InvestigationController> _buildController(
  Investigation investigation,
) async {
  final repository = _MemoryInvestigationRepository();
  await repository.save(investigation);
  return InvestigationController(
    repository,
    CreateInvestigation(repository),
    AnalyzeUrl(_NoopAnalysisRepository(), repository),
    GeneratePdf(PdfReportGenerator()),
    AnalyzeSocial(_FakeSocialAnalysisRepository()),
    _testSettings(),
  );
}

void main() {
  testWidgets('el detalle no desborda en pantalla angosta', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final investigation = await _sampleInvestigation();
    final controller = await _buildController(investigation);
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(
        home: InvestigationDetailScreen(
          controller: controller,
          investigationId: investigation.id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Perfil objetivo'), findsOneWidget);
    expect(find.text('Redes sociales'), findsOneWidget);
    expect(find.text('Análisis de ejemplo'), findsOneWidget);
  });

  testWidgets('el detalle no desborda en pantalla ancha', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final investigation = await _sampleInvestigation();
    final controller = await _buildController(investigation);
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(
        home: InvestigationDetailScreen(
          controller: controller,
          investigationId: investigation.id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Perfil objetivo'), findsOneWidget);
    expect(find.text('Redes sociales'), findsOneWidget);
    expect(find.text('Análisis de ejemplo'), findsOneWidget);
  });
}
