import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/note.dart';
import '../local/notes_local_data_source.dart';
import '../remote/notes_remote_data_source.dart';

enum SyncState { idle, syncing, error }

class SyncService {
  SyncService({
    required NotesLocalDataSource localDataSource,
    required NotesRemoteDataSource remoteDataSource,
    Connectivity? connectivity,
  }) : _localDataSource = localDataSource, // ignore: prefer_initializing_formals
       _remoteDataSource = remoteDataSource, // ignore: prefer_initializing_formals
       _connectivity = connectivity ?? Connectivity();

  final NotesLocalDataSource _localDataSource;
  final NotesRemoteDataSource _remoteDataSource;
  final Connectivity _connectivity;
  final StreamController<SyncState> _statusController =
      StreamController<SyncState>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _wasConnected = false;
  int _lastSyncedAtMillis = 0;

  Stream<SyncState> get statusStream => _statusController.stream;

  void start() {
    _subscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
  }

  void dispose() {
    _subscription?.cancel();
    _statusController.close();
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final isConnected = results.any(
      (result) => result != ConnectivityResult.none,
    );

    if (isConnected && !_wasConnected) {
      syncOnce();
    }

    _wasConnected = isConnected;
  }

  Future<Result<void>> syncOnce() async {
    _statusController.add(SyncState.syncing);
    try {
      final pendingNotes = await _localDataSource.getPendingNotes();

      for (final note in pendingNotes) {
        await _remoteDataSource.pushNote(note);
        await _localDataSource.upsertNote(
          note.copyWith(syncStatus: SyncStatus.synced),
        );
      }

      final pendingById = {for (final note in pendingNotes) note.id: note};

      final remoteNotes = await _remoteDataSource.pullNotesUpdatedAfter(
        _lastSyncedAtMillis,
      );

      for (final remoteNote in remoteNotes) {
        final winner = _resolveConflict(
          local: pendingById[remoteNote.id],
          remote: remoteNote,
        );
        await _localDataSource.upsertNote(winner);
      }

      _lastSyncedAtMillis = DateTime.now().toUtc().millisecondsSinceEpoch;
      _statusController.add(SyncState.idle);
      return const Success(null);
    } catch (error) {
      debugPrint('SyncService.syncOnce failed: ${error}');

      _statusController.add(SyncState.error);
      return const Error(SyncFailure('Failed to sync notes.'));
    }
  }

  Note _resolveConflict({Note? local, required Note remote}) {
    if (local == null) {
      return remote;
    }

    return local.updatedAt.isAfter(remote.updatedAt) ? local : remote;
  }

    Future<bool> _isCurrentlyConnected() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }

  Future<void> syncIfConnected() async {
    if (await _isCurrentlyConnected()) {
      await syncOnce();
    }
  }

  Future<void> deleteRemoteIfConnected(String id) async {
    if (!await _isCurrentlyConnected()) return;

    try {
      await _remoteDataSource.deleteNote(id);
    } catch (_) {
      // Best-effort: if this fails, the note stays deleted locally but not
      // remotely, with no tombstone tracked — it could reappear after a
      // future full re-pull. Acceptable for this project's scope.
    }
  }

}
