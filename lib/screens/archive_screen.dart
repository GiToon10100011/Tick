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
            final color = Theme.of(context).colorScheme.onSurfaceVariant;
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) =>
                        Transform.scale(scale: value, child: child),
                    child: Icon(Icons.archive_outlined, size: 72, color: color.withAlpha(80)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '완료된 항목이 없어요',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: color, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '할 일을 체크하면 여기에 쌓여요',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: color.withAlpha(160)),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: todos.length,
            separatorBuilder: (context, index) =>
                const Divider(indent: 16, endIndent: 16, height: 1),
            itemBuilder: (context, index) {
              final todo = todos[index];

              return Dismissible(
                key: ValueKey(todo.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.red.shade400,
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('영구 삭제'),
                      content: Text('"${todo.text}"을(를) 영구 삭제할까요?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('취소'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: Colors.red.shade400),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('삭제'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) async {
                  await ref.read(todoRepositoryProvider).deleteTodo(todo.id);
                  ref.invalidate(archivedTodosProvider);
                },
                child: ListTile(
                  leading: Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    todo.text,
                    style: const TextStyle(decoration: TextDecoration.lineThrough),
                  ),
                  subtitle: Text(
                    '추가: ${todo.formattedCreatedAt}  ·  완료: ${todo.formattedDoneAt}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.undo),
                    tooltip: '완료 취소 (복구)',
                    onPressed: () async {
                      await ref.read(todoRepositoryProvider).restoreTodo(todo.id);
                      ref.invalidate(archivedTodosProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('할 일을 복구했어요')),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
