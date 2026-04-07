import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/todo_item.dart';
import '../repositories/supabase_todo_repo.dart';
import '../repositories/todo_repository.dart';

final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  return SupabaseTodoRepository();
});

final activeTodosProvider = StreamProvider<List<TodoItem>>((ref) {
  return ref.watch(todoRepositoryProvider).watchActiveTodos();
});

final archivedTodosProvider = FutureProvider<List<TodoItem>>((ref) {
  return ref.watch(todoRepositoryProvider).fetchArchivedTodos();
});
