import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/todo_item.dart';
import '../providers/todo_provider.dart';
import '../widgets/sort_menu.dart';

List<TodoItem> _applyArchiveSort(List<TodoItem> list, SortOrder order) {
  final sorted = [...list];
  switch (order) {
    case SortOrder.dateAsc:
      sorted.sort((a, b) =>
          (a.doneAt ?? a.createdAt).compareTo(b.doneAt ?? b.createdAt));
    case SortOrder.dateDesc:
      sorted.sort((a, b) =>
          (b.doneAt ?? b.createdAt).compareTo(a.doneAt ?? a.createdAt));
    case SortOrder.nameAsc:
      sorted.sort(
          (a, b) => a.text.toLowerCase().compareTo(b.text.toLowerCase()));
  }
  return sorted;
}

class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  static const _snackDuration = Duration(seconds: 2);

  bool get _isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosAsync = ref.watch(archivedTodosProvider);
    final notifier = ref.read(archivedTodosProvider.notifier);
    final sortOrder = ref.watch(archiveSortProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('아카이브', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_isDesktop)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '새로고침',
              onPressed: notifier.refresh,
            ),
          SortMenu(
            current: sortOrder,
            onSelected: (order) =>
                ref.read(archiveSortProvider.notifier).set(order),
            labels: const {
              SortOrder.dateAsc: '완료일 오래된순',
              SortOrder.dateDesc: '완료일 최신순',
              SortOrder.nameAsc: '이름순',
            },
          ),
        ],
      ),
      body: todosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (todos) {
          final sorted = _applyArchiveSort(todos, sortOrder);

          if (sorted.isEmpty) {
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
                    child: Icon(Icons.archive_outlined,
                        size: 72, color: color.withAlpha(80)),
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
            itemCount: sorted.length,
            separatorBuilder: (context, index) =>
                const Divider(indent: 16, endIndent: 16, height: 1),
            itemBuilder: (context, index) {
              final todo = sorted[index];

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
                  try {
                    await notifier.deleteTodo(todo.id);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('삭제 실패: $e'),
                        backgroundColor: Colors.red.shade400,
                        duration: _snackDuration,
                      ));
                    }
                  }
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
                      try {
                        await notifier.restoreTodo(todo.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('할 일을 복구했어요'),
                              duration: _snackDuration,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('복구 실패: $e'),
                            backgroundColor: Colors.red.shade400,
                            duration: _snackDuration,
                          ));
                        }
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
