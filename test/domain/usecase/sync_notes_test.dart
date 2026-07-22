import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:offline_notes_sync/domain/core/result.dart';
import 'package:offline_notes_sync/domain/repositories/notes_repository.dart';
import 'package:offline_notes_sync/domain/usecases/sync_notes.dart';

class MockNotesRepository extends Mock implements NotesRepository {}

void main() {
  late MockNotesRepository repository;
  late SyncNotes syncNotes;

  setUp(() {
    repository = MockNotesRepository();
    syncNotes = SyncNotes(repository);
  });

  test('delegates to NotesRepository.syncNotes and returns its result', () async {
    when(
      () => repository.syncNotes(),
    ).thenAnswer((_) async => const Success(null));

    final result = await syncNotes();

    expect(result, isA<Success<void>>());
    verify(() => repository.syncNotes()).called(1);
  });
}
