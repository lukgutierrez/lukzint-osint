import '../../domain/entities/investigation.dart';
import '../../domain/repositories/investigation_repository.dart';
import '../datasources/local_storage_datasource.dart';

/// Implementación del repositorio de investigaciones sobre almacenamiento local.
class InvestigationRepositoryImpl implements InvestigationRepository {
  final LocalStorageDatasource _datasource;

  const InvestigationRepositoryImpl(this._datasource);

  @override
  Future<void> delete(String id) => _datasource.delete(id);

  @override
  Future<List<Investigation>> findAll() => _datasource.findAll();

  @override
  Future<Investigation?> findById(String id) => _datasource.findById(id);

  @override
  Future<Investigation> save(Investigation investigation) async {
    await _datasource.saveInvestigation(investigation);
    return investigation;
  }
}
