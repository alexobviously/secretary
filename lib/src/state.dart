import 'package:secretary/secretary.dart';

class const SecretaryState<K, T>({
  required final SecretaryStatus status,
  final List<TaskState<K, T>> active = const [],
  final List<TaskState<K, T>> queue = const [],
  final List<RecurringTaskState<K, T>> recurring = const [],
}) {
  List<K> get activeKeys => active.map((e) => e.key).toList();
  List<K> get queueKeys => queue.map((e) => e.key).toList();
  List<K> get recurringKeys => recurring.map((e) => e.key).toList();
  int get numTasks => active.length + queue.length + recurring.length;

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

class const TaskState<K, T>({
  required final K key,
  required final int maxAttempts,
  final List<Result<T, Object>> results = const [],
}) {
  List<Object> get errors => results.errs.values.toList();
  int get attempts => results.length;
  bool get canRetry => attempts < maxAttempts;
  bool get succeeded => results.isNotEmpty && results.last is Ok;
  bool get failed => !canRetry && !succeeded;
  bool get finished => !canRetry || succeeded;
  Result<T, Object>? get lastResult => results.isNotEmpty ? results.last : null;

  factory fromTask(SecretaryTask<K, T> task) => TaskState(
    key: task.key,
    maxAttempts: task.maxAttempts,
    results: task.results,
  );
}

class const RecurringTaskState<K, T>({
  required final K key,
  required final RecurringTaskStatus status,
  required final int maxRuns,
  final List<TaskState<K, T>> runs = const [],
}) {
  int get numRuns => runs.length;

  factory fromTask(
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
