import '../models/todo_item.dart';

abstract class TodoRepository {
  Future<TodoItem> addTodo(String text);
  Future<void> archiveTodo(String id);
  Future<void> restoreTodo(String id);
  Future<void> deleteTodo(String id);
  Stream<List<TodoItem>> watchActiveTodos();
  Future<List<TodoItem>> fetchArchivedTodos();
}
