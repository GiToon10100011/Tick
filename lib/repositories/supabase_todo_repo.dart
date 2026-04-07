import '../core/supabase_client.dart';
import '../models/todo_item.dart';
import 'local_queue_repo.dart';
import 'todo_repository.dart';

class SupabaseTodoRepository implements TodoRepository {
  SupabaseTodoRepository({required this.localQueue});

  final LocalQueueRepository localQueue;
  bool _online = true;

  void setOnline(bool online) {
    _online = online;
    if (online) _flush();
  }

  String get _userId => supabase.auth.currentUser!.id;

  /// 큐에 쌓인 작업을 순서대로 Supabase에 반영 (Last Write Wins)
  Future<void> _flush() async {
    if (!localQueue.hasPending) return;

    final ops = localQueue.getPending();
    for (final op in ops) {
      try {
        switch (op['type'] as String) {
          case 'add':
            await supabase.from('todos').insert({
              'id': op['id'],
              'user_id': _userId,
              'text': op['text'],
              'created_at': op['created_at'],
            });
          case 'archive':
            await supabase.from('todos').update({
              'is_archived': true,
              'done_at': op['done_at'],
            }).eq('id', op['id'] as String);
          case 'restore':
            await supabase.from('todos').update({
              'is_archived': false,
              'done_at': null,
            }).eq('id', op['id'] as String);
          case 'delete':
            await supabase.from('todos').delete().eq('id', op['id'] as String);
        }
      } catch (_) {
        // flush 중 실패 시 나머지는 계속 시도 (다음 연결 때 재시도)
      }
    }
    await localQueue.clearAll();
  }

  @override
  Future<TodoItem> addTodo(String text) async {
    final now = DateTime.now();
    final tempId = 'local_${now.millisecondsSinceEpoch}';

    if (!_online) {
      await localQueue.enqueue({
        'type': 'add',
        'id': tempId,
        'text': text,
        'created_at': now.toIso8601String(),
      });
      return TodoItem(
        id: tempId,
        userId: _userId,
        text: text,
        isArchived: false,
        createdAt: now,
      );
    }

    final data = await supabase
        .from('todos')
        .insert({'user_id': _userId, 'text': text})
        .select()
        .single();
    return TodoItem.fromMap(data);
  }

  @override
  Future<void> archiveTodo(String id) async {
    final doneAt = DateTime.now().toIso8601String();
    if (!_online) {
      await localQueue.enqueue({'type': 'archive', 'id': id, 'done_at': doneAt});
      return;
    }
    await supabase
        .from('todos')
        .update({'is_archived': true, 'done_at': doneAt})
        .eq('id', id);
  }

  @override
  Future<void> restoreTodo(String id) async {
    if (!_online) {
      await localQueue.enqueue({'type': 'restore', 'id': id});
      return;
    }
    await supabase
        .from('todos')
        .update({'is_archived': false, 'done_at': null})
        .eq('id', id);
  }

  @override
  Future<void> deleteTodo(String id) async {
    if (!_online) {
      await localQueue.enqueue({'type': 'delete', 'id': id});
      return;
    }
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
