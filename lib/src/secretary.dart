import 'dart:async';
import 'package:secretary/secretary.dart';

/// A task manager.
class Secretary<K, T> {
  /// The number of tasks that can execute simultaneously.
  /// To allow infinite concurrency (i.e. no queue), set this to 0.
  final int maxConcurrentTasks;

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
  final QueuePolicy retryPolicy;

  /// Dictates what the Secretary will wait for when `stop()` or `dispose()`
  /// are called.
  final StopPolicy stopPolicy;

  /// The maximum number of times to attempt a task before marking it as failed.
  final int maxAttempts;

  /// Dictates what to do with instances of a recurring task.
  final QueuePolicy recurringQueuePolicy;

  Secretary({
    this.maxConcurrentTasks = 1,
    this.checkInterval = const Duration(milliseconds: 50),
    this.retryDelay = const Duration(milliseconds: 1000),
    this.validator = Validators.pass,
    this.recurringValidator = RecurringValidators.pass,
    this.retryIf = RetryIf.alwaysRetry,
    this.retryPolicy = QueuePolicy.backOfQueue,
    this.stopPolicy = StopPolicy.finishActive,
    this.maxAttempts = 1,
    this.recurringQueuePolicy = QueuePolicy.backOfQueue,
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
  bool get hasTaskCapacity =>
      maxConcurrentTasks == 0 || active.length < maxConcurrentTasks;

  final Map<K, Timer> _timers = {};

  /// All task keys waiting to be executed.
  List<K> queue = [];

  /// All tasks currently being executed.
  List<K> active = [];

  /// The last event that was logged.
  SecretaryEvent<K, T>? lastEvent;

  late final _statusStreamController =
      StreamController<SecretaryStatus>.broadcast();

  /// A stream of the Secretary's status.
  Stream<SecretaryStatus> get statusStream => _statusStreamController.stream;

  /// The current status of the Secretary.
  SecretaryStatus status = SecretaryStatus.idle;

  late final _stateStreamController =
      StreamController<SecretaryState>.broadcast();

  /// A stream of the Secretary's state, including the state of the queue
  /// and recurring tasks.
  Stream<SecretaryState> get stateStream => _stateStreamController.stream;

  /// The current state of the Secretary, including its state, the contents of
  /// the queue, and recurring tasks.
  SecretaryState<K, T> get state => SecretaryState(
        status: status,
        active: active.map((e) => TaskState.fromTask(tasks[e]!)).toList(),
        queue: queue.map((e) => TaskState.fromTask(tasks[e]!)).toList(),
        recurring: recurringTasks.values
            .map((e) =>
                RecurringTaskState.fromTask(e, recurringTaskStatus(e.key)))
            .toList(),
      );

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
      completer: Completer(),
      finalCompleter: Completer(),
    );
    tasks[key] = item;
    if (index == null) {
      queue.add(key);
      _emitState();
    } else {
      if (index < 0) index = queue.length - index;
      if (index < 0 || index >= queue.length) return false;
      queue.insert(index, key);
      _emitState();
    }
    return true;
  }

  /// Adds a recurring task.
  ///
  /// Either a [task] or a [taskBuilder] must be provided, but not both.
  /// If [task] is used, then the same task will be built on every run. If more
  /// complex functionality is required, for example, if the task for each run
  /// should depend on how many times the task has run before, or what the previous
  /// result was, then [taskBuilder] can be used.
  ///
  /// [interval] specifies an amount of time between a run finishing and the next
  /// run being added to the queue.
  ///
  /// [maxRuns] is the total number of times this task will run before being
  /// removed. If this is 0, then it will run indefinitely (or until the validator
  /// returns false).
  ///
  /// [overrides] works the same as with `add()` - these will override the default
  /// values of the `Secretary`.
  ///
  /// [validator] will be called after each run, to determine if the task should
  /// be run again. It takes parameters determined by the previous run.
  bool addRecurring(
    K key, {
    Task<T>? task,
    TaskBuilder<K, T>? taskBuilder,
    Duration interval = Duration.zero,
    bool runImmediately = false,
    int maxRuns = 0,
    TaskOverrides<T> overrides = const TaskOverrides.none(),
    RecurringValidator<K, T>? validator,
    QueuePolicy? queuePolicy,
    Callback<T>? onComplete,
    Callback<ErrorEvent<K, T>>? onError,
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
      queuePolicy: queuePolicy ?? recurringQueuePolicy,
      onComplete: onComplete,
      onError: onError,
    );
    recurringTasks[key] = recurringTask;
    _emitState();
    Timer t = Timer(
      runImmediately ? Duration.zero : interval,
      _buildTimerCallback(recurringTask),
    );
    _timers[key] = t;
    return true;
  }

  /// Gets the status of a recurring task with [key].
  RecurringTaskStatus recurringTaskStatus(K key) {
    if (!recurringTasks.containsKey(key)) {
      return RecurringTaskStatus.none;
    }
    if (active.contains(key)) {
      return RecurringTaskStatus.active;
    }
    if (queue.contains(key)) {
      return RecurringTaskStatus.queued;
    }
    return RecurringTaskStatus.waiting;
  }

  /// Starts executing tasks in the queue.
  void start() {
    if (status != SecretaryStatus.idle) return;
    _setStatus(SecretaryStatus.active);
    _loop();
  }

  /// Stops execution. Can be started again as long as it wasn't disposed.
  /// Depends on the `StopPolicy`.
  Future<void> stop() async {
    _setStatus(SecretaryStatus.stopping);
    if (stopPolicy < StopPolicy.finishRecurring) {
      stopAllRecurring();
    }
    if (stopPolicy == StopPolicy.stopImmediately) {
      _setStatus(SecretaryStatus.idle);
      return;
    }

    await for (final newState in statusStream) {
      if ([SecretaryStatus.idle, SecretaryStatus.disposed].contains(newState)) {
        break;
      }
    }
  }

  /// Waits for a result for a task with [key].
  /// If the task is not found, a `TaskNotFoundError` will be returned.
  /// If [waitForFinal] is true, this function will wait for the task to be
  /// totally completed, i.e. it won't return after an error if the task can
  /// be retried. If false, this function will return after the next attempt.
  Future<Result<T, Object>> waitForResult(K key,
      {bool waitForFinal = true}) async {
    if (tasks.containsKey(key)) {
      return waitForFinal
          ? tasks[key]!.finalCompleter.future
          : tasks[key]!.completer.future;
    }
    return Result.error(TaskNotFoundError(key));
  }

  /// Dispose the Secretary and all resources associated with it.
  /// Will have to wait for for execution to stop, depending on the `StopPolicy`.
  Future<void> dispose() async {
    await stop();
    _setStatus(SecretaryStatus.disposed);
    _streamController.close();
    _statusStreamController.close();
  }

  void _addEvent(SecretaryEvent<K, T> event) {
    if (status == SecretaryStatus.disposed) return;
    _streamController.add(event);
    lastEvent = event;
  }

  void _setStatus(SecretaryStatus newStatus) {
    status = newStatus;
    _statusStreamController.add(newStatus);
    _emitState();
  }

  /// Stops a single recurring task with [key].
  /// This won't remove runs that have already been started from the queue.
  bool stopRecurringTask(K key) {
    if (!recurringTasks.containsKey(key)) return false;
    _timers[key]?.cancel();
    recurringTasks.remove(key);
    _emitState();
    return true;
  }

  /// Stops all recurring tasks.
  /// This won't remove runs that have already been started from the queue.
  List<RecurringTask<K, T>> stopAllRecurring() {
    _clearTimers();
    final tasks = [...recurringTasks.values];
    recurringTasks.clear();
    _emitState();
    return tasks;
  }

  void _clearTimers() {
    for (Timer t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
  }

  bool get canStop {
    if (stopPolicy >= StopPolicy.finishActive && active.isNotEmpty) {
      return false;
    }
    if (stopPolicy >= StopPolicy.finishQueue && queue.isNotEmpty) {
      return false;
    }
    if (stopPolicy >= StopPolicy.finishRecurring && recurringTasks.isNotEmpty) {
      return false;
    }
    return true;
  }

  void _loop() async {
    while (
        [SecretaryStatus.active, SecretaryStatus.stopping].contains(status)) {
      if (status == SecretaryStatus.stopping && canStop) {
        _setStatus(SecretaryStatus.idle);
        stopAllRecurring();
        break;
      }

      if (queue.isNotEmpty) {
        Future<SecretaryTask<K, T>?> future = _doNextTask()
          ..then(_handleRecurring);
        if (!hasTaskCapacity) {
          await future;
        }
      } else {
        await Future.delayed(checkInterval);
      }
    }
  }

  void _handleRecurring(SecretaryTask<K, T>? task) {
    if (task == null || !recurringTasks.containsKey(task.key)) return;

    RecurringTask<K, T> recurringTask = recurringTasks[task.key]!;
    recurringTask = recurringTask.withRun(task);
    recurringTasks[recurringTask.key] = recurringTask;
    _timers[recurringTask.key]?.cancel(); // shouldn't be necessary but ok
    _timers.remove(recurringTask.key);
    if (recurringTask.interval != Duration.zero) {
      _emitState();
    }
    if (recurringTask.canRun) {
      Timer timer = Timer(
        recurringTask.interval,
        _buildTimerCallback(recurringTask),
      );
      _timers[recurringTask.key] = timer;
    } else {
      recurringTasks.remove(recurringTask.key);
      // TODO: emit some sort of event?
      _emitState();
    }
  }

  VoidCallback _buildTimerCallback(RecurringTask<K, T> task) => () => add(
        task.key,
        task.buildTask(),
        overrides: task.overrides,
        onComplete: task.onComplete,
        onError: task.onError,
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

    if (task.retryDelay != Duration.zero) {
      _emitState();
    }

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
      task.completer.complete(Result.ok(result));
      task.finalCompleter.complete(Result.ok(result));
      _emitState();
    } else {
      return _handleError(task, error);
    }
    return task;
  }

  SecretaryTask<K, T> _handleError(SecretaryTask<K, T> task, Object error) {
    task = task.withError(error);
    task.completer.complete(Result.error(error));
    task = task.copyWith(completer: Completer());
    tasks[task.key] = task;
    if (task.canRetry && task.retryIf(error)) {
      switch (task.retryPolicy) {
        case QueuePolicy.backOfQueue:
          queue.add(task.key);
          break;
        case QueuePolicy.frontOfQueue:
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
      task.finalCompleter.complete(Result.error(error));
    }
    _emitState();
    return task;
  }

  void _emitState() => _stateStreamController.add(state);
}
