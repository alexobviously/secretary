import 'package:secretary/secretary.dart';

class RecurringTask<K, T> {
  final K key;
  final Task<T>? task;
  final TaskBuilder<T>? taskBuilder;
  final int maxRuns;
  final List<SecretaryTask<K, T>> runs;
  final Duration interval;
  final TaskOverrides<T> overrides;

  int get numRuns => runs.length;
  bool get canRun => maxRuns == 0 || runs.length < maxRuns;

  /// Gets the execution params for the next run.
  ExecutionParams<K, T> get executionParams =>
      ExecutionParams(maxRuns: maxRuns, runs: runs);

  /// Builds the task for the next run.
  Task<T> buildTask() => task ?? taskBuilder!(executionParams);

  const RecurringTask({
    required this.key,
    this.task,
    this.taskBuilder,
    required this.maxRuns,
    this.runs = const [],
    this.interval = Duration.zero,
    this.overrides = const TaskOverrides.none(),
  }) : assert(
          task != null || taskBuilder != null,
          'Either a task or a taskBuilder must be provided, but not both.',
        );

  RecurringTask<K, T> copyWith({
    K? key,
    Task<T>? task,
    TaskBuilder<T>? taskBuilder,
    int? maxRuns,
    List<SecretaryTask<K, T>>? runs,
    TaskOverrides<T>? overrides,
  }) =>
      RecurringTask(
        key: key ?? this.key,
        task: task ?? this.task,
        taskBuilder: taskBuilder ?? this.taskBuilder,
        maxRuns: maxRuns ?? this.maxRuns,
        runs: runs ?? this.runs,
        overrides: overrides ?? this.overrides,
      );

  RecurringTask<K, T> withRun(SecretaryTask<K, T> run) =>
      copyWith(runs: [...runs, run]);
}
