import 'package:flutter/material.dart';

import '../models/todo_item.dart';

class TodoTile extends StatefulWidget {
  final TodoItem todo;
  final VoidCallback onCheck;
  final Future<void> Function(String newText) onEdit;

  const TodoTile({
    super.key,
    required this.todo,
    required this.onCheck,
    required this.onEdit,
  });

  @override
  State<TodoTile> createState() => _TodoTileState();
}

class _TodoTileState extends State<TodoTile> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _opacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleCheck() async {
    await _ctrl.forward();
    widget.onCheck();
  }

  void _showEditDialog() {
    final ctrl = TextEditingController(text: widget.todo.text);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('할 일 수정'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: null,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          onSubmitted: (_) => _submitEdit(ctx, ctrl.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => _submitEdit(ctx, ctrl.text),
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitEdit(BuildContext ctx, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed == widget.todo.text) {
      Navigator.pop(ctx);
      return;
    }
    Navigator.pop(ctx);
    try {
      await widget.onEdit(trimmed);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('수정 실패: $e'),
            backgroundColor: Colors.red.shade400,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            GestureDetector(
              onTap: _handleCheck,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                widget.todo.text,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.todo.formattedCreatedAt,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(
                Icons.edit_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(160),
              ),
              onPressed: _showEditDialog,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: '수정',
            ),
          ],
        ),
      ),
    );
  }
}
