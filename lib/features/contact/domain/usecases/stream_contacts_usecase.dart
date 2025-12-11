import 'package:fihirana/features/contact/domain/repositories/contact_repository.dart';
import 'package:fihirana/features/contact/domain/entities/contact.dart';

/// Use case for streaming contacts
class StreamContactsUseCase {
  final ContactRepository _repository;

  StreamContactsUseCase(this._repository);

  Stream<List<Contact>> execute() {
    return _repository.getContactsStream();
  }
}