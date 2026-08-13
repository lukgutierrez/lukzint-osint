/// Excepción de dominio para errores relacionados con el
/// análisis de fuentes OSINT.
class AnalysisException implements Exception {
  final String message;

  const AnalysisException(this.message);

  @override
  String toString() => message;
}
