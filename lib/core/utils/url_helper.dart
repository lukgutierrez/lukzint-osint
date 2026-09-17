import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper seguro para la apertura de hipervínculos externos y correos.
class UrlHelper {
  UrlHelper._();

  /// Abre una URL en el navegador predeterminado del sistema.
  static Future<bool> openUrl(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return false;

    try {
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Error abriendo URL ($rawUrl): $e');
      return false;
    }
  }

  /// Abre el cliente de correo predeterminado con la dirección destino.
  static Future<bool> openEmail({
    required String email,
    String subject = 'Consulta sobre LUKZINT OSINT',
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: subject.isNotEmpty ? {'subject': subject} : null,
    );

    try {
      return await launchUrl(uri);
    } catch (e) {
      debugPrint('Error abriendo cliente de correo ($email): $e');
      return false;
    }
  }
}
