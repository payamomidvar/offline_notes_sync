import 'package:drift/drift.dart';

import 'app_database.dart';

part 'notes_dao.g.dart';

@DriftAccessor(tables: [NotesTable])
class NotesDao extends DatabaseAccessor<AppDatabase> with _$NotesDaoMixin {
  NotesDao(super.db);

  Stream<List<NoteRow>> watchAllNotes() => select(notesTable).watch();

  Future<void> upsertNote(NoteRow note) {
    return into(notesTable).insertOnConflictUpdate(note);
  }

  Future<void> deleteNoteById(String id) {
    return (delete(notesTable)..where((tbl) => tbl.id.equals(id))).go();
  }
}
