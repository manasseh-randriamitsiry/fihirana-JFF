import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/features/hymn/domain/repositories/hymn_repository.dart';

class GetHymnByIdUseCase {
  final IHymnService _repository;

  GetHymnByIdUseCase(this._repository);

  Future<Hymn?> call(String id) {
    return _repository.getHymnById(id);
  }
}
