import 'dart:async';

import 'package:secretary/secretary.dart';

/// A task manager.
class Secretary<K, T> {
  /// The amount of time to wait before checking for new tasks when the queue is empty.
  final Duration checkInterval;

  /// The amount of time to wait before retrying a task, if it was the last task attempted.
  final Duration retryDelay;

  /// A validator function that will be called on results to determine if the
  /// task succeeded.
  /// It should return null if the task was considered a success, and the error otherwise.
  final Validator<T> validator;

  /// A validator function that will determine if a recurring task should be
  /// continued each run. Takes an `ExecutionParams<K, T>` object in and returns
  /// a boolean. True means the recurring task will continue, and false stops it.
  final RecurringValidator<K, T> recurringValidator;

  /// A test to determine if a task should be retried or not.
  /// Takes an error as an input (the result of [validator]), and returns a bool.
  final RetryTest retryIf;

  /// Dictates what to do with a task that needs to be retried, i.e. should it
  /// return to the back of the queue or be retried immediately?
  final RetryPolicy retryPolicy;

  /// Dictates what the Secretary will wait for when `stop()` or `dispose()`
  /// are called.
  final StopPolicy stopPolicy;

  /// The maximum number of times to attempt a task before marking it as failed.
  final int maxAttempts;

  Secretary({
    this.checkInterval = const Duration(milliseconds: 50),
    this.retryDelay = const Duration(milliseconds: 1000),
    this.validator = Validators.pass,
    this.recurringValidator = RecurringValidators.pass,
    this.retryIf = RetryIf.alwaysRetry,
    this.retryPolicy = RetryPolicy.backOfQueue,
    this.stopPolicy = StopPolicy.finishActive,
    this.maxAttempts = 1,
    bool autostart = true,
  }) {
    if (autostart) start();
  }

  late final _streamController =
      StreamController<SecretaryEvent<K, T>>.broadcast();

  /// A stream of all events - success, retry and failure.
  Stream<SecretaryEvent<K, T>> get stream => _streamController.stream;

  /// A stream of only successful execution events.
  Stream<SuccessEvent<K, T>> get successStream =>
      stream.where((e) => e.isSuccess).map((e) => e as SuccessEvent<K, T>);

  /// A stream of results of successful task executions.
  Stream<T> get resultStream => successStream.map((e) => e.result);

  /// A stream of all error events. This includes both errors that result in
  /// retries, and ones that result in failure.
  Stream<ErrorEvent<K, T>> get errorStream =>
      stream.where((e) => e.isError).map((e) => e as ErrorEvent<K, T>);

  /// A stream of task executions that ended in failure.
  Stream<FailureEvent<K, T>> get failureStream =>
      stream.where((e) => e.isFailure).map((e) => e as FailureEvent<K, T>);

  /// A stream of task executions that were queued to be retried.
  Stream<RetryEvent<K, T>> get retryStream =>
      stream.where((e) => e.isRetry).map((e) => e as RetryEvent<K, T>);

  /// A map linking all keys in the queue and active lists with their tasks.
  Map<K, SecretaryTask<K, T>> tasks = {};

  /// Is there anything left to do?
  bool get hasTasks => tasks.isNotEmpty;

  Map<K, RecurringTask<K, T>> recurringTasks = {};

  bool get hasRecurringTasks => recurringTasks.isNotEmpty;

  final Map<K, Timer> _timers = {};

  /// All task keys waiting to be executed.
  List<K> queue = [];

  /// All tasks currently being executed.
  List<K> active = [];

  /// The last event that was logged.
  SecretaryEvent<K, T>? lastEvent;

  late final _stateStreamController =
      StreamController<SecretaryState>.broadcast();

  /// A stream of Secretary's state.
  Stream<SecretaryState> get stateStream => _stateStreamController.stream;

  /// The current state of the Secretary.
  SecretaryState state = SecretaryState.idle;

  /// Adds an item to the queue.
  /// [key] is used to identify the task, and should conform to the K type
  /// constraint of the Secretary. It isn't really important what the [key] is,
  /// but note that tasks with keys that already exist in the queue will be rejected.
  ///
  /// [task] should be a function that returns a Future<T>, where T is the T
  /// type constraint of the Secretary.
  ///
  /// If [index] is specified, then the item will be inserted at that point in
  /// the queue, otherwise it will be added to the end. A negative index can
  /// also be used, e.g. -1 will add the task as the second last element.
  ///
  /// [onComplete] and [onError] will be called on completion and error events
  /// for this task, respectively. These are not required; all of the events
  /// for all tasks are passed to the streams in `Secretary`.
  ///
  /// Use [overrides] to override parameters of the Secretary for this task only,
  /// such as [validator] and [maxAttempts].
  bool add(
    K key,
    Task<T> task, {
    int? index,
    Callback<T>? onComplete,
    Callback<ErrorEvent<K, T>>? onError,
    TaskOverrides<T> overrides = const TaskOverrides.none(),
  }) {
    if (queue.contains(key) || active.contains(key)) return false;
    final item = SecretaryTask<K, T>(
      key: key,
      task: task,
      validator: overrides.validator ?? validator,
      onComplete: onComplete,
      onError: onError,
      retryIf: overrides.retryIf ?? retryIf,
      retryPolicy: overrides.retryPolicy ?? retryPolicy,
      retryDelay: overrides.retryDelay ?? retryDelay,
      maxAttempts: overrides.maxAttempts ?? maxAttempts,
    );
    tasks[key] = item;
    if (index == null) {
      queue.add(key);
    } else {
      if (index < 0) index = queue.length - index;
      if (index < 0 || index >= queue.length) return false;
      queue.insert(index, key);
    }
    return true;
  }

  bool addRecurring(
    K key, {
    Task<T>? task,
    TaskBuilder<K, T>? taskBuilder,
    Duration interval = Duration.zero,
    bool runImmediately = false,
    int maxRuns = 0,
    TaskOverrides<T> overrides = const TaskOverrides.none(),
    RecurringValidator<K, T>? validator,
  }) {
    if (!(task != null || taskBuilder != null)) {
      throw Exception(
          'Either a task or a taskBuilder must be provided, but not both.');
    }
    RecurringTask<K, T> recurringTask = RecurringTask(
      key: key,
      task: task,
      taskBuilder: taskBuilder,
      interval: interval,
      maxRuns: maxRuns,
      overrides: overrides,
      validator: validator ?? recurringValidator,
    );
    recurringTasks[key] = recurringTask;
    Timer t = Timer(
      runImmediately ? Duration.zero : interval,
      _buildTimerCallback(recurringTask),
    );
    _timers[key] = t;
    return true;
  }

  /// Starts executing tasks in the queue.
  void start() {
    if (state != SecretaryState.idle) return;
    _setState(SecretaryState.active);
    _loop();
  }

  /// Stops execution. Can be started again as long as it wasn't disposed.
  /// Depends on the `StopPolicy`.
  Future<void> stop() async {
    _setState(SecretaryState.stopping);
    stopAllRecurring(); // TODO: add policies for this
    if (stopPolicy == StopPolicy.stopImmediately) {
      _setState(SecretaryState.idle);
      return;
    }

    await for (final newState in stateStream) {
      if ([SecretaryState.idle, SecretaryState.disposed].contains(newState)) {
        break;
      }
    }
  }

  /// Dispose the Secretary and all resources associated with it.
  /// Will have to wait for for execution to stop, depending on the `StopPolicy`.
  Future<void> dispose() async {
    await stop();
    _setState(SecretaryState.disposed);
    _streamController.close();
    _stateStreamController.close();
  }

  void _addEvent(SecretaryEvent<K, T> event) {
    if (state == SecretaryState.disposed) return;
    _streamController.add(event);
    lastEvent = event;
  }

  void _setState(SecretaryState newState) {
    state = newState;
    _stateStreamController.add(newState);
  }

  List<RecurringTask<K, T>> stopAllRecurring() {
    _clearTimers();
    final tasks = [...recurringTasks.values];
    recurringTasks.clear();
    return tasks;
  }

  void _clearTimers() {
    for (Timer t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
  }

  void _loop() async {
    while ([SecretaryState.active, SecretaryState.stopping].contains(state)) {
      if (state == SecretaryState.stopping) {
        bool stop = true;
        if ((stopPolicy == StopPolicy.finishQueue &&
                (queue.isNotEmpty || active.isNotEmpty)) ||
            (stopPolicy == StopPolicy.finishActive && active.isNotEmpty)) {
          stop = false;
        }
        if (stop) {
          _setState(SecretaryState.idle);
          break;
        }
      }

      if (queue.isNotEmpty) {
        final task = await _doNextTask();
        if (task != null &&
            recurringTasks.containsKey(task.key) &&
            task.finished) {
          _handleRecurring(task);
        }
      } else {
        await Future.delayed(checkInterval);
      }
    }
  }

  void _handleRecurring(SecretaryTask<K, T> task) {
    RecurringTask<K, T> recurringTask = recurringTasks[task.key]!;
    recurringTask = recurringTask.withRun(task);
    recurringTasks[recurringTask.key] = recurringTask;
    _timers[recurringTask.key]?.cancel(); // shouldn't be necessary but ok
    _timers.remove(recurringTask.key);
    if (recurringTask.canRun) {
      Timer timer = Timer(
        recurringTask.interval,
        _buildTimerCallback(recurringTask),
      );
      _timers[recurringTask.key] = timer;
    } else {
      recurringTasks.remove(recurringTask.key);
      // TODO: emit some sort of event?
    }
  }

  VoidCallback _buildTimerCallback(RecurringTask<K, T> task) => () => add(
        task.key,
        task.buildTask(),
        overrides: task.overrides,
      );

  Future<SecretaryTask<K, T>?> _doNextTask() async {
    if (queue.isEmpty) return null;
    final key = queue.first;
    return await _doTask(key);
  }

  Future<SecretaryTask<K, T>?> _doTask(K key) async {
    if (!queue.contains(key)) return null;

    queue.remove(key);
    active.add(key);
    SecretaryTask<K, T> task = tasks[key]!;

    if (lastEvent != null && lastEvent!.isRetry && lastEvent!.key == key) {
      await Future.delayed(task.retryDelay);
    }

    T result = await task.task();
    Object? error;

    if (task.validator != null) {
      error = task.validator!(result);
    }

    active.remove(key);
    if (error == null) {
      tasks.remove(key);
      task = task.withSuccess(result);
      task.onComplete?.call(result);
      _addEvent(SuccessEvent(
        key: key,
        result: result,
        errors: task.errors,
      ));
    } else {
      return _handleError(task, error);
    }
    return task;
  }

  SecretaryTask<K, T> _handleError(SecretaryTask<K, T> task, Object error) {
    task = task.withError(error);
    tasks[task.key] = task;
    if (task.canRetry && task.retryIf(error)) {
      switch (task.retryPolicy) {
        case RetryPolicy.backOfQueue:
          queue.add(task.key);
          break;
        case RetryPolicy.frontOfQueue:
          queue.insert(0, task.key);
          break;
      }
      final event = RetryEvent.fromTask(task);
      task.onError?.call(event);
      _addEvent(event);
    } else {
      tasks.remove(task.key);
      final event = FailureEvent.fromTask(task);
      task.onError?.call(event);
      _addEvent(event);
    }
    return task;
  }
}
