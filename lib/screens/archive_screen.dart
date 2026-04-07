import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/todo_provider.dart';

class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosAsync = ref.watch(archivedTodosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('아카이브', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: todosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (todos) {
          if (todos.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.archive_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '완료된 항목이 없어요',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: todos.length,
            separatorBuilder: (context, index) => const Divider(indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final todo = todos[index];
              return ListTile(
                leading: Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  todo.text,
                  style: const TextStyle(decoration: TextDecoration.lineThrough),
                ),
                subtitle: Text('추가: ${todo.formattedCreatedAt}  완료: ${todo.formattedDoneAt}'),
                onLongPress: () => _showActions(context, ref, todo.id),
              );
            },
          );
        },
      ),
    );
  }

  void _showActions(BuildContext context, WidgetRef ref, String id) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.undo),
              title: const Text('완료 취소 (복구)'),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(todoRepositoryProvider).restoreTodo(id);
                ref.invalidate(archivedTodosProvider);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red.shade400),
              title: Text('영구 삭제', style: TextStyle(color: Colors.red.shade400)),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(todoRepositoryProvider).deleteTodo(id);
                ref.invalidate(archivedTodosProvider);
              },
            ),
          ],
        ),
      ),
    );
  }
}
