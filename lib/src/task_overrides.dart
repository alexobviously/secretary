import 'package:secretary/secretary.dart';

/// A collection of optional parameters that can be used to override the base
/// values in the parent Secretary when creating tasks.
class TaskOverrides<T> {
  /// A validator function that will be called on results to determine if the
  /// task succeeded.
  /// It should return null if the task was considered a success, and the error otherwise.
  final Validator<T>? validator;

  /// A test to determine if a task should be retried or not.
  /// Takes an error as an input (the result of [validator]), and returns a bool.
  final RetryTest? retryIf;

  /// Dictates what to do with a task that needs to be retried, i.e. should it
  /// return to the back of the queue or be retried immediately?
  final QueuePolicy? retryPolicy;

  /// The amount of time to wait before retrying a task, if it was the last task attempted.
  final Duration? retryDelay;

  /// The maximum number of times to attempt a task before marking it as failed.
  final int? maxAttempts;

  const TaskOverrides({
    this.validator,
    this.retryIf,
    this.retryPolicy,
    this.retryDelay,
    this.maxAttempts,
  });

  /// No overrides.
  const factory TaskOverrides.none() = TaskOverrides;
}
