/// Etiqueta textual para un nivel de confianza de 0.0 a 1.0.
String confidenceLabel(double confidence) {
  if (confidence >= 0.9) return 'Alta';
  if (confidence >= 0.6) return 'Media';
  return 'Baja';
}
