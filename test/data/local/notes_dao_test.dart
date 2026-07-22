import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_notes_sync/data/local/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  NoteRow buildRow({
    required String id,
    String? title,
    String syncStatus = 'pending',
    bool isDeleted = false,
    int updatedAt = 1000,
  }) {
    return NoteRow(
      id: id,
      title: title ?? 'Title $id',
      body: 'Body $id',
      batteryAtCreation: 50,
      createdAt: 1000,
      updatedAt: updatedAt,
      syncStatus: syncStatus,
      isDeleted: isDeleted,
    );
  }

  test('upsertNote inserts a new row that watchAllNotes emits', () async {
    await database.notesDao.upsertNote(buildRow(id: 'a'));

    final notes = await database.notesDao.watchAllNotes().first;

    expect(notes, hasLength(1));
    expect(notes.first.id, 'a');
  });

  test('upsertNote with an existing id overwrites instead of duplicating', () async {
    await database.notesDao.upsertNote(buildRow(id: 'a', updatedAt: 1000));
    await database.notesDao.upsertNote(
      buildRow(id: 'a', updatedAt: 2000, title: 'Changed'),
    );

    final notes = await database.notesDao.watchAllNotes().first;

    expect(notes, hasLength(1));
    expect(notes.first.title, 'Changed');
    expect(notes.first.updatedAt, 2000);
  });

  test('watchAllNotes excludes rows marked isDeleted', () async {
    await database.notesDao.upsertNote(buildRow(id: 'a'));
    await database.notesDao.upsertNote(buildRow(id: 'b', isDeleted: true));

    final notes = await database.notesDao.watchAllNotes().first;

    expect(notes.map((n) => n.id), ['a']);
  });

  test('getPendingNotes only returns rows with syncStatus pending', () async {
    await database.notesDao.upsertNote(
      buildRow(id: 'a', syncStatus: 'pending'),
    );
    await database.notesDao.upsertNote(
      buildRow(id: 'b', syncStatus: 'synced'),
    );

    final pending = await database.notesDao.getPendingNotes();

    expect(pending.map((n) => n.id), ['a']);
  });

  test('upsertNotes writes many rows in a single batch', () async {
    final rows = List.generate(5, (i) => buildRow(id: 'note-$i'));

    await database.notesDao.upsertNotes(rows);

    final notes = await database.notesDao.watchAllNotes().first;
    expect(notes, hasLength(5));
  });
}
