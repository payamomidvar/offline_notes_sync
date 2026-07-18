import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'data/local/app_database.dart';
import 'firebase_options.dart';
import 'presentation/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final database = AppDatabase();

  runApp(OfflineNotesSyncApp(database: database));
}

class OfflineNotesSyncApp extends StatelessWidget {
  const OfflineNotesSyncApp({super.key, required this.database});

  final AppDatabase database;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Offline Notes Sync',
      theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}
