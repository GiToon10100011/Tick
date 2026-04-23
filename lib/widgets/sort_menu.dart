import 'package:flutter/material.dart';

import '../providers/todo_provider.dart';

class SortMenu extends StatelessWidget {
  const SortMenu({
    super.key,
    required this.current,
    required this.onSelected,
    required this.labels,
  });

  final SortOrder current;
  final ValueChanged<SortOrder> onSelected;
  final Map<SortOrder, String> labels;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SortOrder>(
      icon: const Icon(Icons.sort),
      tooltip: '정렬',
      onSelected: onSelected,
      itemBuilder: (_) => SortOrder.values.map((order) {
        return PopupMenuItem(
          value: order,
          child: Row(
            children: [
              Icon(
                Icons.check,
                color: current == order
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(labels[order]!),
            ],
          ),
        );
      }).toList(),
    );
  }
}
