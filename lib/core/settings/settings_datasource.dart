import '../storage/json_storage.dart';
import 'ai_provider.dart';

/// Persistencia de la configuración de la aplicación.
///
/// Las API keys de IA se guardan únicamente en el dispositivo del usuario,
/// dentro de un archivo JSON local (nunca se versionan ni se envían salvo
/// en las peticiones al proveedor de IA).
class SettingsDatasource {
  final JsonStorage _storage;

  const SettingsDatasource(this._storage);

  static const String _key = 'settings';

  static const String _providerKeyField = 'aiProvider';

  static const String _fallbackField = 'aiFallback';

  Map<String, dynamic> _asMap(Object? raw) {
    if (raw is! Map<String, dynamic>) return const {};
    return raw;
  }

  bool _isSet(Object? value) => value is String && value.isNotEmpty;

  /// Compatibilidad: clave de Google Gemini.
  Future<String?> getGeminiApiKey() => getAiApiKey(AiProvider.gemini);

  /// Compatibilidad: guarda la clave de Google Gemini.
  Future<void> setGeminiApiKey(String apiKey) =>
      setAiApiKey(AiProvider.gemini, apiKey);

  Future<String?> getAiApiKey(AiProvider provider) async {
    final raw = await _storage.read(_key);
    final value = _asMap(raw)[provider.storageKey];
    return _isSet(value) ? value as String : null;
  }

  Future<void> setAiApiKey(AiProvider provider, String apiKey) async {
    await _patch({provider.storageKey: apiKey.trim()});
  }

  Future<AiProvider> getAiProvider() async {
    final raw = await _storage.read(_key);
    final value = _asMap(raw)[_providerKeyField];
    return AiProvider.fromStorageKey(value is String ? value : null);
  }

  Future<void> setAiProvider(AiProvider provider) async {
    await _patch({_providerKeyField: provider.storageKey});
  }

  /// Indica si el análisis intentará otros proveedores cuando el
  /// proveedor principal falle.
  Future<bool> getAiFallbackEnabled() async {
    final raw = await _storage.read(_key);
    final value = _asMap(raw)[_fallbackField];
    return value is bool ? value : true;
  }

  Future<void> setAiFallbackEnabled(bool enabled) async {
    await _patch({_fallbackField: enabled});
  }

  Future<void> _patch(Map<String, dynamic> values) async {
    final raw = await _storage.read(_key);
    final data = Map<String, dynamic>.from(_asMap(raw));
    data.addAll(values);
    await _storage.write(_key, data);
  }
}