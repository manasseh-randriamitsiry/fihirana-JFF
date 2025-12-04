import 'package:fihirana/features/contact/domain/repositories/contact_repository.dart';
import 'package:fihirana/features/contact/domain/entities/contact.dart';

/// Use case for getting all contacts
class GetAllContactsUseCase {
  final ContactRepository _repository;

  GetAllContactsUseCase(this._repository);

  Future<List<Contact>> execute() async {
    return await _repository.getAllContacts();
  }
}