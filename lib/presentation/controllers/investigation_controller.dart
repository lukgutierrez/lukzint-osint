import 'package:flutter/foundation.dart';

import '../../core/settings/ai_provider.dart';
import '../../core/settings/settings_datasource.dart';
import '../../domain/entities/analysis_result.dart';
import '../../domain/entities/investigation.dart';
import '../../domain/repositories/investigation_repository.dart';
import '../../domain/usecases/analyze_social.dart';
import '../../domain/usecases/analyze_url.dart';
import '../../domain/usecases/create_investigation.dart';
import '../../domain/usecases/generate_pdf.dart';

/// Controlador de estado para las investigaciones OSINT.
class InvestigationController extends ChangeNotifier {
  final InvestigationRepository _repository;
  final CreateInvestigation _createInvestigation;
  final AnalyzeUrl _analyzeUrl;
  final GeneratePdf _generatePdf;
  final AnalyzeSocial _analyzeSocial;
  final SettingsDatasource _settings;

  InvestigationController(
    this._repository,
    this._createInvestigation,
    this._analyzeUrl,
    this._generatePdf,
    this._analyzeSocial,
    this._settings,
  );

  List<Investigation> _investigations = const [];
  bool _loading = false;
  bool _busy = false;
  String? _error;
  final Map<AiProvider, String?> _aiKeys = {};
  AiProvider _aiProvider = AiProvider.gemini;
  bool _aiFallbackEnabled = true;

  List<Investigation> get investigations => List.unmodifiable(_investigations);

  bool get loading => _loading;

  bool get busy => _busy;

  String? get error => _error;

  /// Compatibilidad: clave de Google Gemini.
  String? get geminiApiKey => _aiKeys[AiProvider.gemini];

  /// Proveedor de IA seleccionado como principal.
  AiProvider get aiProvider => _aiProvider;

  String get aiProviderLabel => _aiProvider.label;

  /// Indica si el análisis intentará otros proveedores cuando falle el principal.
  bool get aiFallbackEnabled => _aiFallbackEnabled;

  /// Verdadero si hay al menos una API key configurada para algún proveedor.
  bool get hasAiKey => AiProvider.values.any(hasApiKey);

  bool hasApiKey(AiProvider provider) {
    final value = _aiKeys[provider];
    return value != null && value.isNotEmpty;
  }

  String? apiKeyFor(AiProvider provider) => _aiKeys[provider];

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _investigations = await _repository.findAll();
    } catch (e) {
      _error = 'No se pudieron cargar las investigaciones: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadSettings() async {
    await Future.wait([
      for (final provider in AiProvider.values) _loadAiKey(provider),
    ]);
    _aiProvider = await _settings.getAiProvider();
    _aiFallbackEnabled = await _settings.getAiFallbackEnabled();
    notifyListeners();
  }

  Future<void> _loadAiKey(AiProvider provider) async {
    _aiKeys[provider] = await _settings.getAiApiKey(provider);
  }

  Future<bool> saveApiKey(AiProvider provider, String apiKey) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _settings.setAiApiKey(provider, apiKey);
      _aiKeys[provider] = apiKey.trim();
      return true;
    } catch (e) {
      _error = 'No se pudo guardar la configuración: $e';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Compatibilidad: guarda la clave de Google Gemini.
  Future<bool> saveGeminiApiKey(String apiKey) =>
      saveApiKey(AiProvider.gemini, apiKey);

  Future<bool> selectAiProvider(AiProvider provider) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _settings.setAiProvider(provider);
      _aiProvider = provider;
      return true;
    } catch (e) {
      _error = 'No se pudo guardar la configuración: $e';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> setAiFallbackEnabled(bool enabled) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _settings.setAiFallbackEnabled(enabled);
      _aiFallbackEnabled = enabled;
      return true;
    } catch (e) {
      _error = 'No se pudo guardar la configuración: $e';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<AnalysisResult?> analyzeSocial({
    required String platform,
    required String content,
    String? url,
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      return await _analyzeSocial.call(
        platform: platform,
        content: content,
        url: url,
      );
    } catch (e) {
      _error = '$e';
      return null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<Investigation?> create({
    required String title,
    required String objective,
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final investigation =
          await _createInvestigation.call(title: title, objective: objective);
      await load();
      return investigation;
    } catch (e) {
      _error = 'No se pudo crear la investigación: $e';
      return null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> updateInvestigation(Investigation investigation) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.save(investigation);
      await load();
      return true;
    } catch (e) {
      _error = 'No se pudo guardar los cambios: $e';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<AnalysisResult?> preview(String url) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      return await _analyzeUrl.preview(url);
    } catch (e) {
      _error = '$e';
      return null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<Investigation?> attach(
    Investigation investigation,
    AnalysisResult result,
  ) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _analyzeUrl.attach(investigation, result);
      await load();
      return updated;
    } catch (e) {
      _error = '$e';
      return null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<ReportDocument?> generatePdfReport(Investigation investigation) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      return await _generatePdf.call(investigation);
    } catch (e) {
      _error = 'No se pudo generar el informe: $e';
      return null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> delete(String id) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.delete(id);
      await load();
      return true;
    } catch (e) {
      _error = 'No se pudo eliminar la investigación: $e';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
