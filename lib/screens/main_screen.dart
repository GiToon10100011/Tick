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
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '할 일이 없어요',
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
            separatorBuilder: (context, index) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final todo = todos[index];
              return TodoTile(
                key: ValueKey(todo.id),
                todo: todo,
                onCheck: () => ref.read(todoRepositoryProvider).archiveTodo(todo.id),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
