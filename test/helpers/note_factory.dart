import 'package:offline_notes_sync/domain/entities/note.dart';

Note buildNote({
  String id = 'note-1',
  String title = 'Title',
  String body = 'Body',
  int? batteryAtCreation = 80,
  DateTime? createdAt,
  DateTime? updatedAt,
  SyncStatus syncStatus = SyncStatus.pending,
  bool isDeleted = false,
}) {
  final created = createdAt ?? DateTime.utc(2026, 1, 1);
  return Note(
    id: id,
    title: title,
    body: body,
    batteryAtCreation: batteryAtCreation,
    createdAt: created,
    updatedAt: updatedAt ?? created,
    syncStatus: syncStatus,
    isDeleted: isDeleted,
  );
}
