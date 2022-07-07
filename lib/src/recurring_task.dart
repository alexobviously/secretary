import 'package:secretary/secretary.dart';

class RecurringTask<K, T> {
  final K key;
  final Task<T>? task;
  final TaskBuilder<T>? taskBuilder;
  final int maxRuns;
  final List<SecretaryTask<K, T>> runs;
  final Duration interval;

  int get numRuns => runs.length;
  bool get canRun => maxRuns == 0 || runs.length < maxRuns;

  /// Gets the execution params for the next run.
  ExecutionParams get executionParams =>
      ExecutionParams(maxRuns: maxRuns, runs: runs);

  const RecurringTask({
    required this.key,
    this.task,
    this.taskBuilder,
    required this.maxRuns,
    this.runs = const [],
    this.interval = Duration.zero,
  }) : assert(
          task != null || taskBuilder != null,
          'Either a task or a taskBuilder must be provided, but not both.',
        );

  RecurringTask copyWith({
    K? key,
    Task<T>? task,
    TaskBuilder<T>? taskBuilder,
    int? maxRuns,
    List<SecretaryTask<K, T>>? runs,
  }) =>
      RecurringTask(
        key: key ?? this.key,
        task: task ?? this.task,
        taskBuilder: taskBuilder ?? this.taskBuilder,
        maxRuns: maxRuns ?? this.maxRuns,
        runs: runs ?? this.runs,
      );
}
