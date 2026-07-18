import '../entities/note.dart';
import '../repositories/notes_repository.dart';

class WatchNotes {
  const WatchNotes(this._repository);

  final NotesRepository _repository;

  Stream<List<Note>> call() {
    return _repository.watchNotes();
  }
}
