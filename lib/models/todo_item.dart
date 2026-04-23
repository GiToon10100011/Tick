class TodoItem {
  final String id;
  final String userId;
  final String text;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime? doneAt;

  const TodoItem({
    required this.id,
    required this.userId,
    required this.text,
    required this.isArchived,
    required this.createdAt,
    this.doneAt,
  });

  factory TodoItem.fromMap(Map<String, dynamic> map) {
    return TodoItem(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      text: map['text'] as String,
      isArchived: map['is_archived'] as bool,
      createdAt: DateTime.parse(map['created_at'] as String),
      doneAt: map['done_at'] != null ? DateTime.parse(map['done_at'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'text': text,
      'is_archived': isArchived,
      'created_at': createdAt.toIso8601String(),
      if (doneAt != null) 'done_at': doneAt!.toIso8601String(),
    };
  }

  TodoItem copyWith({String? text}) {
    return TodoItem(
      id: id,
      userId: userId,
      text: text ?? this.text,
      isArchived: isArchived,
      createdAt: createdAt,
      doneAt: doneAt,
    );
  }

  String get formattedCreatedAt => _formatDate(createdAt);
  String get formattedDoneAt => doneAt != null ? _formatDate(doneAt!) : '';

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final prefix = date.year != now.year ? '${date.year}년 ' : '';
    return '$prefix${date.month}월 ${date.day}일';
  }
}
