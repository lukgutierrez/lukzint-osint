import '../entities/investigation.dart';

/// Contrato de persistencia de investigaciones.
abstract class InvestigationRepository {
  Future<Investigation> save(Investigation investigation);

  Future<Investigation?> findById(String id);

  Future<List<Investigation>> findAll();

  Future<void> delete(String id);
}
