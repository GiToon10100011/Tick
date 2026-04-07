import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

/// 오프라인 상태에서 발생한 Todo 작업을 로컬에 저장했다가
/// 온라인 복귀 시 Supabase에 순서대로 반영한다.
class LocalQueueRepository {
  static const _boxName = 'offline_queue';

  Box<String>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  Box<String> get _queue {
    assert(_box != null, 'LocalQueueRepository.init()을 먼저 호출하세요');
    return _box!;
  }

  Future<void> enqueue(Map<String, dynamic> operation) async {
    await _queue.add(jsonEncode(operation));
  }

  List<Map<String, dynamic>> getPending() {
    return _queue.values
        .map((v) => jsonDecode(v) as Map<String, dynamic>)
        .toList();
  }

  Future<void> clearAll() async {
    await _queue.clear();
  }

  bool get hasPending => _queue.isNotEmpty;
}
