import '../core/result.dart';
import '../entities/note.dart';

abstract class NotesRepository {
  Stream<List<Note>> watchNotes();

  Future<Result<void>> addNote(Note note);

  Future<Result<void>> updateNote(Note note);

  Future<Result<void>> deleteNote(String id);

  Future<Result<void>> syncNotes();
}
