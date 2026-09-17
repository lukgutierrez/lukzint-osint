import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osint_social_analyzer/core/constants/branding.dart';
import 'package:osint_social_analyzer/core/settings/ai_provider.dart';
import 'package:osint_social_analyzer/core/settings/settings_datasource.dart';
import 'package:osint_social_analyzer/data/repositories/pdf_report_generator.dart';
import 'package:osint_social_analyzer/domain/entities/analysis_result.dart';
import 'package:osint_social_analyzer/domain/entities/investigation.dart';
import 'package:osint_social_analyzer/domain/entities/source.dart';
import 'package:osint_social_analyzer/domain/repositories/analysis_repository.dart';
import 'package:osint_social_analyzer/domain/repositories/investigation_repository.dart';
import 'package:osint_social_analyzer/domain/repositories/social_analysis_repository.dart';
import 'package:osint_social_analyzer/domain/usecases/analyze_social.dart';
import 'package:osint_social_analyzer/domain/usecases/analyze_url.dart';
import 'package:osint_social_analyzer/domain/usecases/create_investigation.dart';
import 'package:osint_social_analyzer/domain/usecases/generate_pdf.dart';
import 'package:osint_social_analyzer/presentation/controllers/investigation_controller.dart';
import 'package:osint_social_analyzer/presentation/screens/splash_screen.dart';
import 'package:osint_social_analyzer/presentation/widgets/about_developer_dialog.dart';

class _MemoryInvestigationRepo implements InvestigationRepository {
  @override
  Future<void> delete(String id) async {}

  @override
  Future<List<Investigation>> findAll() async => [];

  @override
  Future<Investigation?> findById(String id) async => null;

  @override
  Future<Investigation> save(Investigation investigation) async =>
      investigation;
}

class _NoopAnalysisRepo implements AnalysisRepository {
  @override
  Future<AnalysisResult> analyzeUrl(String url) async => AnalysisResult(
        url: url,
        finalUrl: url,
        title: url,
        description: '',
        sourceType: SourceType.web,
        consultedAt: DateTime(2026, 1, 1),
        findings: const [],
      );
}

class _NoopSocialRepo implements SocialAnalysisRepository {
  @override
  Future<AnalysisResult> analyzeSocial({
    required String platform,
    required String content,
    String? url,
  }) async =>
      AnalysisResult(
        url: url ?? '',
        finalUrl: url ?? '',
        title: 'Perfil',
        description: '',
        sourceType: SourceType.social,
        consultedAt: DateTime(2026, 1, 1),
        findings: const [],
      );
}

class _FakeSettingsDatasource implements SettingsDatasource {
  @override
  Future<String?> getAiApiKey(AiProvider provider) async => null;

  @override
  Future<void> setAiApiKey(AiProvider provider, String apiKey) async {}

  @override
  Future<AiProvider> getAiProvider() async => AiProvider.gemini;

  @override
  Future<void> setAiProvider(AiProvider provider) async {}

  @override
  Future<bool> getAiFallbackEnabled() async => true;

  @override
  Future<void> setAiFallbackEnabled(bool enabled) async {}

  @override
  Future<String?> getGeminiApiKey() async => null;

  @override
  Future<void> setGeminiApiKey(String apiKey) async {}
}

InvestigationController _createTestController() {
  final repo = _MemoryInvestigationRepo();
  return InvestigationController(
    repo,
    CreateInvestigation(repo),
    AnalyzeUrl(_NoopAnalysisRepo(), repo),
    GeneratePdf(PdfReportGenerator()),
    AnalyzeSocial(_NoopSocialRepo()),
    _FakeSettingsDatasource(),
  );
}

void main() {
  group('AppBranding v1.0', () {
    test('contiene los datos oficiales de Luciano Gutierrez (@lukgtz)', () {
      expect(AppBranding.appName, 'LUKZINT');
      expect(AppBranding.appVersion, '1.0.0');
      expect(AppBranding.developerName, 'Luciano Gutierrez');
      expect(AppBranding.developerProfile, '@lukgtz');
      expect(AppBranding.developerRole, 'Software Engineer & OSINT Researcher');
      expect(AppBranding.githubUrl,
          'https://github.com/lukgutierrez/lukzint-osint');
      expect(AppBranding.linkedinUrl,
          'https://www.linkedin.com/in/lucianogutierrezlgtz/');
      expect(AppBranding.email, 'lucianogutierrezlgtz@gmail.com');
      expect(AppBranding.watermark, contains('Luciano Gutierrez'));
      expect(AppBranding.watermark, contains('@lukgtz'));
    });
  });

  group('AboutDeveloperDialog', () {
    testWidgets('renderiza la información y los 3 botones de contacto',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AboutDeveloperDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LUKZINT'), findsOneWidget);
      expect(find.text('v1.0.0'), findsOneWidget);
      expect(find.text('Luciano Gutierrez'), findsOneWidget);
      expect(find.text('(@lukgtz)'), findsOneWidget);
      expect(find.text('Software Engineer & OSINT Researcher'), findsOneWidget);

      // Los 3 canales oficiales de contacto
      expect(find.text('Perfil en LinkedIn'), findsOneWidget);
      expect(find.text('Repositorio en GitHub'), findsOneWidget);
      expect(find.text('Correo Electrónico (Gmail)'), findsOneWidget);
      expect(find.text('lucianogutierrezlgtz@gmail.com'), findsOneWidget);
      expect(find.text('Cerrar'), findsOneWidget);
    });
  });

  group('SplashScreen', () {
    testWidgets('muestra el logo, el branding y el indicador de progreso',
        (tester) async {
      final controller = _createTestController();

      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            controller: controller,
            minDuration: Duration.zero,
            onTransition: () {},
          ),
        ),
      );

      expect(find.text('LUKZINT'), findsOneWidget);
      expect(find.text('v1.0.0'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text(AppBranding.watermark), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('ejecuta la inicialización y el callback de transición',
        (tester) async {
      final controller = _createTestController();
      var transitioned = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            controller: controller,
            minDuration: Duration.zero,
            onTransition: () => transitioned = true,
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(transitioned, isTrue);
    });
  });
}
