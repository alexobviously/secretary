import 'package:elegant/elegant.dart' show Result;
import 'package:secretary/secretary.dart';

class SecretaryState<K, T> {
  final SecretaryStatus status;
  final List<TaskState<K, T>> active;
  final List<TaskState<K, T>> queue;
  final List<RecurringTaskState<K, T>> recurring;

  List<K> get activeKeys => active.map((e) => e.key).toList();
  List<K> get queueKeys => queue.map((e) => e.key).toList();
  List<K> get recurringKeys => recurring.map((e) => e.key).toList();
  int get numTasks => active.length + queue.length + recurring.length;

  const SecretaryState({
    required this.status,
    this.active = const [],
    this.queue = const [],
    this.recurring = const [],
  });

  @override
  String toString() {
    final activeStr =
        'active: ${active.length} ${activeKeys.take(3)}${active.length > 3 ? '...' : ''}';
    final queueStr =
        'queue: ${queue.length} ${queueKeys.take(3)}${queue.length > 3 ? '...' : ''}';
    final recurringStr =
        'recurring: ${recurring.length} ${recurringKeys.take(3)}${recurring.length > 3 ? '...' : ''}';
    return 'SecretaryState(status: ${status.name}, $activeStr, $queueStr, $recurringStr)';
  }
}

class TaskState<K, T> {
  final K key;
  final int maxAttempts;
  final List<Result<T, Object>> results;

  List<Object> get errors =>
      results.where((e) => !e.ok).map((e) => e.error!).toList();
  int get attempts => results.length;
  bool get canRetry => attempts < maxAttempts;
  bool get succeeded => results.isNotEmpty && results.last.ok;
  bool get failed => !canRetry && !succeeded;
  bool get finished => !canRetry || succeeded;
  Result<T, Object>? get lastResult => results.isNotEmpty ? results.last : null;

  const TaskState({
    required this.key,
    required this.maxAttempts,
    this.results = const [],
  });

  factory TaskState.fromTask(SecretaryTask<K, T> task) => TaskState(
    key: task.key,
    maxAttempts: task.maxAttempts,
    results: task.results,
  );
}

class RecurringTaskState<K, T> {
  final K key;
  final RecurringTaskStatus status;
  final int maxRuns;
  final List<TaskState<K, T>> runs;

  int get numRuns => runs.length;

  const RecurringTaskState({
    required this.key,
    required this.status,
    required this.maxRuns,
    this.runs = const [],
  });

  factory RecurringTaskState.fromTask(
    RecurringTask<K, T> task,
    RecurringTaskStatus status,
  ) => RecurringTaskState(
    key: task.key,
    status: status,
    maxRuns: task.maxRuns,
    runs: task.runs.map((e) => TaskState<K, T>.fromTask(e)).toList(),
  );
}

enum RecurringTaskStatus { active, queued, waiting, none }
