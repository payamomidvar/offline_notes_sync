import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'presentation/router/app_router.dart';

// No billing account is available on this Firebase project (Cloud Firestore
// now requires one, even within the free quota), so this points at the
// local Firestore emulator instead. The phone and this machine must be on
// the same Wi-Fi network. Flip to false once a Blaze-plan project with a
// real Firestore database is available.
const useFirestoreEmulator = true;
const firestoreEmulatorHost = '192.168.8.21';
const firestoreEmulatorPort = 8080;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (useFirestoreEmulator) {
    FirebaseFirestore.instance.useFirestoreEmulator(
      firestoreEmulatorHost,
      firestoreEmulatorPort,
    );
  }

  runApp(const ProviderScope(child: OfflineNotesSyncApp()));
}

class OfflineNotesSyncApp extends StatelessWidget {
  const OfflineNotesSyncApp({super.key});

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
