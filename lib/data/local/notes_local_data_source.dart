import '../../domain/entities/note.dart';
import 'app_database.dart';
import 'notes_dao.dart';

class NotesLocalDataSource {
  const NotesLocalDataSource(this._dao);

  final NotesDao _dao;

  Stream<List<Note>> watchNotes() {
    return _dao.watchAllNotes().map(
      (rows) => rows.map(_toEntity).toList(),
    );
  }

  Future<void> upsertNote(Note note) {
    return _dao.upsertNote(_toRow(note));
  }

  Future<void> deleteNote(String id) {
    return _dao.deleteNoteById(id);
  }

  Note _toEntity(NoteRow row) {
    return Note(
      id: row.id,
      title: row.title,
      body: row.body,
      batteryAtCreation: row.batteryAtCreation,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAt,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.updatedAt,
        isUtc: true,
      ),
      syncStatus: SyncStatus.values.byName(row.syncStatus),
    );
  }

  NoteRow _toRow(Note note) {
    return NoteRow(
      id: note.id,
      title: note.title,
      body: note.body,
      batteryAtCreation: note.batteryAtCreation,
      createdAt: note.createdAt.toUtc().millisecondsSinceEpoch,
      updatedAt: note.updatedAt.toUtc().millisecondsSinceEpoch,
      syncStatus: note.syncStatus.name,
    );
  }
}
