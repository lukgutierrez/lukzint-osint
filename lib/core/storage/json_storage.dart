import 'dart:convert';
import 'dart:io';

/// Almacenamiento persistente basado en archivos JSON planos.
///
/// Cada clave se guarda como un archivo `<clave>.json` dentro del
/// directorio base proporcionado (obtenido habitualmente mediante
/// `path_provider`).
class JsonStorage {
  final Directory baseDirectory;

  JsonStorage(this.baseDirectory);

  Directory get root => baseDirectory;

  String _pathFor(String key) =>
      '${root.path}${Platform.pathSeparator}$key.json';

  Future<void> write(String key, Object value) async {
    await root.create(recursive: true);
    final file = File(_pathFor(key));
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(value),
      flush: true,
    );
  }

  Future<Object?> read(String key) async {
    final file = File(_pathFor(key));
    if (!await file.exists()) return null;
    final raw = await file.readAsString();
    return jsonDecode(raw);
  }

  Future<List<String>> listKeys() async {
    if (!await root.exists()) return const [];
    final keys = <String>[];
    await for (final entity in root.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        keys.add(entity.uri.pathSegments.last.replaceAll('.json', ''));
      }
    }
    return keys;
  }

  Future<void> delete(String key) async {
    final file = File(_pathFor(key));
    if (await file.exists()) {
      await file.delete();
    }
  }
}
