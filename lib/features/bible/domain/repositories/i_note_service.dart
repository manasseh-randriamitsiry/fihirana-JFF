import 'package:fihirana/features/bible/domain/entities/note.dart';

abstract class INoteService {
  Future<Note?> getNote(String hymnId);
  Stream<List<Note>> getPublicNotesStream(String hymnId);
  Future<bool> saveNote(String hymnId, String content);
  Future<bool> canEditNote(Note note);
  Future<bool> deleteNote(String noteId);
}