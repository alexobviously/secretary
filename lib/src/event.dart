import 'package:secretary/secretary.dart';

class SecretaryEvent<K, T> {
  final K key;
  const SecretaryEvent({required this.key});

  bool get isSuccess => this is SuccessEvent;
  bool get isError => this is ErrorEvent;
  bool get isRetry => this is RetryEvent;
  bool get isFailure => this is FailureEvent;
}

class SuccessEvent<K, T> extends SecretaryEvent<K, T> {
  final T result;
  const SuccessEvent({required super.key, required this.result});
}

class ErrorEvent<K, T> extends SecretaryEvent<K, T> {
  final List<Object> errors;

  const ErrorEvent({required super.key, required this.errors});

  Object get error => errors.last;
  int get attempts => errors.length;
}

class RetryEvent<K, T> extends ErrorEvent<K, T> {
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
}
