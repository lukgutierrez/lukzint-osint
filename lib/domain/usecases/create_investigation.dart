import '../entities/investigation.dart';
import '../repositories/investigation_repository.dart';

/// Caso de uso: crear una nueva investigación.
class CreateInvestigation {
  final InvestigationRepository _repository;

  const CreateInvestigation(this._repository);

  Future<Investigation> call({
    required String title,
    required String objective,
  }) async {
    final investigation =
        Investigation.create(title: title, objective: objective);
    return _repository.save(investigation);
  }
}
