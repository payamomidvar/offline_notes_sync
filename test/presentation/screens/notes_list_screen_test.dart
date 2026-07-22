import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:offline_notes_sync/data/sync/sync_service.dart';
import 'package:offline_notes_sync/domain/core/result.dart';
import 'package:offline_notes_sync/domain/entities/note.dart';
import 'package:offline_notes_sync/domain/repositories/notes_repository.dart';
import 'package:offline_notes_sync/presentation/riverpod/notes_notifier.dart';
import 'package:offline_notes_sync/presentation/riverpod/sync_status_notifier.dart';
import 'package:offline_notes_sync/presentation/screens/notes_list_screen.dart';

import '../../helpers/note_factory.dart';

class _FakeNotesRepository implements NotesRepository {
  _FakeNotesRepository(this._notes);

  final List<Note> _notes;

  @override
  Stream<List<Note>> watchNotes() => Stream.value(_notes);

  @override
  Future<Result<void>> addNote(Note note) async => const Success(null);

  @override
  Future<Result<void>> updateNote(Note note) async => const Success(null);

  @override
  Future<Result<void>> deleteNote(Note note) async => const Success(null);

  @override
  Future<Result<void>> syncNotes() async => const Success(null);
}

class _FixedSyncStatusNotifier extends SyncStatusNotifier {
  _FixedSyncStatusNotifier(this._state);

  final SyncState _state;

  @override
  Stream<SyncState> build() => Stream.value(_state);
}

Widget _buildTestApp({
  required List<Note> notes,
  SyncState syncState = SyncState.idle,
}) {
  final router = GoRouter(
    initialLocation: '/notes',
    routes: [
      GoRoute(
        path: '/notes',
        builder: (context, state) => const NotesListScreen(),
      ),
      GoRoute(path: '/notes/new', builder: (context, state) => const SizedBox()),
      GoRoute(
        path: '/notes/:id/edit',
        builder: (context, state) => const SizedBox(),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      notesRepositoryProvider.overrideWithValue(_FakeNotesRepository(notes)),
      syncStatusNotifierProvider.overrideWith(
        () => _FixedSyncStatusNotifier(syncState),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('shows the empty state when there are no notes', (tester) async {
    await tester.pumpWidget(_buildTestApp(notes: const []));
    await tester.pumpAndSettle();

    expect(find.text('No notes yet'), findsOneWidget);
  });

  testWidgets('renders a card for each note', (tester) async {
    final notes = [
      buildNote(id: '1', title: 'First note'),
      buildNote(id: '2', title: 'Second note'),
    ];

    await tester.pumpWidget(_buildTestApp(notes: notes));
    await tester.pumpAndSettle();

    expect(find.text('First note'), findsOneWidget);
    expect(find.text('Second note'), findsOneWidget);
  });

  testWidgets('shows a syncing indicator when SyncService is syncing', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(notes: const [], syncState: SyncState.syncing),
    );
    await tester.pumpAndSettle();

    expect(find.text('Syncing'), findsOneWidget);
  });
}
