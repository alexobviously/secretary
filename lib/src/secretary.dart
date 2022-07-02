import 'package:secretary/secretary.dart';

class Secretary<K, T> {
  final Duration checkInterval;
  final ValidatorFunction<T>? validator;
  final RetryPolicy retryPolicy;
  final StopPolicy stopPolicy;
  final int maxRetries = 0;

  Secretary({
    this.checkInterval = const Duration(milliseconds: 50),
    this.validator,
    this.retryPolicy = RetryPolicy.backOfQueue,
    this.stopPolicy = StopPolicy.finishActive,
    bool autostart = true,
  }) {
    if (autostart) start();
  }

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

  Future<void> dispose() async {}

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
    ValidatorFunction<T>? validator,
    Callback<T>? onComplete,
    RetryPolicy? retryPolicy,
    int? maxRetries,
  }) async {
    final item = SecretaryTask<K, T>(
      key: key,
      task: task,
      validator: validator ?? this.validator,
      onComplete: onComplete,
      retryPolicy: retryPolicy ?? this.retryPolicy,
      maxRetries: maxRetries ?? this.maxRetries,
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
    bool valid = true;

    if (task.validator != null) {
      valid = task.validator!(result);
    }

    active.remove(key);
    if (valid) {
      tasks.remove(key);
      task.onComplete?.call(result);
    } else {
      switch (task.retryPolicy) {
        case RetryPolicy.backOfQueue:
          queue.add(key);
          break;
        case RetryPolicy.frontOfQueue:
          queue.insert(0, key);
          break;
      }
    }
  }
}
