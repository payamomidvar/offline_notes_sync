import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:offline_notes_sync/data/local/app_database.dart';
import 'package:offline_notes_sync/data/local/notes_local_data_source.dart';
import 'package:offline_notes_sync/data/remote/notes_remote_data_source.dart';
import 'package:offline_notes_sync/data/repositories/notes_repository_impl.dart';
import 'package:offline_notes_sync/data/sync/sync_service.dart';
import 'package:offline_notes_sync/domain/entities/note.dart';
import 'package:offline_notes_sync/domain/usecases/add_note.dart';

class _MockRemoteDataSource extends Mock implements NotesRemoteDataSource {}

class _MockConnectivity extends Mock implements Connectivity {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(
      Note(
        id: 'fallback',
        title: '',
        body: '',
        batteryAtCreation: null,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        syncStatus: SyncStatus.pending,
      ),
    );
  });

  testWidgets(
    'adding a note offline stays pending, then becomes synced on reconnect',
    (tester) async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      final localDataSource = NotesLocalDataSource(database.notesDao);
      final remoteDataSource = _MockRemoteDataSource();
      final connectivity = _MockConnectivity();
      final connectivityController =
          StreamController<List<ConnectivityResult>>.broadcast();

      when(
        () => connectivity.onConnectivityChanged,
      ).thenAnswer((_) => connectivityController.stream);
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.none]);
      when(
        () => remoteDataSource.pushNote(any()),
      ).thenAnswer((_) async {});
      when(
        () => remoteDataSource.pullNotesUpdatedAfter(any()),
      ).thenAnswer((_) async => []);

      final syncService = SyncService(
        localDataSource: localDataSource,
        remoteDataSource: remoteDataSource,
        connectivity: connectivity,
      );
      final repository = NotesRepositoryImpl(
        localDataSource: localDataSource,
        syncService: syncService,
      );
      final addNote = AddNote(repository);

      final now = DateTime.now().toUtc();
      final note = Note(
        id: 'integration-note',
        title: 'Offline note',
        body: 'Written with no connectivity',
        batteryAtCreation: 42,
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.pending,
      );

      // Offline: adding the note must not reach the remote data source.
      await addNote(note);

      var stored = await localDataSource.getPendingNotes();
      expect(stored, hasLength(1));
      expect(stored.single.syncStatus, SyncStatus.pending);
      verifyNever(() => remoteDataSource.pushNote(any()));

      // Reconnect: SyncService's own connectivity listener should push it.
      final syncFinished = syncService.statusStream.firstWhere(
        (state) => state == SyncState.idle || state == SyncState.error,
      );
      connectivityController.add([ConnectivityResult.wifi]);
      await syncFinished;

      stored = await localDataSource.getPendingNotes();
      expect(stored, isEmpty);
      verify(() => remoteDataSource.pushNote(any())).called(1);

      await connectivityController.close();
      syncService.dispose();
      await database.close();
    },
  );
}
