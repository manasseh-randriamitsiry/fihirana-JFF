import 'package:fihirana/features/contact/domain/repositories/contact_repository.dart';

/// Use case for adding a new contact
class AddContactUseCase {
  final ContactRepository _repository;

  AddContactUseCase(this._repository);

  Future<bool> execute({
    required String name,
    required String phoneNumber,
    String? location,
    double? latitude,
    double? longitude,
  }) async {
    return await _repository.addContact(
      name: name,
      phoneNumber: phoneNumber,
      location: location,
      latitude: latitude,
      longitude: longitude,
    );
  }
}