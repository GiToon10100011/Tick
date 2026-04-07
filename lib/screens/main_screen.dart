import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/todo_provider.dart';
import '../widgets/todo_tile.dart';
import 'archive_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final _textCtrl = TextEditingController();

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
      await ref.read(todoRepositoryProvider).addTodo(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('추가 실패: $e'), backgroundColor: Colors.red.shade400),
        );
      }
    }
  }

  Future<void> _archiveTodo(String id, String text) async {
    await ref.read(todoRepositoryProvider).archiveTodo(id);
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('"$text" 완료!'),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: '취소',
            onPressed: () => ref.read(todoRepositoryProvider).restoreTodo(id),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final todosAsync = ref.watch(activeTodosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tick', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
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
          if (todos.isEmpty) {
            return _EmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: todos.length,
            separatorBuilder: (context, index) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final todo = todos[index];
              return TodoTile(
                key: ValueKey(todo.id),
                todo: todo,
                onCheck: () => _archiveTodo(todo.id, todo.text),
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
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
            child: Icon(Icons.check_circle_outline, size: 72, color: color.withAlpha(80)),
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
