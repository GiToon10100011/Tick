import '../core/supabase_client.dart';
import '../models/todo_item.dart';
import 'todo_repository.dart';

class SupabaseTodoRepository implements TodoRepository {
  String get _userId => supabase.auth.currentUser!.id;

  @override
  Future<TodoItem> addTodo(String text) async {
    final data = await supabase
        .from('todos')
        .insert({'user_id': _userId, 'text': text})
        .select()
        .single();
    return TodoItem.fromMap(data);
  }

  @override
  Future<void> archiveTodo(String id) async {
    await supabase
        .from('todos')
        .update({'is_archived': true, 'done_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  @override
  Future<void> restoreTodo(String id) async {
    await supabase
        .from('todos')
        .update({'is_archived': false, 'done_at': null})
        .eq('id', id);
  }

  @override
  Future<void> deleteTodo(String id) async {
    await supabase.from('todos').delete().eq('id', id);
  }

  @override
  Stream<List<TodoItem>> watchActiveTodos() {
    return supabase
        .from('todos')
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId)
        .order('created_at')
        .map((rows) => rows
            .where((r) => r['is_archived'] == false)
            .map(TodoItem.fromMap)
            .toList());
  }

  @override
  Future<List<TodoItem>> fetchArchivedTodos() async {
    final data = await supabase
        .from('todos')
        .select()
        .eq('user_id', _userId)
        .eq('is_archived', true)
        .order('done_at', ascending: false);
    return data.map(TodoItem.fromMap).toList();
  }
}
