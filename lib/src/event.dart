import 'package:secretary/secretary.dart';

class SecretaryEvent<K, T> {
  final K key;
  const SecretaryEvent({required this.key});

  bool get isSuccess => this is SuccessEvent;
  bool get isRetry => this is RetryEvent;
  bool get isFailure => this is FailureEvent;
}

class SuccessEvent<K, T> extends SecretaryEvent<K, T> {
  final T result;
  const SuccessEvent({required super.key, required this.result});
}

class RetryEvent<K, T> extends SecretaryEvent<K, T> {
  final List<Object> errors;
  final int maxAttempts;

  Object get error => errors.last;
  int get attempts => errors.length;
  int get attemptsLeft => maxAttempts - attempts;

  const RetryEvent({
    required super.key,
    required this.errors,
    required this.maxAttempts,
  });

  factory RetryEvent.fromTask(SecretaryTask<K, T> task) => RetryEvent(
        key: task.key,
        errors: [...task.errors],
        maxAttempts: task.maxAttempts,
      );
}

class FailureEvent<K, T> extends SecretaryEvent<K, T> {
  final List<Object> errors;

  Object get error => errors.last;
  int get attempts => errors.length;

  const FailureEvent({
    required super.key,
    required this.errors,
  });

  factory FailureEvent.fromTask(SecretaryTask<K, T> task) => FailureEvent(
        key: task.key,
        errors: task.errors,
      );
}
