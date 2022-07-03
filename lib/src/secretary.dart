import 'dart:async';

import 'package:secretary/secretary.dart';

class Secretary<K, T> {
  final Duration checkInterval;
  final Duration retryDelay;
  final Validator<T>? validator;
  final bool Function(Object?) retryIf;
  final RetryPolicy retryPolicy;
  final StopPolicy stopPolicy;
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
  Stream<T> get resultStream => stream
      .where((e) => e.isSuccess)
      .map((e) => (e as SuccessEvent<K, T>).result);
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

  void add(
    K key,
    Task<T> task, {
    Validator<T>? validator,
    Callback<T>? onComplete,
    RetryTest? retryIf,
    RetryPolicy? retryPolicy,
    Duration? retryDelay,
    int? maxAttempts,
  }) async {
    final item = SecretaryTask<K, T>(
      key: key,
      task: task,
      validator: validator ?? this.validator,
      onComplete: onComplete,
      retryIf: retryIf ?? this.retryIf,
      retryPolicy: retryPolicy ?? this.retryPolicy,
      retryDelay: retryDelay ?? this.retryDelay,
      maxAttempts: maxAttempts ?? this.maxAttempts,
    );
    tasks[key] = item;
    queue.add(key);
  }

  void start() {
    if (state != SecretaryState.idle) return;
    _setState(SecretaryState.active);
    _loop();
  }

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
      _handleError(key, error);
    }
  }

  void _handleError(K key, Object error) {
    SecretaryTask<K, T> task = tasks[key]!.withError(error);
    tasks[key] = task;
    if (task.canRetry && task.retryIf(error)) {
      switch (task.retryPolicy) {
        case RetryPolicy.backOfQueue:
          queue.add(key);
          break;
        case RetryPolicy.frontOfQueue:
          queue.insert(0, key);
          break;
      }
      _addEvent(RetryEvent.fromTask(task));
    } else {
      _addEvent(FailureEvent.fromTask(task));
    }
  }
}
