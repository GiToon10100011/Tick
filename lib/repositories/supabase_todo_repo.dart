import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

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
        // 실패 시 다음 연결 때 재시도
      }
    }
    await localQueue.clearAll();
  }

  @override
  Future<TodoItem> addTodo(String text) async {
    final now = DateTime.now();

    if (!_online) {
      final tempId = 'local_${now.millisecondsSinceEpoch}';
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

  /// 초기 데이터는 REST로 즉시 가져오고, Realtime은 변경 알림 전용으로 사용.
  /// Realtime timeout이 발생해도 초기 데이터는 정상 표시됨.
  @override
  Stream<List<TodoItem>> watchActiveTodos() {
    late StreamController<List<TodoItem>> controller;
    RealtimeChannel? channel;

    Future<void> fetchAndEmit() async {
      try {
        final data = await supabase
            .from('todos')
            .select()
            .eq('user_id', _userId)
            .eq('is_archived', false)
            .order('created_at');
        if (!controller.isClosed) {
          controller.add(data.map(TodoItem.fromMap).toList());
        }
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    controller = StreamController<List<TodoItem>>(
      onListen: () {
        fetchAndEmit();
        channel = supabase
            .channel('active_todos_$_userId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'todos',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: _userId,
              ),
              callback: (_) => fetchAndEmit(),
            )
            .subscribe();
      },
      onCancel: () {
        channel?.unsubscribe();
        controller.close();
      },
    );

    return controller.stream;
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
