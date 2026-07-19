import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/notes_repository.dart';
import '../local/notes_local_data_source.dart';
import '../sync/sync_service.dart';

class NotesRepositoryImpl implements NotesRepository {
  NotesRepositoryImpl({
    required NotesLocalDataSource localDataSource,
    required SyncService syncService,
  }) : _localDataSource = localDataSource,// ignore: prefer_initializing_formals
       _syncService = syncService // ignore: prefer_initializing_formals
       {
    _syncService.start();
  }

  final NotesLocalDataSource _localDataSource;
  final SyncService _syncService;

  @override
  Stream<List<Note>> watchNotes() => _localDataSource.watchNotes();

  @override
  Future<Result<void>> addNote(Note note) => _writeLocally(note);

  @override
  Future<Result<void>> updateNote(Note note) => _writeLocally(note);

  @override
  Future<Result<void>> deleteNote(String id) async {
    try {
      await _localDataSource.deleteNote(id);
      return const Success(null);
    } catch (_) {
      return const Error(CacheFailure('Failed to delete note.'));
    }
  }

  @override
  Future<Result<void>> syncNotes() => _syncService.syncOnce();

  Future<Result<void>> _writeLocally(Note note) async {
    try {
      await _localDataSource.upsertNote(
        note.copyWith(syncStatus: SyncStatus.pending),
      );
      return const Success(null);
    } catch (_) {
      return const Error(CacheFailure('Failed to save note.'));
    }
  }
}
