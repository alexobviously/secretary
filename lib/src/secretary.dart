import 'dart:async';

import 'package:secretary/secretary.dart';

class Secretary<K, T> {
  final Duration checkInterval;
  final Validator<T>? validator;
  final RetryPolicy retryPolicy;
  final StopPolicy stopPolicy;
  final int maxAttempts;

  Secretary({
    this.checkInterval = const Duration(milliseconds: 50),
    this.validator,
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
  SecretaryState state = SecretaryState.idle;

  void start() {
    state = SecretaryState.active;
    _loop();
  }

  void stop() {
    state = SecretaryState.stopping;
  }

  Future<void> dispose() async {
    _streamController.close();
  }

  void _loop() async {
    while ([SecretaryState.active, SecretaryState.stopping].contains(state)) {
      if (state == SecretaryState.stopping &&
          stopPolicy != StopPolicy.finishQueue) {
        break;
      }

      if (queue.isNotEmpty) {
        await _doNextTask();
      } else {
        await Future.delayed(checkInterval);
      }
    }
  }

  void add(
    K key,
    FutureFunction<T> task, {
    Validator<T>? validator,
    Callback<T>? onComplete,
    RetryPolicy? retryPolicy,
    int? maxAttempts,
  }) async {
    final item = SecretaryTask<K, T>(
      key: key,
      task: task,
      validator: validator ?? this.validator,
      onComplete: onComplete,
      retryPolicy: retryPolicy ?? this.retryPolicy,
      maxAttempts: maxAttempts ?? this.maxAttempts,
    );
    tasks[key] = item;
    queue.add(key);
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

    T result = await task.task();
    Object? error;

    if (task.validator != null) {
      error = task.validator!(result);
    }

    active.remove(key);
    if (error == null) {
      tasks.remove(key);
      task.onComplete?.call(result);
      _streamController.add(SuccessEvent(key: key, result: result));
    } else {
      _handleError(key, error);
    }
  }

  void _handleError(K key, Object error) {
    SecretaryTask<K, T> task = tasks[key]!.withError(error);
    if (task.canRetry) {
      switch (task.retryPolicy) {
        case RetryPolicy.backOfQueue:
          queue.add(key);
          break;
        case RetryPolicy.frontOfQueue:
          queue.insert(0, key);
          break;
      }
      _streamController.add(RetryEvent.fromTask(task));
    } else {
      _streamController.add(FailureEvent.fromTask(task));
    }
  }
}
