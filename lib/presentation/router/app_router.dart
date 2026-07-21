import 'package:go_router/go_router.dart';

import '../screens/note_edit_screen.dart';
import '../screens/notes_list_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/notes',
  routes: [
    GoRoute(
      path: '/notes',
      builder: (context, state) => const NotesListScreen(),
    ),
    GoRoute(
      path: '/notes/new',
      builder: (context, state) => const NoteEditScreen(),
    ),
    GoRoute(
      path: '/notes/:id/edit',
      builder: (context, state) =>
          NoteEditScreen(noteId: state.pathParameters['id']),
    ),
  ],
);
