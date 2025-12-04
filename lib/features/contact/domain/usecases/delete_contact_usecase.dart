import 'package:fihirana/features/contact/domain/repositories/contact_repository.dart';

/// Use case for deleting a contact
class DeleteContactUseCase {
  final ContactRepository _repository;

  DeleteContactUseCase(this._repository);

  Future<bool> execute(String contactId) async {
    return await _repository.deleteContact(contactId);
  }
}