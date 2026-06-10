import 'package:fihirana/features/contact/domain/repositories/contact_repository.dart';
import 'package:fihirana/features/contact/domain/entities/contact.dart';

/// Use case for searching contacts
class SearchContactsUseCase {
  final ContactRepository _repository;

  SearchContactsUseCase(this._repository);

  Future<List<Contact>> execute(String query) async {
    return await _repository.searchContacts(query);
  }
}
