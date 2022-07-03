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
  final Validator<T>? validator;

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
    this.validator,
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
  Stream<SecretaryEvent<K, T>> get stream => _streamController.stream;
  Stream<SuccessEvent<K, T>> get successStream =>
      stream.where((e) => e.isSuccess).map((e) => e as SuccessEvent<K, T>);
  Stream<T> get resultStream => successStream.map((e) => e.result);
  Stream<ErrorEvent<K, T>> get errorStream =>
      stream.where((e) => e.isError).map((e) => e as ErrorEvent<K, T>);

  Map<K, SecretaryTask<K, T>> tasks = {};
  List<K> queue = [];
  List<K> active = [];
  SecretaryEvent<K, T>? lastEvent;

  late final _stateStreamController =
      StreamController<SecretaryState>.broadcast();
  Stream<SecretaryState> get stateStream => _stateStreamController.stream;
  SecretaryState state = SecretaryState.idle;

  bool get hasTasks => tasks.isNotEmpty;

  /// Adds an item to the queue.
  /// [task] should be a function that returns a Future<T>, where T is the T
  /// type constraint of the Secretary.
  /// If [index] is specified, then the item will be inserted at that point in
  /// the queue, otherwise it will be added to the end. A negative index can
  /// also be used, e.g. -1 will add the task as the second last element.
  ///
  bool add(
    K key,
    Task<T> task, {
    int? index,
    Callback<T>? onComplete,
    Callback<ErrorEvent<K, T>>? onError,
    Validator<T>? validator,
    RetryTest? retryIf,
    RetryPolicy? retryPolicy,
    Duration? retryDelay,
    int? maxAttempts,
  }) {
    if (queue.contains(key) || active.contains(key)) return false;
    final item = SecretaryTask<K, T>(
      key: key,
      task: task,
      validator: validator ?? this.validator,
      onComplete: onComplete,
      onError: onError,
      retryIf: retryIf ?? this.retryIf,
      retryPolicy: retryPolicy ?? this.retryPolicy,
      retryDelay: retryDelay ?? this.retryDelay,
      maxAttempts: maxAttempts ?? this.maxAttempts,
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
        await _doNextTask();
      } else {
        await Future.delayed(checkInterval);
      }
    }
  }

  Future<void> _doNextTask() async {
    if (queue.isEmpty) return;
    final key = queue.first;
    await _doTask(key);
  }

  Future<void> _doTask(K key) async {
    if (!queue.contains(key)) return;

    queue.remove(key);
    active.add(key);
    final task = tasks[key]!;

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
      task.onComplete?.call(result);
      _addEvent(SuccessEvent(
        key: key,
        result: result,
        errors: task.errors,
      ));
    } else {
      _handleError(task, error);
    }
  }

  void _handleError(SecretaryTask<K, T> task, Object error) {
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
      final event = FailureEvent.fromTask(task);
      task.onError?.call(event);
      _addEvent(event);
    }
  }
}
