import '../core/result.dart';
import '../repositories/notes_repository.dart';

class DeleteNote {
  const DeleteNote(this._repository);

  final NotesRepository _repository;

  Future<Result<void>> call(String id) {
    return _repository.deleteNote(id);
  }
}
