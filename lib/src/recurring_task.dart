import 'package:secretary/secretary.dart';

class RecurringTask<K, T> {
  final K key;
  final Task<T>? task;
  final TaskBuilder<K, T>? taskBuilder;
  final int maxRuns;
  final List<SecretaryTask<K, T>> runs;
  final Duration interval;
  final TaskOverrides<T> overrides;
  final RecurringValidator<K, T> validator;

  int get numRuns => runs.length;
  bool get canRun =>
      (maxRuns == 0 || runs.length < maxRuns) && validator(executionParams);

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
    this.validator = RecurringValidators.pass,
  }) : assert(
          task != null || taskBuilder != null,
          'Either a task or a taskBuilder must be provided, but not both.',
        );

  RecurringTask<K, T> copyWith({
    K? key,
    Task<T>? task,
    TaskBuilder<K, T>? taskBuilder,
    int? maxRuns,
    List<SecretaryTask<K, T>>? runs,
    Duration? interval,
    TaskOverrides<T>? overrides,
    RecurringValidator<K, T>? validator,
  }) =>
      RecurringTask(
        key: key ?? this.key,
        task: task ?? this.task,
        taskBuilder: taskBuilder ?? this.taskBuilder,
        maxRuns: maxRuns ?? this.maxRuns,
        runs: runs ?? this.runs,
        interval: interval ?? this.interval,
        overrides: overrides ?? this.overrides,
        validator: validator ?? this.validator,
      );

  RecurringTask<K, T> withRun(SecretaryTask<K, T> run) =>
      copyWith(runs: [...runs, run]);
}
