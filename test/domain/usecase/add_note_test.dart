import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:offline_notes_sync/domain/core/result.dart';
import 'package:offline_notes_sync/domain/repositories/notes_repository.dart';
import 'package:offline_notes_sync/domain/usecases/add_note.dart';

import '../../helpers/note_factory.dart';

class MockNotesRepository extends Mock implements NotesRepository {}

void main() {
  late MockNotesRepository repository;
  late AddNote addNote;

  setUp(() {
    repository = MockNotesRepository();
    addNote = AddNote(repository);
  });

  test('delegates to NotesRepository.addNote and returns its result', () async {
    final note = buildNote();
    when(
      () => repository.addNote(note),
    ).thenAnswer((_) async => const Success(null));

    final result = await addNote(note);

    expect(result, isA<Success<void>>());
    verify(() => repository.addNote(note)).called(1);
  });
}
