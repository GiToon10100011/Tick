import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/todo_item.dart';
import '../providers/todo_provider.dart';
import '../widgets/sort_menu.dart';
import '../widgets/todo_tile.dart';
import 'archive_screen.dart';

List<TodoItem> _applySort(List<TodoItem> list, SortOrder order) {
  final sorted = [...list];
  switch (order) {
    case SortOrder.dateAsc:
      sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    case SortOrder.dateDesc:
      sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    case SortOrder.nameAsc:
      sorted.sort((a, b) =>
          a.text.toLowerCase().compareTo(b.text.toLowerCase()));
  }
  return sorted;
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final _textCtrl = TextEditingController();

  static const _snackDuration = Duration(seconds: 2);

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _addTodo() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    _textCtrl.clear();
    FocusScope.of(context).unfocus();

    try {
      await ref.read(activeTodosProvider.notifier).addTodo(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('추가 실패: $e'),
          backgroundColor: Colors.red.shade400,
          duration: _snackDuration,
        ));
      }
    }
  }

  Future<void> _archiveTodo(String id, String text) async {
    try {
      await ref.read(activeTodosProvider.notifier).archiveTodo(id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('완료 처리 실패: $e'),
          backgroundColor: Colors.red.shade400,
          duration: _snackDuration,
        ));
      }
      return;
    }
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('"$text" 완료!'),
        duration: _snackDuration,
        action: SnackBarAction(
          label: '취소',
          onPressed: () =>
              ref.read(activeTodosProvider.notifier).restoreTodo(id),
        ),
      ));
  }

  bool get _isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  @override
  Widget build(BuildContext context) {
    final todosAsync = ref.watch(activeTodosProvider);
    final sortOrder = ref.watch(activeSortProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tick', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_isDesktop)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '새로고침',
              onPressed: () =>
                  ref.read(activeTodosProvider.notifier).refresh(),
            ),
          SortMenu(
            current: sortOrder,
            onSelected: (order) =>
                ref.read(activeSortProvider.notifier).set(order),
            labels: const {
              SortOrder.dateAsc: '날짜 오름차순',
              SortOrder.dateDesc: '날짜 내림차순',
              SortOrder.nameAsc: '이름순',
            },
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ArchiveScreen()),
            ),
            child: const Text('아카이브'),
          ),
        ],
      ),
      body: todosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (todos) {
          final sorted = _applySort(todos, sortOrder);
          if (sorted.isEmpty) {
            return _EmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: sorted.length,
            separatorBuilder: (context, index) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final todo = sorted[index];
              return TodoTile(
                key: ValueKey(todo.id),
                todo: todo,
                onCheck: () => _archiveTodo(todo.id, todo.text),
                onEdit: (newText) => ref
                    .read(activeTodosProvider.notifier)
                    .updateTodo(todo.id, newText),
              );
            },
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textCtrl,
                  decoration: InputDecoration(
                    hintText: '할 일 추가',
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  onSubmitted: (_) => _addTodo(),
                  textInputAction: TextInputAction.done,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _addTodo,
                style: FilledButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(14),
                ),
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
            child:
                Icon(Icons.check_circle_outline, size: 72, color: color.withAlpha(80)),
          ),
          const SizedBox(height: 16),
          Text(
            '할 일이 없어요',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            '아래에서 새 할 일을 추가해보세요',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: color.withAlpha(160)),
          ),
        ],
      ),
    );
  }
}
