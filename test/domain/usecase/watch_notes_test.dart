import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:offline_notes_sync/domain/entities/note.dart';
import 'package:offline_notes_sync/domain/repositories/notes_repository.dart';
import 'package:offline_notes_sync/domain/usecases/watch_notes.dart';

import '../../helpers/note_factory.dart';

class MockNotesRepository extends Mock implements NotesRepository {}

void main() {
  late MockNotesRepository repository;
  late WatchNotes watchNotes;

  setUp(() {
    repository = MockNotesRepository();
    watchNotes = WatchNotes(repository);
  });

  test('delegates to NotesRepository.watchNotes', () async {
    final note = buildNote();
    when(
      () => repository.watchNotes(),
    ).thenAnswer((_) => Stream.value(<Note>[note]));

    await expectLater(watchNotes(), emits(<Note>[note]));
  });
}
