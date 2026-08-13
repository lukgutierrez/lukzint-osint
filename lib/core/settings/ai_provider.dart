/// Proveedores de IA soportados para el análisis de contenido público.
///
/// Todos ofrecen un nivel gratuito razonable para uso personal sin
/// requerir tarjeta de crédito. El proveedor elegido es el que se intenta
/// primero; si falla y el fallback está habilitado, se prueban el resto.
enum AiProvider {
  gemini(
    storageKey: 'geminiApiKey',
    label: 'Google Gemini',
    description: 'Modelos Gemini Flash con contexto largo. Gratis.',
  ),
  openrouter(
    storageKey: 'openrouterApiKey',
    label: 'OpenRouter',
    description: 'Un solo acceso a muchos modelos gratuitos (:free).',
  ),
  groq(
    storageKey: 'groqApiKey',
    label: 'Groq',
    description: 'Inferencia muy rápida de modelos abiertos. Gratis.',
  ),
  mistral(
    storageKey: 'mistralApiKey',
    label: 'Mistral AI',
    description: 'Modelos europeos con modo gratuito sin tarjeta.',
  );

  const AiProvider({
    required this.storageKey,
    required this.label,
    required this.description,
  });

  /// Clave bajo la cual se guarda la API key en la configuración local.
  final String storageKey;

  /// Nombre comercial del proveedor.
  final String label;

  /// Descripción breve para mostrar en la interfaz.
  final String description;

  static AiProvider fromStorageKey(String? key) {
    return AiProvider.values.firstWhere(
      (provider) => provider.storageKey == key,
      orElse: () => AiProvider.gemini,
    );
  }
}