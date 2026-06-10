import 'package:fihirana/features/contact/domain/repositories/contact_repository.dart';
import 'package:fihirana/features/contact/domain/entities/contact.dart';

/// Use case for updating an existing contact
class UpdateContactUseCase {
  final ContactRepository _repository;

  UpdateContactUseCase(this._repository);

  Future<bool> execute(Contact contact) async {
    return await _repository.updateContact(contact);
  }
}
