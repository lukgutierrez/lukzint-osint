import '../../core/errors/analysis_exception.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/url_validator.dart';
import '../../domain/entities/analysis_result.dart';
import '../../domain/entities/finding.dart';
import '../../domain/entities/source.dart';
import '../../domain/repositories/analysis_repository.dart';
import '../datasources/github_api_datasource.dart';
import '../datasources/web_scraper_datasource.dart';

/// Implementación del análisis de fuentes públicas OSINT.
class AnalysisRepositoryImpl implements AnalysisRepository {
  final GithubApiDatasource _githubApi;
  final WebScraperDatasource _webScraper;

  AnalysisRepositoryImpl(this._githubApi, this._webScraper);

  @override
  Future<AnalysisResult> analyzeUrl(String url) async {
    final normalized = UrlValidator.normalize(url);
    final validationError = UrlValidator.validate(normalized);
    if (validationError != null) {
      throw AnalysisException(validationError);
    }

    if (UrlValidator.isGithubProfile(normalized)) {
      return _analyzeGithub(normalized);
    }

    return _analyzeWeb(normalized);
  }

  Future<AnalysisResult> _analyzeGithub(String url) async {
    final username = UrlValidator.githubUsername(url)!;
    final profile = await _githubApi.fetchProfile(username);
    final consultedAt = DateTime.now();

    final findings = <Finding>[
      _finding(
        FindingCategory.identity,
        'Usuario de GitHub',
        profile.login,
        1.0,
        'Campo "login" de la API oficial de GitHub',
        consultedAt,
      ),
      if (profile.name != null && profile.name!.isNotEmpty)
        _finding(
          FindingCategory.identity,
          'Nombre público',
          profile.name!,
          0.95,
          'Campo "name" de la API oficial de GitHub',
          consultedAt,
        ),
      if (profile.bio != null && profile.bio!.isNotEmpty)
        _finding(
          FindingCategory.identity,
          'Biografía',
          profile.bio!,
          0.9,
          'Campo "bio" de la API oficial de GitHub',
          consultedAt,
        ),
      if (profile.company != null && profile.company!.isNotEmpty)
        _finding(
          FindingCategory.organization,
          'Compañía declarada',
          profile.company!,
          0.85,
          'Campo "company" de la API oficial de GitHub',
          consultedAt,
        ),
      if (profile.location != null && profile.location!.isNotEmpty)
        _finding(
          FindingCategory.metadata,
          'Ubicación declarada',
          profile.location!,
          0.85,
          'Campo "location" de la API oficial de GitHub',
          consultedAt,
        ),
      if (profile.blog != null && profile.blog!.isNotEmpty)
        _finding(
          FindingCategory.metadata,
          'Sitio web declarado',
          profile.blog!,
          0.8,
          'Campo "blog" de la API oficial de GitHub',
          consultedAt,
        ),
      if (profile.twitterUsername != null && profile.twitterUsername!.isNotEmpty)
        _finding(
          FindingCategory.identity,
          'Usuario de Twitter/X declarado',
          profile.twitterUsername!,
          0.9,
          'Campo "twitter_username" de la API oficial de GitHub',
          consultedAt,
        ),
      _finding(
        FindingCategory.project,
        'Repositorios públicos',
        profile.publicRepos.toString(),
        1.0,
        'Campo "public_repos" de la API oficial de GitHub',
        consultedAt,
      ),
      _finding(
        FindingCategory.metadata,
        'Seguidores',
        profile.followers.toString(),
        1.0,
        'Campo "followers" de la API oficial de GitHub',
        consultedAt,
      ),
      _finding(
        FindingCategory.metadata,
        'Usuarios seguidos',
        profile.following.toString(),
        1.0,
        'Campo "following" de la API oficial de GitHub',
        consultedAt,
      ),
      if (profile.createdAt != null)
        _finding(
          FindingCategory.metadata,
          'Cuenta creada el',
          DateFormatter.dateOnly(profile.createdAt!),
          0.95,
          'Campo "created_at" de la API oficial de GitHub',
          consultedAt,
        ),
    ];

    return AnalysisResult(
      url: url,
      finalUrl: profile.htmlUrl ?? url,
      title: profile.name ?? profile.login,
      description: profile.bio ?? '',
      sourceType: SourceType.github,
      consultedAt: consultedAt,
      findings: findings,
    );
  }

  Future<AnalysisResult> _analyzeWeb(String url) async {
    final page = await _webScraper.fetch(url);
    final consultedAt = DateTime.now();

    final findings = <Finding>[
      if (page.title.isNotEmpty)
        _finding(
          FindingCategory.metadata,
          'Título de la página',
          page.title,
          0.8,
          'Etiqueta <title> / og:title',
          consultedAt,
        ),
      if (page.description.isNotEmpty)
        _finding(
          FindingCategory.metadata,
          'Descripción',
          page.description,
          0.8,
          'Meta description / og:description',
          consultedAt,
        ),
      if (page.siteName != null && page.siteName!.isNotEmpty)
        _finding(
          FindingCategory.organization,
          'Nombre del sitio',
          page.siteName!,
          0.7,
          'og:site_name',
          consultedAt,
        ),
      if (page.ogType != null && page.ogType!.isNotEmpty)
        _finding(
          FindingCategory.metadata,
          'Tipo de contenido',
          page.ogType!,
          0.7,
          'og:type',
          consultedAt,
        ),
      if (page.canonical != null && page.canonical!.isNotEmpty)
        _finding(
          FindingCategory.metadata,
          'URL canónica',
          page.canonical!,
          0.7,
          'Enlace rel="canonical"',
          consultedAt,
        ),
      for (final heading in page.headings)
        _finding(
          FindingCategory.content,
          'Encabezado principal',
          heading,
          0.6,
          'Elemento <h1>',
          consultedAt,
        ),
    ];

    return AnalysisResult(
      url: url,
      finalUrl: page.url,
      title: page.title.isEmpty ? url : page.title,
      description: page.description,
      sourceType: SourceType.web,
      consultedAt: consultedAt,
      findings: findings,
    );
  }

  Finding _finding(
    FindingCategory category,
    String description,
    String content,
    double confidence,
    String evidence,
    DateTime timestamp,
  ) {
    return Finding(
      id: _nextId(),
      sourceId: '',
      category: category,
      description: description,
      content: content,
      confidence: confidence,
      evidence: evidence,
      timestamp: timestamp,
    );
  }

  int _counter = 0;

  String _nextId() => 'f-${DateTime.now().microsecondsSinceEpoch}-${_counter++}';
}
