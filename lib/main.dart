import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'core/constants/branding.dart';
import 'core/network/http_native_client.dart';
import 'core/settings/ai_provider.dart';
import 'core/settings/settings_datasource.dart';
import 'core/storage/json_storage.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/ai_datasource.dart';
import 'data/datasources/failover_ai_datasource.dart';
import 'data/datasources/gemini_ai_datasource.dart';
import 'data/datasources/github_api_datasource.dart';
import 'data/datasources/local_storage_datasource.dart';
import 'data/datasources/openai_compatible_ai_datasource.dart';
import 'data/datasources/web_scraper_datasource.dart';
import 'data/repositories/analysis_repository_impl.dart';
import 'data/repositories/investigation_repository_impl.dart';
import 'data/repositories/pdf_report_generator.dart';
import 'data/repositories/social_analysis_repository_impl.dart';
import 'domain/repositories/analysis_repository.dart';
import 'domain/repositories/investigation_repository.dart';
import 'domain/repositories/social_analysis_repository.dart';
import 'domain/usecases/analyze_social.dart';
import 'domain/usecases/analyze_url.dart';
import 'domain/usecases/create_investigation.dart';
import 'domain/usecases/generate_pdf.dart';
import 'presentation/controllers/investigation_controller.dart';
import 'presentation/screens/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final documentsDir = await getApplicationDocumentsDirectory();
  final storageDir = Directory(
    '${documentsDir.path}${Platform.pathSeparator}osint_social_analyzer',
  );
  final controller = buildController(storageDir);
  await controller.loadSettings();
  runApp(OsintApp(controller: controller));
}

/// Ensambla todas las dependencias de la aplicación mediante
/// inyección manual (sin frameworks externos).
InvestigationController buildController(Directory storageDir) {
  final storage = JsonStorage(storageDir);
  final settingsDatasource = SettingsDatasource(storage);
  final localStorageDatasource = LocalStorageDatasource(storage);
  final investigationRepository =
      InvestigationRepositoryImpl(localStorageDatasource)
          as InvestigationRepository;

  final httpClient = HttpNativeClient();
  final analysisRepository = AnalysisRepositoryImpl(
    GithubApiDatasource(httpClient),
    WebScraperDatasource(httpClient),
  ) as AnalysisRepository;

  final socialRepository = SocialAnalysisRepositoryImpl(
    _buildAiDatasource(settingsDatasource),
  ) as SocialAnalysisRepository;

  return InvestigationController(
    investigationRepository,
    CreateInvestigation(investigationRepository),
    AnalyzeUrl(analysisRepository, investigationRepository),
    GeneratePdf(PdfReportGenerator()),
    AnalyzeSocial(socialRepository),
    settingsDatasource,
  );
}

/// Ensambla los proveedores de IA y los envuelve en un enrutador con
/// fallback automático: primero el proveedor elegido y luego el resto
/// de los configurados si falla.
AiDatasource _buildAiDatasource(SettingsDatasource settingsDatasource) {
  final datasources = <AiProvider, AiDatasource>{
    AiProvider.gemini: GeminiAiDatasource(settings: settingsDatasource),
    AiProvider.openrouter: OpenAiCompatibleAiDatasource(
      settings: settingsDatasource,
      provider: AiProvider.openrouter,
      baseUrl: 'https://openrouter.ai/api/v1',
      model: 'openrouter/free',
    ),
    AiProvider.groq: OpenAiCompatibleAiDatasource(
      settings: settingsDatasource,
      provider: AiProvider.groq,
      baseUrl: 'https://api.groq.com/openai/v1',
      model: 'llama-3.3-70b-versatile',
    ),
    AiProvider.mistral: OpenAiCompatibleAiDatasource(
      settings: settingsDatasource,
      provider: AiProvider.mistral,
      baseUrl: 'https://api.mistral.ai/v1',
      model: 'mistral-small-latest',
    ),
  };

  return FailoverAiDatasource(
    settings: settingsDatasource,
    datasources: datasources,
  );
}

/// Widget raíz de la aplicación.
class OsintApp extends StatelessWidget {
  final InvestigationController controller;

  const OsintApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppBranding.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: DashboardScreen(controller: controller),
    );
  }
}
