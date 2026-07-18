import 'package:equatable/equatable.dart';

enum SyncStatus { pending, synced }

class Note extends Equatable {
  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.batteryAtCreation,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
  });

  final String id;
  final String title;
  final String body;
  final int? batteryAtCreation;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;

  Note copyWith({
    String? title,
    String? body,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      batteryAtCreation: batteryAtCreation,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    body,
    batteryAtCreation,
    createdAt,
    updatedAt,
    syncStatus,
  ];
}
