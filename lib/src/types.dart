import 'package:secretary/secretary.dart';

typedef VoidCallback = void Function();
typedef Task<T> = Future<T> Function();
typedef TaskBuilder<K, T> = Task<T> Function(ExecutionParams<K, T>);
typedef Validator<T> = Object? Function(T);
typedef Callback<T> = void Function(T);
typedef RetryTest = bool Function(Object?);
typedef RecurringValidator<K, T> = bool Function(ExecutionParams<K, T>);

enum SecretaryState {
  idle,
  active,
  stopping,
  disposed,
}

/// Dictates what to do with a task that needs to be queued, such as a retried
/// task, i.e. should it return to the back of the queue or be retried immediately?
enum QueuePolicy {
  /// Tasks will be placed at the back of the queue.
  backOfQueue,

  /// Tasks will be retried immediately.
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

/// A collection of common `RetryTest` generators.
class RetryIf {
  /// Always retries, regardless of error.
  static bool alwaysRetry(Object? error) => true;

  /// Never retries, regardlessof error.
  static bool neverRetry(Object? error) => false;

  /// Validates only of the error was equal to [target].
  static RetryTest matchSingle(Object? target) =>
      (Object? error) => error == target;

  /// Validates only if the error matches one of [targets].
  static RetryTest matchMulti(List<Object?> targets) =>
      (Object? error) => targets.contains(error);

  /// Validates if the error was not equal to [target].
  static RetryTest notSingle(Object? target) =>
      (Object? error) => error != target;

  /// Validates if the error doesn't match any of [targets].
  static RetryTest notIn(List<Object?> targets) =>
      (Object? error) => !targets.contains(error);
}

/// A collection of coommon `Validator` generators.
class Validators {
  /// Always valid.
  static Object? pass(dynamic val) => null;

  /// Valid if the result was equal to [target].
  static Validator<T> matchSingle<T>(T target) =>
      (T val) => val == target ? null : val;

  /// Valid if the result was one of [targets].
  static Validator<T> matchMulti<T>(List<T> targets) =>
      (T val) => targets.contains(val) ? null : val;

  /// Valid if the result (a `Result` object) is ok.
  static Object? resultOk<T, E>(Result<T, E> result) =>
      result.ok ? null : result.error!;
}

/// A collection of common `RecurringValidator` generators.
class RecurringValidators {
  /// Always valid
  static bool pass(ExecutionParams params) => true;

  /// Valid if the previous run was successful.
  static bool lastRunSucceeded(ExecutionParams params) =>
      params.runs.isEmpty || params.runs.last.succeeded;

  /// Valid if less than[n] runs have failed over the lifetime of the task.
  static RecurringValidator maxFailures(int n) =>
      (ExecutionParams params) => params.runs.where((e) => e.failed).length < n;

  /// Valid unless the last [n] runs have all failed.
  static RecurringValidator maxFailuresInRow(int n) =>
      (ExecutionParams params) =>
          params.runs.length < n ||
          params.runs.reversed.take(n).where((e) => !e.failed).length < n;
}
