import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../data/remote/battery_channel.dart';
import '../../domain/entities/note.dart';
import '../riverpod/notes_notifier.dart';

class NoteEditScreen extends ConsumerStatefulWidget {
  const NoteEditScreen({super.key, this.noteId});

  final String? noteId;

  @override
  ConsumerState<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends ConsumerState<NoteEditScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  Note? _existingNote;
  bool _initialized = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _initializeIfNeeded(List<Note> notes) {
    if (_initialized) return;

    final matches = notes.where((n) => n.id == widget.noteId);
    if (matches.isEmpty) return;

    _existingNote = matches.first;
    _titleController.text = _existingNote!.title;
    _bodyController.text = _existingNote!.body;
    _initialized = true;
  }

  Future<void> _save() async {
    final now = DateTime.now().toUtc();

    if (_existingNote != null) {
      final updated = _existingNote!.copyWith(
        title: _titleController.text,
        body: _bodyController.text,
        updatedAt: now,
      );
      await ref.read(updateNoteProvider)(updated);
    } else {
      final batteryLevel = await const BatteryChannel().getBatteryLevel();
      final newNote = Note(
        id: const Uuid().v4(),
        title: _titleController.text,
        body: _bodyController.text,
        batteryAtCreation: batteryLevel,
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.pending,
      );
      await ref.read(addNoteProvider)(newNote);
    }

    if (mounted) {
      context.pop();
    }
  }

  Future<void> _delete() async {
    final note = _existingNote;
    if (note == null) return;

    await ref.read(deleteNoteProvider)(note.id);

    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.noteId != null) {
      final notes = ref.watch(notesNotifierProvider).value ?? const [];
      _initializeIfNeeded(notes);
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.noteId == null ? 'New note' : 'Edit note'),
        actions: [
          if (_existingNote != null)
            IconButton(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.tonalIcon(
              onPressed: _save,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Save'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                style: theme.textTheme.headlineSmall,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Title',
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
              if (_existingNote?.batteryAtCreation != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.battery_std,
                      size: 14,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Created at ${_existingNote!.batteryAtCreation}% battery',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Divider(color: theme.colorScheme.outlineVariant),
              const SizedBox(height: 12),
              TextField(
                controller: _bodyController,
                style: theme.textTheme.bodyLarge,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Start writing...',
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
