typedef Task<T> = Future<T> Function();
typedef Validator<T> = Object? Function(T);
typedef Callback<T> = void Function(T);
typedef RetryTest = bool Function(Object?);

enum SecretaryState {
  idle,
  active,
  stopping,
  disposed,
}

/// Dictates what to do with a task that needs to be retried, i.e. should it
/// return to the back of the queue or be retried immediately?
enum RetryPolicy {
  /// Error'd tasks will be placed at the back of the queue.
  backOfQueue,

  /// Error'd tasks will be retried immediately.
  frontOfQueue,
}

/// Dictates what the Secretary will wait for when `stop()` or `dispose()`
/// are called.
enum StopPolicy {
  /// Immediately stops work, regardless of tasks in progress.
  stopImmediately,

  /// Stops work after all currently active tasks are completed.
  finishActive,

  /// Stops work after all tasks in the queue are completed.
  /// Note that tasks can still be added while the Secretary is in the `stopping`
  /// state, and thus this could go on indefinitely.
  finishQueue,
}

class RetryIf {
  static bool alwaysRetry(Object? error) => true;
  static bool neverRetry(Object? error) => false;
}

class Validators {
  static Validator<T> matchSingle<T>(T target) =>
      (T val) => val == target ? null : val;

  static Validator<T> matchMulti<T>(List<T> targets) =>
      (T val) => targets.contains(val) ? null : val;
}
