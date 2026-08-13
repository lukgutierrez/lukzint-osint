import '../../core/storage/json_storage.dart';
import '../../domain/entities/investigation.dart';
import '../models/investigation_model.dart';

/// Datasource de persistencia local basado en archivos JSON planos.
class LocalStorageDatasource {
  final JsonStorage _storage;

  const LocalStorageDatasource(this._storage);

  static const String _prefix = 'investigation';

  String _key(String id) => '${_prefix}_$id';

  Future<void> saveInvestigation(Investigation investigation) async {
    await _storage.write(
      _key(investigation.id),
      InvestigationModel.toJson(investigation),
    );
  }

  Future<Investigation?> findById(String id) async {
    final raw = await _storage.read(_key(id));
    if (raw is! Map<String, dynamic>) return null;
    return InvestigationModel.fromJson(raw);
  }

  Future<List<Investigation>> findAll() async {
    final keys = await _storage.listKeys();
    final investigations = <Investigation>[];
    for (final key in keys) {
      if (!key.startsWith('${_prefix}_')) continue;
      final raw = await _storage.read(key);
      if (raw is Map<String, dynamic>) {
        investigations.add(InvestigationModel.fromJson(raw));
      }
    }
    investigations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return investigations;
  }

  Future<void> delete(String id) => _storage.delete(_key(id));
}
