import 'package:fihirana/features/contact/domain/repositories/contact_repository.dart';
import 'package:fihirana/features/contact/domain/entities/contact.dart';

/// Use case for checking if user can edit contact
class CanEditContactUseCase {
  final ContactRepository _repository;

  CanEditContactUseCase(this._repository);

  Future<bool> execute(Contact contact) async {
    return await _repository.canEditContact(contact);
  }
}
