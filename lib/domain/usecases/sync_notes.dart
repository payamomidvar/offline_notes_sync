import '../core/result.dart';
import '../repositories/notes_repository.dart';

class SyncNotes {
  const SyncNotes(this._repository);

  final NotesRepository _repository;

  Future<Result<void>> call() {
    return _repository.syncNotes();
  }
}
