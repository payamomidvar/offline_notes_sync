import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../data/local/notes_local_data_source.dart';
import '../../data/remote/notes_remote_data_source.dart';
import '../../data/repositories/notes_repository_impl.dart';
import '../../data/sync/sync_service.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/notes_repository.dart';
import '../../domain/usecases/watch_notes.dart';
import '../../domain/usecases/add_note.dart';
import '../../domain/usecases/update_note.dart';
import '../../domain/usecases/delete_note.dart';


final appDatabaseProvider = Provider<AppDatabase>((ref) {
  ref.keepAlive();
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final notesLocalDataSourceProvider = Provider<NotesLocalDataSource>((ref) {
  ref.keepAlive();
  final database = ref.watch(appDatabaseProvider);
  return NotesLocalDataSource(database.notesDao);
});

final notesRemoteDataSourceProvider = Provider<NotesRemoteDataSource>((ref) {
  ref.keepAlive();
  return NotesRemoteDataSource(FirebaseFirestore.instance);
});

final syncServiceProvider = Provider<SyncService>((ref) {
  ref.keepAlive();
  final service = SyncService(
    localDataSource: ref.watch(notesLocalDataSourceProvider),
    remoteDataSource: ref.watch(notesRemoteDataSourceProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  ref.keepAlive();
  return NotesRepositoryImpl(
    localDataSource: ref.watch(notesLocalDataSourceProvider),
    syncService: ref.watch(syncServiceProvider),
  );
});

final watchNotesProvider = Provider<WatchNotes>((ref) {
  ref.keepAlive();
  return WatchNotes(ref.watch(notesRepositoryProvider));
});

final addNoteProvider = Provider<AddNote>((ref) {
  ref.keepAlive();
  return AddNote(ref.watch(notesRepositoryProvider));
});

final updateNoteProvider = Provider<UpdateNote>((ref) {
  ref.keepAlive();
  return UpdateNote(ref.watch(notesRepositoryProvider));
});

final deleteNoteProvider = Provider<DeleteNote>((ref) {
  ref.keepAlive();
  return DeleteNote(ref.watch(notesRepositoryProvider));
});


class NotesNotifier extends StreamNotifier<List<Note>> {
  @override
  Stream<List<Note>> build() {
    final watchNotes = ref.watch(watchNotesProvider);
    return watchNotes();
  }
}

final notesNotifierProvider =
    StreamNotifierProvider<NotesNotifier, List<Note>>(NotesNotifier.new);
