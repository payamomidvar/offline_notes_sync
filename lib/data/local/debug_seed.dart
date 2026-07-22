import 'dart:math';

import '../../domain/entities/note.dart';
import 'notes_dao.dart';
import 'app_database.dart';


const _loremSentences = [
  'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
  'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
  'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.',
  'Duis aute irure dolor in reprehenderit in voluptate velit esse.',
  'Excepteur sint occaecat cupidatat non proident, sunt in culpa.',
];

Future<void> seedDebugNotes(NotesDao dao, {int count = 500}) async {
  final random = Random();
  final now = DateTime.now().toUtc().millisecondsSinceEpoch;

  final rows = List.generate(count, (index) {
    final sentenceCount = 1 + random.nextInt(4);
    final body = List.generate(
      sentenceCount,
      (_) => _loremSentences[random.nextInt(_loremSentences.length)],
    ).join(' ');

    return NoteRow(
      id: 'seed-$index-$now',
      title: 'Seeded note #$index',
      body: body,
      batteryAtCreation: random.nextInt(5) == 0 ? null : random.nextInt(101),
      createdAt: now - index * 60000,
      updatedAt: now - index * 60000,
      syncStatus: SyncStatus.synced.name,
      isDeleted: false,
    );
  });

  await dao.upsertNotes(rows);
}
