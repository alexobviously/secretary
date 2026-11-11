import 'package:secretary/secretary.dart';

sealed class const SecretaryEvent<K, T>({
  required final K key,
  required final List<Object> errors,
}) {
  Object get error => errors.last;
  int get attempts => errors.length;

  bool get isSuccess => this is SuccessEvent;
  bool get isError => this is ErrorEvent;
  bool get isRetry => this is RetryEvent;
  bool get isFailure => this is FailureEvent;
  bool get isFinal => isSuccess || isFailure;

  @override
  String toString() => 'SecretaryEvent($key)';
}

class const SuccessEvent<K, T>({
  required super.key,
  super.errors = const [],
  required final T result,
}) extends SecretaryEvent<K, T> {
  @override
  int get attempts => super.attempts + 1;

  @override
  String toString() => 'SuccessEvent($key, $result, attempts: $attempts)';
}

class const ErrorEvent<K, T>({
  required super.key,
  required super.errors,
}) extends SecretaryEvent<K, T> {
  int get maxAttempts => errors.length;

  @override
  String toString() => 'ErrorEvent($key, $attempts, $error)';
}

class const RetryEvent<K, T>({
  required super.key,
  required super.errors,
  @override required final int maxAttempts,
}) extends ErrorEvent<K, T> {
  int get attemptsLeft => maxAttempts - attempts;

  factory fromTask(SecretaryTask<K, T> task) => RetryEvent(
    key: task.key,
    errors: [...task.errors],
    maxAttempts: task.maxAttempts,
  );

  @override
  String toString() => 'RetryEvent($key, $attempts/$maxAttempts, $error)';
}

class const FailureEvent<K, T>({
  required super.key,
  required super.errors,
}) extends ErrorEvent<K, T> {
  factory fromTask(SecretaryTask<K, T> task) => FailureEvent(
    key: task.key,
    errors: task.errors,
  );

  @override
  String toString() => 'FailureEvent($key, $attempts/$attempts, $error)';
}

class const RecurringTaskFinishedEvent<K, T>({
  required super.key,
  required super.errors,
  final bool invalidated = false,
}) extends SecretaryEvent<K, T> {
  @override
  String toString() => 'RecurringTaskFinishedEvent($key, $invalidated)';
}
