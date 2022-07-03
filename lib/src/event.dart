import 'package:secretary/secretary.dart';

class SecretaryEvent<K, T> {
  final K key;
  final List<Object> errors;

  Object get error => errors.last;
  int get attempts => errors.length;

  const SecretaryEvent({required this.key, required this.errors});

  bool get isSuccess => this is SuccessEvent;
  bool get isError => this is ErrorEvent;
  bool get isRetry => this is RetryEvent;
  bool get isFailure => this is FailureEvent;

  @override
  String toString() => 'SecretaryEvent($key)';
}

class SuccessEvent<K, T> extends SecretaryEvent<K, T> {
  final T result;

  @override
  int get attempts => super.attempts + 1;

  const SuccessEvent({
    required super.key,
    super.errors = const [],
    required this.result,
  });

  @override
  String toString() => 'SuccessEvent($key, $result, attempts: $attempts)';
}

class ErrorEvent<K, T> extends SecretaryEvent<K, T> {
  const ErrorEvent({required super.key, required super.errors});

  int get maxAttempts => errors.length;

  @override
  String toString() => 'ErrorEvent($key, $attempts, $error)';
}

class RetryEvent<K, T> extends ErrorEvent<K, T> {
  @override
  final int maxAttempts;

  int get attemptsLeft => maxAttempts - attempts;

  const RetryEvent({
    required super.key,
    required super.errors,
    required this.maxAttempts,
  });

  factory RetryEvent.fromTask(SecretaryTask<K, T> task) => RetryEvent(
        key: task.key,
        errors: [...task.errors],
        maxAttempts: task.maxAttempts,
      );

  @override
  String toString() => 'RetryEvent($key, $attempts/$maxAttempts, $error)';
}

class FailureEvent<K, T> extends ErrorEvent<K, T> {
  const FailureEvent({
    required super.key,
    required super.errors,
  });

  factory FailureEvent.fromTask(SecretaryTask<K, T> task) => FailureEvent(
        key: task.key,
        errors: task.errors,
      );

  @override
  String toString() => 'FailureEvent($key, $attempts/$attempts, $error)';
}
