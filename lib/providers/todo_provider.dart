import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/todo_item.dart';
import '../repositories/local_queue_repo.dart';
import '../repositories/supabase_todo_repo.dart';
import '../repositories/todo_repository.dart';
import 'connectivity_provider.dart';

final localQueueProvider = Provider<LocalQueueRepository>((ref) {
  return LocalQueueRepository();
});

final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  final queue = ref.watch(localQueueProvider);
  queue.init();

  final repo = SupabaseTodoRepository(localQueue: queue);

  ref.listen(isOnlineProvider, (_, online) {
    repo.setOnline(online);
  });

  return repo;
});

// ---------------------------------------------------------------------------
// Active todos — optimistic UI via StateNotifier
// ---------------------------------------------------------------------------

class ActiveTodosNotifier extends StateNotifier<AsyncValue<List<TodoItem>>> {
  ActiveTodosNotifier(this._repo) : super(const AsyncValue.loading()) {
    _subscribe();
  }

  final TodoRepository _repo;
  StreamSubscription<List<TodoItem>>? _sub;

  /// IDs currently being removed (archive). Filtered from incoming stream data
  /// so the item doesn't reappear briefly while the DB round-trip completes.
  final Set<String> _pendingRemovals = {};

  /// Temp items for optimistic adds (key = temp id).
  final Map<String, TodoItem> _pendingAdds = {};

  void _subscribe() {
    _sub = _repo.watchActiveTodos().listen(
      (serverList) {
        final filtered =
            serverList.where((t) => !_pendingRemovals.contains(t.id)).toList();
        for (final pending in _pendingAdds.values) {
          if (!filtered.any((t) => t.id == pending.id)) {
            filtered.add(pending);
          }
        }
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        state = AsyncValue.data(filtered);
      },
      onError: (e, st) {
        if (state is AsyncLoading) state = AsyncValue.error(e, st);
      },
    );
  }

  Future<void> refresh() async {
    await _sub?.cancel();
    _pendingRemovals.clear();
    _pendingAdds.clear();
    state = const AsyncValue.loading();
    _subscribe();
  }

  Future<void> addTodo(String text) async {
    final tempId = 'tmp_${DateTime.now().millisecondsSinceEpoch}';
    final tempItem = TodoItem(
      id: tempId,
      userId: '',
      text: text,
      isArchived: false,
      createdAt: DateTime.now(),
    );
    _pendingAdds[tempId] = tempItem;
    state = state.whenData((list) => [...list, tempItem]);

    try {
      final real = await _repo.addTodo(text);
      _pendingAdds.remove(tempId);
      state = state.whenData(
          (list) => list.map((t) => t.id == tempId ? real : t).toList());
    } catch (e) {
      _pendingAdds.remove(tempId);
      state = state
          .whenData((list) => list.where((t) => t.id != tempId).toList());
      rethrow;
    }
  }

  Future<void> archiveTodo(String id) async {
    _pendingRemovals.add(id);
    TodoItem? removed;
    state = state.whenData((list) {
      removed = list.where((t) => t.id == id).firstOrNull;
      return list.where((t) => t.id != id).toList();
    });

    try {
      await _repo.archiveTodo(id);
      _pendingRemovals.remove(id);
    } catch (e) {
      _pendingRemovals.remove(id);
      if (removed != null) {
        state = state.whenData((list) =>
            [...list, removed!]
              ..sort((a, b) => a.createdAt.compareTo(b.createdAt)));
      }
      rethrow;
    }
  }

  Future<void> restoreTodo(String id) async {
    // Restore is triggered from archive; active list will update via stream.
    await _repo.restoreTodo(id);
  }

  Future<void> updateTodo(String id, String text) async {
    TodoItem? original;
    state = state.whenData((list) => list.map((t) {
          if (t.id == id) {
            original = t;
            return t.copyWith(text: text);
          }
          return t;
        }).toList());

    try {
      await _repo.updateTodo(id, text);
    } catch (e) {
      if (original != null) {
        state = state.whenData(
            (list) => list.map((t) => t.id == id ? original! : t).toList());
      }
      rethrow;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final activeTodosProvider =
    StateNotifierProvider<ActiveTodosNotifier, AsyncValue<List<TodoItem>>>(
        (ref) {
  return ActiveTodosNotifier(ref.watch(todoRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Archived todos — optimistic UI via StateNotifier (autoDispose = fresh on nav)
// ---------------------------------------------------------------------------

class ArchivedTodosNotifier
    extends StateNotifier<AsyncValue<List<TodoItem>>> {
  ArchivedTodosNotifier(this._repo) : super(const AsyncValue.loading()) {
    _load();
  }

  final TodoRepository _repo;

  Future<void> _load() async {
    try {
      final todos = await _repo.fetchArchivedTodos();
      state = AsyncValue.data(todos);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _load();

  Future<void> deleteTodo(String id) async {
    final backup = state.valueOrNull;
    state = state.whenData((list) => list.where((t) => t.id != id).toList());
    try {
      await _repo.deleteTodo(id);
    } catch (e) {
      if (backup != null) state = AsyncValue.data(backup);
      rethrow;
    }
  }

  Future<void> restoreTodo(String id) async {
    final backup = state.valueOrNull;
    state = state.whenData((list) => list.where((t) => t.id != id).toList());
    try {
      await _repo.restoreTodo(id);
    } catch (e) {
      if (backup != null) state = AsyncValue.data(backup);
      rethrow;
    }
  }
}

final archivedTodosProvider = StateNotifierProvider.autoDispose<
    ArchivedTodosNotifier, AsyncValue<List<TodoItem>>>((ref) {
  return ArchivedTodosNotifier(ref.watch(todoRepositoryProvider));
});
