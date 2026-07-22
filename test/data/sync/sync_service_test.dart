import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:offline_notes_sync/data/local/notes_local_data_source.dart';
import 'package:offline_notes_sync/data/remote/notes_remote_data_source.dart';
import 'package:offline_notes_sync/data/sync/sync_service.dart';
import 'package:offline_notes_sync/domain/core/result.dart';
import 'package:offline_notes_sync/domain/entities/note.dart';

import '../../helpers/note_factory.dart';

class MockNotesLocalDataSource extends Mock implements NotesLocalDataSource {}

class MockNotesRemoteDataSource extends Mock
    implements NotesRemoteDataSource {}

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  setUpAll(() {
    registerFallbackValue(buildNote());
  });

  late MockNotesLocalDataSource localDataSource;
  late MockNotesRemoteDataSource remoteDataSource;
  late MockConnectivity connectivity;
  late StreamController<List<ConnectivityResult>> connectivityController;
  late SyncService syncService;

  setUp(() {
    localDataSource = MockNotesLocalDataSource();
    remoteDataSource = MockNotesRemoteDataSource();
    connectivity = MockConnectivity();
    connectivityController =
        StreamController<List<ConnectivityResult>>.broadcast();

    when(
      () => connectivity.onConnectivityChanged,
    ).thenAnswer((_) => connectivityController.stream);
    when(() => localDataSource.upsertNote(any())).thenAnswer((_) async {});
    when(() => remoteDataSource.pushNote(any())).thenAnswer((_) async {});

    syncService = SyncService(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
      connectivity: connectivity,
    );
  });

  tearDown(() {
    connectivityController.close();
  });

  group('syncOnce', () {
    test('pushes every pending note and marks it synced locally', () async {
      final pending = buildNote(id: 'a', syncStatus: SyncStatus.pending);
      when(
        () => localDataSource.getPendingNotes(),
      ).thenAnswer((_) async => [pending]);
      when(
        () => remoteDataSource.pullNotesUpdatedAfter(any()),
      ).thenAnswer((_) async => []);

      final result = await syncService.syncOnce();

      expect(result, isA<Success<void>>());
      verify(() => remoteDataSource.pushNote(pending)).called(1);

      final captured = verify(
        () => localDataSource.upsertNote(captureAny()),
      ).captured.cast<Note>();
      expect(captured.single.syncStatus, SyncStatus.synced);
    });

    test('pulls remote notes with no local conflict and upserts them', () async {
      final remote = buildNote(id: 'b', syncStatus: SyncStatus.synced);
      when(
        () => localDataSource.getPendingNotes(),
      ).thenAnswer((_) async => []);
      when(
        () => remoteDataSource.pullNotesUpdatedAfter(any()),
      ).thenAnswer((_) async => [remote]);

      await syncService.syncOnce();

      verify(() => localDataSource.upsertNote(remote)).called(1);
    });

    test('a strictly newer local pending note wins over an older remote copy', () async {
      final local = buildNote(
        id: 'c',
        title: 'Local edit',
        updatedAt: DateTime.utc(2026, 1, 2),
        syncStatus: SyncStatus.pending,
      );
      final remote = buildNote(
        id: 'c',
        title: 'Remote edit',
        updatedAt: DateTime.utc(2026, 1, 1),
        syncStatus: SyncStatus.synced,
      );
      when(
        () => localDataSource.getPendingNotes(),
      ).thenAnswer((_) async => [local]);
      when(
        () => remoteDataSource.pullNotesUpdatedAfter(any()),
      ).thenAnswer((_) async => [remote]);

      await syncService.syncOnce();

      final captured = verify(
        () => localDataSource.upsertNote(captureAny()),
      ).captured.cast<Note>();
      expect(captured.last.title, 'Local edit');
      expect(captured.last.syncStatus, SyncStatus.synced);
    });

    test('a strictly newer remote copy overwrites an older local pending edit', () async {
      final local = buildNote(
        id: 'd',
        title: 'Local edit',
        updatedAt: DateTime.utc(2026, 1, 1),
        syncStatus: SyncStatus.pending,
      );
      final remote = buildNote(
        id: 'd',
        title: 'Remote edit',
        updatedAt: DateTime.utc(2026, 1, 2),
        syncStatus: SyncStatus.synced,
      );
      when(
        () => localDataSource.getPendingNotes(),
      ).thenAnswer((_) async => [local]);
      when(
        () => remoteDataSource.pullNotesUpdatedAfter(any()),
      ).thenAnswer((_) async => [remote]);

      await syncService.syncOnce();

      final captured = verify(
        () => localDataSource.upsertNote(captureAny()),
      ).captured.cast<Note>();
      expect(captured.last.title, 'Remote edit');
    });

    test('a tie in updatedAt favors the remote copy', () async {
      final tiedAt = DateTime.utc(2026, 1, 1);
      final local = buildNote(
        id: 'e',
        title: 'Local edit',
        updatedAt: tiedAt,
        syncStatus: SyncStatus.pending,
      );
      final remote = buildNote(
        id: 'e',
        title: 'Remote edit',
        updatedAt: tiedAt,
        syncStatus: SyncStatus.synced,
      );
      when(
        () => localDataSource.getPendingNotes(),
      ).thenAnswer((_) async => [local]);
      when(
        () => remoteDataSource.pullNotesUpdatedAfter(any()),
      ).thenAnswer((_) async => [remote]);

      await syncService.syncOnce();

      final captured = verify(
        () => localDataSource.upsertNote(captureAny()),
      ).captured.cast<Note>();
      expect(captured.last.title, 'Remote edit');
    });

    test('a local tombstone newer than the remote copy is pushed and stays deleted', () async {
      final tombstone = buildNote(
        id: 'f',
        updatedAt: DateTime.utc(2026, 1, 2),
        syncStatus: SyncStatus.pending,
        isDeleted: true,
      );
      final remote = buildNote(
        id: 'f',
        updatedAt: DateTime.utc(2026, 1, 1),
        syncStatus: SyncStatus.synced,
      );
      when(
        () => localDataSource.getPendingNotes(),
      ).thenAnswer((_) async => [tombstone]);
      when(
        () => remoteDataSource.pullNotesUpdatedAfter(any()),
      ).thenAnswer((_) async => [remote]);

      await syncService.syncOnce();

      verify(() => remoteDataSource.pushNote(tombstone)).called(1);
      final captured = verify(
        () => localDataSource.upsertNote(captureAny()),
      ).captured.cast<Note>();
      expect(captured.last.isDeleted, isTrue);
      expect(captured.last.syncStatus, SyncStatus.synced);
    });

    test('a remote tombstone newer than the local copy soft-deletes it locally', () async {
      final local = buildNote(
        id: 'g',
        updatedAt: DateTime.utc(2026, 1, 1),
        syncStatus: SyncStatus.pending,
      );
      final remoteTombstone = buildNote(
        id: 'g',
        updatedAt: DateTime.utc(2026, 1, 2),
        syncStatus: SyncStatus.synced,
        isDeleted: true,
      );
      when(
        () => localDataSource.getPendingNotes(),
      ).thenAnswer((_) async => [local]);
      when(
        () => remoteDataSource.pullNotesUpdatedAfter(any()),
      ).thenAnswer((_) async => [remoteTombstone]);

      await syncService.syncOnce();

      final captured = verify(
        () => localDataSource.upsertNote(captureAny()),
      ).captured.cast<Note>();
      expect(captured.last.isDeleted, isTrue);
    });

    test('reports SyncFailure and emits SyncState.error when a push fails', () async {
      when(
        () => localDataSource.getPendingNotes(),
      ).thenAnswer((_) async => [buildNote()]);
      when(() => remoteDataSource.pushNote(any())).thenThrow(Exception('boom'));

      final statuses = <SyncState>[];
      final subscription = syncService.statusStream.listen(statuses.add);

      final result = await syncService.syncOnce();
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(result, isA<Error<void>>());
      expect(statuses, contains(SyncState.error));
    });
  });

  group('connectivity-triggered sync', () {
    test('runs a sync pass only on transition from disconnected to connected', () async {
      when(
        () => localDataSource.getPendingNotes(),
      ).thenAnswer((_) async => []);
      when(
        () => remoteDataSource.pullNotesUpdatedAfter(any()),
      ).thenAnswer((_) async => []);

      syncService.start();

      connectivityController.add([ConnectivityResult.wifi]);
      await Future<void>.delayed(Duration.zero);
      connectivityController.add([ConnectivityResult.wifi]);
      await Future<void>.delayed(Duration.zero);

      verify(() => remoteDataSource.pullNotesUpdatedAfter(any())).called(1);
    });
  });
}
