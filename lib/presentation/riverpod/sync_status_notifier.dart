import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/sync/sync_service.dart';
import 'notes_notifier.dart';

class SyncStatusNotifier extends StreamNotifier<SyncState> {
  @override
  Stream<SyncState> build() async* {
    yield SyncState.idle;
    final syncService = ref.watch(syncServiceProvider);
    yield* syncService.statusStream;
  }
}

final syncStatusNotifierProvider =
    StreamNotifierProvider<SyncStatusNotifier, SyncState>(
      SyncStatusNotifier.new,
    );
