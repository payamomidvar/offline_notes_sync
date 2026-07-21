import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/note.dart';

class NotesRemoteDataSource {
  NotesRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _notesCollection =>
      _firestore.collection('notes');

  Future<void> pushNote(Note note) {
    return _notesCollection.doc(note.id).set(_toDocument(note));
  }

  Future<List<Note>> pullNotesUpdatedAfter(int sinceEpochMillis) async {
    final snapshot = await _notesCollection
        .where('updatedAt', isGreaterThan: sinceEpochMillis)
        .get();

    return snapshot.docs.map((doc) => _toEntity(doc.id, doc.data())).toList();
  }

  Map<String, dynamic> _toDocument(Note note) {
    return {
      'title': note.title,
      'body': note.body,
      'batteryAtCreation': note.batteryAtCreation,
      'createdAt': note.createdAt.toUtc().millisecondsSinceEpoch,
      'updatedAt': note.updatedAt.toUtc().millisecondsSinceEpoch,
      'isDeleted': note.isDeleted,
    };
  }

  Note _toEntity(String id, Map<String, dynamic> data) {
    return Note(
      id: id,
      title: data['title'] as String,
      body: data['body'] as String,
      batteryAtCreation: data['batteryAtCreation'] as int?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        data['createdAt'] as int,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        data['updatedAt'] as int,
        isUtc: true,
      ),
      syncStatus: SyncStatus.synced,
      isDeleted: data['isDeleted'] as bool? ?? false,
    );
  }
}
