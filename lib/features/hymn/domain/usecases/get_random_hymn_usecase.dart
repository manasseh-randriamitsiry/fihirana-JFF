import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/features/hymn/domain/repositories/hymn_repository.dart';

class GetRandomHymnUseCase {
  final IHymnService _repository;

  GetRandomHymnUseCase(this._repository);

  Future<Hymn?> call() {
    return _repository.getRandomHymn();
  }
}
