import '../core/result.dart';
import '../entities/note.dart';
import '../repositories/notes_repository.dart';

class DeleteNote {
  const DeleteNote(this._repository);

  final NotesRepository _repository;

  Future<Result<void>> call(Note note) {
    return _repository.deleteNote(note);
  }
}
