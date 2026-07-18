import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'notes_dao.dart';

part 'app_database.g.dart';

@DataClassName('NoteRow')
class NotesTable extends Table {
  @override
  String get tableName => 'notes';

  TextColumn get id => text()();

  TextColumn get title => text()();

  TextColumn get body => text()();

  IntColumn get batteryAtCreation => integer().nullable()();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  TextColumn get syncStatus => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [NotesTable], daos: [NotesDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'offline_notes_sync.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}

