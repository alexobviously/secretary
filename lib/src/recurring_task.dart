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
  final QueuePolicy queuePolicy;
  final Callback<T>? onComplete;
  final Callback<ErrorEvent<K, T>>? onError;

  int get numRuns => runs.length;
  bool get canRun =>
      (maxRuns == 0 || runs.length < maxRuns) && validator(executionParams);
  bool get valid => validator(executionParams);
  List<Object> get errors => runs.expand((e) => e.errors).toList();

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
    this.queuePolicy = QueuePolicy.backOfQueue,
    this.onComplete,
    this.onError,
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
    QueuePolicy? queuePolicy,
    Callback<T>? onComplete,
    Callback<ErrorEvent<K, T>>? onError,
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
        queuePolicy: queuePolicy ?? this.queuePolicy,
        onComplete: onComplete ?? this.onComplete,
        onError: onError ?? this.onError,
      );

  RecurringTask<K, T> withRun(SecretaryTask<K, T> run) =>
      copyWith(runs: [...runs, run]);
}
