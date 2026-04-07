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
  // Hive 박스 초기화 (비동기지만 실제 write 전에 완료됨)
  queue.init();

  final repo = SupabaseTodoRepository(localQueue: queue);

  // 네트워크 상태 변경 시 repo에 전달 (온라인 복귀 시 자동 flush)
  ref.listen(isOnlineProvider, (_, online) {
    repo.setOnline(online);
  });

  return repo;
});

final activeTodosProvider = StreamProvider<List<TodoItem>>((ref) {
  return ref.watch(todoRepositoryProvider).watchActiveTodos();
});

final archivedTodosProvider = FutureProvider<List<TodoItem>>((ref) {
  return ref.watch(todoRepositoryProvider).fetchArchivedTodos();
});
