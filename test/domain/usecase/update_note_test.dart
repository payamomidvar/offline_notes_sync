import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:offline_notes_sync/domain/core/result.dart';
import 'package:offline_notes_sync/domain/repositories/notes_repository.dart';
import 'package:offline_notes_sync/domain/usecases/update_note.dart';

import '../../helpers/note_factory.dart';

class MockNotesRepository extends Mock implements NotesRepository {}

void main() {
  late MockNotesRepository repository;
  late UpdateNote updateNote;

  setUp(() {
    repository = MockNotesRepository();
    updateNote = UpdateNote(repository);
  });

  test('delegates to NotesRepository.updateNote and returns its result', () async {
    final note = buildNote(title: 'Changed');
    when(
      () => repository.updateNote(note),
    ).thenAnswer((_) async => const Success(null));

    final result = await updateNote(note);

    expect(result, isA<Success<void>>());
    verify(() => repository.updateNote(note)).called(1);
  });
}
