import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:offline_notes_sync/domain/core/result.dart';
import 'package:offline_notes_sync/domain/repositories/notes_repository.dart';
import 'package:offline_notes_sync/domain/usecases/delete_note.dart';

import '../../helpers/note_factory.dart';

class MockNotesRepository extends Mock implements NotesRepository {}

void main() {
  late MockNotesRepository repository;
  late DeleteNote deleteNote;

  setUp(() {
    repository = MockNotesRepository();
    deleteNote = DeleteNote(repository);
  });

  test('delegates to NotesRepository.deleteNote with the full note and returns its result', () async {
    final note = buildNote();
    when(
      () => repository.deleteNote(note),
    ).thenAnswer((_) async => const Success(null));

    final result = await deleteNote(note);

    expect(result, isA<Success<void>>());
    verify(() => repository.deleteNote(note)).called(1);
  });
}
