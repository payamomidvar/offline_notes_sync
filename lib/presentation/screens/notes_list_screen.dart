import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/sync/sync_service.dart';
import '../../domain/entities/note.dart';
import '../riverpod/notes_notifier.dart';
import '../riverpod/sync_status_notifier.dart';

class NotesListScreen extends ConsumerWidget {
  const NotesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesNotifierProvider);
    final syncState = ref.watch(syncStatusNotifierProvider).value;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Notes'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(child: _SyncBadge(state: syncState)),
              ),
            ],
          ),
          notesAsync.when(
            data: (notes) {
              if (notes.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                sliver: SliverList.separated(
                  itemCount: notes.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return _NoteCard(
                      note: note,
                      onTap: () => context.push('/notes/${note.id}/edit'),
                      onDelete: () => ref.read(deleteNoteProvider)(note),
                    );
                  },
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('Failed to load notes: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/notes/new'),
        icon: const Icon(Icons.add),
        label: const Text('New note'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.note_alt_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No notes yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap "New note" to write your first one.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncBadge extends StatelessWidget {
  const _SyncBadge({required this.state});

  final SyncState? state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final (icon, label, background, foreground) = switch (state) {
      SyncState.syncing => (
        Icons.sync,
        'Syncing',
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      SyncState.error => (
        Icons.sync_problem,
        'Sync error',
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
      SyncState.idle || null => (
        Icons.cloud_done_outlined,
        'Synced',
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPending = note.syncStatus == SyncStatus.pending;

    return Dismissible(
      key: ValueKey(note.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.delete_outline,
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        elevation: 0,
        color: theme.colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title.isEmpty ? '(untitled)' : note.title,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (note.body.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          note.body,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (note.batteryAtCreation != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.battery_std,
                              size: 14,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Created at ${note.batteryAtCreation}% battery',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  isPending
                      ? Icons.cloud_upload_outlined
                      : Icons.cloud_done_outlined,
                  size: 18,
                  color: isPending
                      ? theme.colorScheme.tertiary
                      : theme.colorScheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
