import 'package:fihirana/features/favorites/domain/repositories/favorites_repository.dart';

/// Use case for checking audio availability
class CheckAudioAvailabilityUseCase {
  final FavoritesRepository _repository;

  CheckAudioAvailabilityUseCase(this._repository);

  /// Execute the use case
  Future<bool> call(String hymnId) async {
    return await _repository.checkAudioAvailability(hymnId);
  }
}
